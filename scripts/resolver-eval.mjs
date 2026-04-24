#!/usr/bin/env node
// Skillify Step 7 — Resolver routing eval (structural, no LLM)
// ──────────────────────────────────────────────────────────────────────
// 역할: 주어진 intent 문장이 CLAUDE.md "## Skill routing" 테이블에서
//      어떤 skill로 라우팅되는지 시뮬레이션하고 golden set 대비 pass/fail 계산.
//
// 이 스크립트는 **LLM 호출 없음**. 결정론적 키워드 중첩 점수로 라우팅을
// 추정한다. 이유: Step 8(check-skills-reachable)이 "매핑이 존재하는가"를
// 검증한 뒤, Step 7은 "매핑 설명이 intent에 얼마나 잘 붙는가"를 검증.
// LLM 라우팅의 모든 nuance는 놓치지만, *가장 흔한 drift*("트리거 설명이
// 너무 모호해서 어떤 intent에도 매치됨" / "중복 skill이 같은 intent에
// 둘 다 매치")를 결정론적으로 잡는다.
//
// 고급 버전(실제 Claude 호출)은 future work — 이 스크립트로 드러난
// 구조적 갭을 먼저 고치고, 그 다음 LLM eval을 돌리는 게 올바른 순서.
//
// CLI:
//   node scripts/resolver-eval.mjs                     # 현 프로젝트, 기본 cases
//   node scripts/resolver-eval.mjs --project <path>
//   node scripts/resolver-eval.mjs --cases <path.json>
//   node scripts/resolver-eval.mjs --json

import { readFileSync, existsSync } from "node:fs";
import { join } from "node:path";

const args = process.argv.slice(2);
const flags = {
  project: process.cwd(),
  cases: null,
  json: false,
};
for (let i = 0; i < args.length; i++) {
  if (args[i] === "--project") flags.project = args[++i];
  else if (args[i] === "--cases") flags.cases = args[++i];
  else if (args[i] === "--json") flags.json = true;
  else if (args[i] === "--help" || args[i] === "-h") {
    console.log(`
Skillify Step 7 — resolver routing eval (structural)

사용법: resolver-eval [--project <path>] [--cases <path.json>] [--json]

기본 cases: <project>/data/resolver-eval-cases.json
exit: 0=모두 pass / 1=하나라도 fail / 2=설정 오류
`);
    process.exit(0);
  }
}

// ── Skill routing 섹션 파싱 ───────────────────────────────────────────
const claudeMdPath = join(flags.project, "CLAUDE.md");
if (!existsSync(claudeMdPath)) {
  console.error(`CLAUDE.md 없음: ${claudeMdPath}`);
  process.exit(2);
}
const claudeMd = readFileSync(claudeMdPath, "utf8");
const lines = claudeMd.split("\n");
let sectionStart = -1;
let sectionEnd = lines.length;
for (let i = 0; i < lines.length; i++) {
  if (/^##\s+Skill\s+routing\b/i.test(lines[i])) {
    sectionStart = i;
    break;
  }
}
if (sectionStart < 0) {
  console.error("CLAUDE.md에 '## Skill routing' 섹션 없음");
  process.exit(2);
}
for (let j = sectionStart + 1; j < lines.length; j++) {
  if (/^##\s+/.test(lines[j])) {
    sectionEnd = j;
    break;
  }
}
const sectionText = lines.slice(sectionStart, sectionEnd).join("\n");

// 각 라우팅 규칙: `- <trigger desc> → invoke <skill>` 형식
const ruleRegex = /^-\s+(.+?)\s*(?:→|->)\s*invoke\s+([a-z][a-z0-9-]*)\s*$/gim;
const rules = [];
let m;
while ((m = ruleRegex.exec(sectionText)) !== null) {
  rules.push({ description: m[1].trim(), skill: m[2] });
}
if (rules.length === 0) {
  console.error("라우팅 규칙 파싱 실패 — '- desc → invoke skill' 형식 확인");
  process.exit(2);
}

// ── cases 로드 ────────────────────────────────────────────────────────
const casesPath = flags.cases || join(flags.project, "data", "resolver-eval-cases.json");
if (!existsSync(casesPath)) {
  console.error(`cases JSON 없음: ${casesPath}`);
  process.exit(2);
}
const casesData = JSON.parse(readFileSync(casesPath, "utf8"));
const cases = casesData.cases || [];

