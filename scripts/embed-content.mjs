#!/usr/bin/env node
/**
 * Layer 3 (JIT Retrieval) POC Phase 1 — 임베딩 인덱서
 *
 * docs/**\/*.md + root-level .md → 섹션(H2) 단위 청킹 → 로컬 임베딩 → JSON 인덱스
 *
 * 사용:
 *   node scripts/embed-content.mjs
 *
 * 산출물:
 *   data/embeddings.json (gitignore)
 *
 * 설계 결정:
 *  - 모델: @xenova/transformers + Xenova/multilingual-e5-small
 *    · 100% 로컬, 외부 API 0, 94 언어 지원, 384차원
 *    · Phase 2b 벤치마크(benchmark-models.mjs)에서 3모델 비교 → 한국어 Top-1 3/5 승리
 *    · 첫 실행 시 ~120MB 모델 다운로드 후 ./node_modules/.cache 에 캐시
 *  - 청킹: H2 (`## `) 단위. 한 .md → N 청크
 *    · POC 엔트리 §10 안티패턴 "단일 전체 .md 임베딩" 회피
 *    · 청크가 너무 작으면 (< 200자) 다음 H2 와 합침
 *  - 메타: slug · title · category · tags · date · confidence · h2_title · chunk_text
 *  - 벡터 저장: 단순 JSON. ~100 문서 × ~5 청크/문서 ≈ 500 벡터 × 384 float = ~750KB
 *  - 거리 함수: 코사인 유사도 (모델 출력이 이미 정규화됐지만 검색 시 명시적 계산)
 *
 * 향후 확장 (Phase 2+):
 *  - 인덱싱 자동화 (pre-commit hook 또는 CI)
 *  - 쿼리 라우터 + 섀도우 모드
 *  - 임베딩 모델 비교 (Voyage · OpenAI text-embedding-3-small)
 */

import fs from "fs";
import path from "path";
import matter from "gray-matter";

const OUTPUT_FILE = path.join(process.cwd(), "data", "embeddings.json");

// aidy-architect 구조: docs/ + root-level .md
const SOURCES = [
  { dir: "docs", source_type: "doc", slug_prefix: "docs", ext: ".md" },
  { dir: ".", source_type: "root-doc", slug_prefix: "", ext: ".md", maxDepth: 0 },
];

// 청크 최소 크기 (이보다 작으면 다음 H2 와 합침)
const MIN_CHUNK_LEN = 200;
// 청크 최대 크기 (너무 길면 모델 윈도우 초과 + 신호 희석)
const MAX_CHUNK_LEN = 2000;

function findFiles(dir, ext, maxDepth = Infinity) {
  const results = [];
  if (!fs.existsSync(dir)) return results;

  function traverse(currentDir, depth) {
    if (depth > maxDepth) return;
    const items = fs.readdirSync(currentDir, { withFileTypes: true });
    for (const item of items) {
      const fullPath = path.join(currentDir, item.name);
      if (item.isDirectory()) {
        traverse(fullPath, depth + 1);
      } else if (item.name.endsWith(ext)) {
        results.push(fullPath);
      }
    }
  }

  traverse(dir, 0);
  return results;
}

/**
 * MDX/MD 본문을 H2 단위로 청킹.
 * - 첫 H2 이전 텍스트(서두) 는 별도 청크
 * - 짧은 청크는 다음 청크와 합침
 * - 너무 긴 청크는 자른 후 잔여를 새 청크로
 */