// ── 토큰화 + 점수 ─────────────────────────────────────────────────────
// 한국어 조사·어미를 제거해 어휘 매칭률을 올린다. 완전 형태소 분석은 과잉.
// slash 목록("법률/보안/마케팅")도 쪼개서 각 토큰 매칭되도록.
const KOREAN_SUFFIX = /(?:으로|로|은|는|이|가|을|를|의|에게|한테|에서|부터|까지|에|와|과|야|다|자|해줘|해주|해|하자|하기|한테|라서|면|다면)$/;
function tokenize(text) {
  return text
    .toLowerCase()
    .replace(/[,.!?():·"'`\/\\]/g, " ")
    .split(/\s+/)
    .map((w) => w.replace(KOREAN_SUFFIX, ""))
    .filter((t) => t.length > 1);
}

function scoreRule(intent, rule) {
  const ti = new Set(tokenize(intent));
  const td = tokenize(rule.description);
  let hits = 0;
  for (const t of td) if (ti.has(t)) hits++;
  // 정규화: 트리거 설명의 특이도(descriptor 어휘 수) 고려
  return td.length === 0 ? 0 : hits / Math.sqrt(td.length);
}

function route(intent) {
  let best = null;
  let second = null;
  for (const r of rules) {
    const s = scoreRule(intent, r);
    if (!best || s > best.score) {
      second = best;
      best = { ...r, score: s };
    } else if (!second || s > second.score) {
      second = { ...r, score: s };
    }
  }
  return { top: best, runnerUp: second };
}

// ── 평가 ──────────────────────────────────────────────────────────────
const results = [];
for (const c of cases) {
  const r = route(c.intent);
  // null expectedSkill = "어떤 skill도 발동 안 돼야" (과잉 라우팅 방지 케이스)
  // → top score가 threshold 미만이면 pass, 이상이면 fail
  let pass;
  if (c.expectedSkill === null) {
    pass = r.top.score < 0.3; // threshold
  } else {
    pass = r.top && r.top.skill === c.expectedSkill && r.top.score > 0;
  }
  results.push({
    intent: c.intent,
    expected: c.expectedSkill,
    predicted: r.top ? r.top.skill : null,
    score: r.top ? r.top.score.toFixed(3) : "0.000",
    runnerUp: r.runnerUp ? `${r.runnerUp.skill}(${r.runnerUp.score.toFixed(3)})` : "-",
    pass,
    notes: c.notes || "",
  });
}

const passed = results.filter((r) => r.pass).length;
const total = results.length;
const accuracy = total > 0 ? (passed / total) * 100 : 0;

// ── 출력 ──────────────────────────────────────────────────────────────
if (flags.json) {
  console.log(
    JSON.stringify(
      {
        project: flags.project,
        rules: rules.length,
        cases: total,
        passed,
        accuracy: Number(accuracy.toFixed(2)),
        results,
      },
      null,
      2,
    ),
  );
} else {
  console.log(`\n📋 Resolver Routing Eval (structural)`);
  console.log(`   규칙 ${rules.length}개 / 케이스 ${total}개 / 통과 ${passed}개 / 정확도 ${accuracy.toFixed(1)}%`);
  console.log();
  console.log("| # | intent | expected | predicted | score | runnerUp | pass |");
  console.log("|---|---|---|---|---:|---|:---:|");
  for (let i = 0; i < results.length; i++) {
    const r = results[i];
    const mark = r.pass ? "✅" : "❌";
    const intent = r.intent.length > 40 ? r.intent.slice(0, 38) + "…" : r.intent;
    console.log(
      `| ${i + 1} | ${intent} | ${r.expected ?? "(none)"} | ${r.predicted ?? "-"} | ${r.score} | ${r.runnerUp} | ${mark} |`,
    );
  }
  const fails = results.filter((r) => !r.pass);
  if (fails.length > 0) {
    console.log();
    console.log(`## 🔴 실패 케이스 상세 (${fails.length}건)`);
    for (const f of fails) {
      console.log();
      console.log(`- **intent**: "${f.intent}"`);
      console.log(`  - 예상: ${f.expected ?? "(none routed)"}`);
      console.log(`  - 실제: ${f.predicted} (score ${f.score})`);
      console.log(`  - 차점: ${f.runnerUp}`);
      console.log(`  - 메모: ${f.notes}`);
    }
    console.log();
    console.log("**해석**: 트리거 설명 키워드가 intent와 낮은 중첩이거나 다른 skill의 설명이 더 잘 맞음. 수정 방향:");
    console.log("1. 해당 skill의 routing 설명을 intent 키워드 포함하도록 강화");
    console.log("2. 또는 golden case를 현실적 표현으로 다듬기");
  }
}

process.exit(passed === total ? 0 : 1);