function chunkByH2(content) {
  const lines = content.split("\n");
  const chunks = [];
  let current = { h2: null, body: [] };

  for (const line of lines) {
    if (/^## /.test(line)) {
      // 이전 청크 확정
      if (current.body.length > 0 || current.h2) {
        chunks.push({
          h2: current.h2,
          text: current.body.join("\n").trim(),
        });
      }
      current = { h2: line.replace(/^##\s+/, "").trim(), body: [] };
    } else {
      current.body.push(line);
    }
  }
  if (current.body.length > 0 || current.h2) {
    chunks.push({
      h2: current.h2,
      text: current.body.join("\n").trim(),
    });
  }

  // 짧은 청크는 다음 청크와 합치기
  const merged = [];
  let buffer = null;
  for (const chunk of chunks) {
    if (!buffer) {
      buffer = chunk;
      continue;
    }
    if (buffer.text.length < MIN_CHUNK_LEN) {
      buffer = {
        h2: buffer.h2 || chunk.h2,
        text: buffer.text + "\n\n" + (chunk.h2 ? `## ${chunk.h2}\n` : "") + chunk.text,
      };
    } else {
      merged.push(buffer);
      buffer = chunk;
    }
  }
  if (buffer) merged.push(buffer);

  // 너무 긴 청크는 잘라내기 (단순 cut, 향후 재청킹 검토)
  const final = [];
  for (const chunk of merged) {
    if (chunk.text.length <= MAX_CHUNK_LEN) {
      final.push(chunk);
    } else {
      // 단순 분할 — 향후 토큰 기반으로 개선
      let remaining = chunk.text;
      let part = 0;
      while (remaining.length > 0) {
        final.push({
          h2: chunk.h2 + (part > 0 ? ` (cont. ${part})` : ""),
          text: remaining.slice(0, MAX_CHUNK_LEN),
        });
        remaining = remaining.slice(MAX_CHUNK_LEN);
        part++;
      }
    }
  }

  return final.filter((c) => c.text.length >= 50); // 너무 짧은 잔여물 제거
}

/**
 * 임베딩 텍스트 구성:
 *  - h2 제목 + 본문 (제목이 핵심 시그널이라 포함)
 *  - frontmatter title 도 포함 (엔트리 주제 컨텍스트)
 */
function buildEmbeddingText(entryTitle, h2, text) {
  const parts = [];
  if (entryTitle) parts.push(`# ${entryTitle}`);
  if (h2) parts.push(`## ${h2}`);
  parts.push(text);
  return parts.join("\n\n");
}

async function main() {
  console.log("📦 Loading embedding model (Xenova/multilingual-e5-small)...");
  console.log("   첫 실행 시 ~120MB 다운로드 (이후 캐시)");

  // dynamic import — top-level await 회피
  const { pipeline } = await import("@xenova/transformers");
  const extractor = await pipeline(
    "feature-extraction",
    "Xenova/multilingual-e5-small",
  );

  // Multi-source: docs/ + root-level .md
  const allChunks = [];
  let totalChunks = 0;
  const sourceCounts = {};

  for (const source of SOURCES) {
    const sourceDir = path.join(process.cwd(), source.dir);
    const files = findFiles(sourceDir, source.ext, source.maxDepth);
    sourceCounts[source.source_type] = files.length;
    console.log(`\n🔍 [${source.source_type}] ${files.length} ${source.ext} files in ${source.dir}${source.maxDepth === 0 ? " (root only)" : ""}`);

    for (const file of files) {
      const rel = path.relative(process.cwd(), file);
      const raw = fs.readFileSync(file, "utf-8");
      const { data, content } = matter(raw);

      // slug 도출
      // doc: docs/<relative-path-without-ext> → "docs/<relative-path>"
      // root-doc: <filename-without-ext> → "<filename>"
      let slug;
      if (source.source_type === "doc") {
        const relPath = path.relative(path.join(process.cwd(), source.dir), file);
        slug = `${source.slug_prefix}/${relPath.replace(/\.md$/, "")}`;
      } else {
        // root-doc
        const filename = path.basename(file).replace(/\.md$/, "");
        slug = filename;
      }

      const chunks = chunkByH2(content);
      totalChunks += chunks.length;

      for (let i = 0; i < chunks.length; i++) {
        const chunk = chunks[i];
        allChunks.push({
          source: source.source_type,  // "doc" | "root-doc"
          slug,
          title: data.title || path.basename(file, ".md"),
          tags: data.tags || [],
          date: data.date || null,
          h2_title: chunk.h2 || "(intro)",
          chunk_index: i,
          chunk_text: chunk.text,
        });
      }
    }
  }

  const totalFiles = Object.values(sourceCounts).reduce((a, b) => a + b, 0);
  console.log(`\n🧮 ${totalChunks} chunks total from ${totalFiles} files. Embedding...`);

  const start = Date.now();
  const vectors = [];
  for (let i = 0; i < allChunks.length; i++) {
    const meta = allChunks[i];
    const text = buildEmbeddingText(meta.title, meta.h2_title, meta.chunk_text);
    const output = await extractor(text, { pooling: "mean", normalize: true });
    // tensor → 일반 배열 (정규화된 384 float)
    vectors.push(Array.from(output.data));

    if ((i + 1) % 50 === 0 || i === allChunks.length - 1) {
      const pct = (((i + 1) / allChunks.length) * 100).toFixed(0);
      process.stdout.write(`\r   [${pct}%] ${i + 1}/${allChunks.length}`);
    }
  }
  const elapsed = ((Date.now() - start) / 1000).toFixed(1);
  console.log(`\n   완료 (${elapsed}s)`);

  // 인덱스 저장
  const index = {
    model: "Xenova/multilingual-e5-small",
    dim: vectors[0]?.length || 0,
    created_at: new Date().toISOString(),
    chunks: allChunks.map((meta, i) => ({ ...meta, vector: vectors[i] })),
  };

  fs.mkdirSync(path.dirname(OUTPUT_FILE), { recursive: true });
  fs.writeFileSync(OUTPUT_FILE, JSON.stringify(index));

  const sizeKB = (fs.statSync(OUTPUT_FILE).size / 1024).toFixed(0);
  console.log(`\n✅ Index saved: data/embeddings.json (${sizeKB} KB, ${totalChunks} chunks, ${index.dim}d)`);
}

main().catch((err) => {
  console.error("❌ Embedding failed:", err);
  process.exit(1);
});
