/**
 * Layer 3 POC Phase 2c — 쿼리 라우터 v0 (규칙 기반)
 *
 * "모든 쿼리에 RAG → Layer 3가 선형 비용으로 회귀" 안티패턴 회피.
 * 에러 키워드 / 명시 트리거 / 기술 용어가 포함된 쿼리만 검색 실행.
 * 일반 대화("안녕", "감사합니다")는 skip.
 *
 * 설계 원칙:
 *  - false negative(검색 놓침) > false positive(불필요 검색)
 *    → 의심스러우면 검색 실행. 비용은 1~2ms(brute force)이므로 허용 범위
 *  - 규칙은 단순하게, 확장은 N=3 패턴으로
 */

// ── 명시 트리거 (사용자가 의도적으로 검색) ──
const EXPLICIT_TRIGGERS = [
  /^\/search\s/i,
  /^검색[:：\s]/,
  /^찾아[:：\s]/,
  /^search[:：\s]/i,
  /^find[:：\s]/i,
];

// ── 에러 키워드 (스택 트레이스, 에러 메시지 패턴) ──
const ERROR_KEYWORDS = [
  // 일반 에러 패턴
  /error/i,
  /에러/,
  /실패/,
  /fail/i,
  /crash/i,
  /exception/i,
  /bug/i,
  /버그/,
  // 기술 에러 패턴
  /exit\s+\d+/i,
  /not found/i,
  /누락/,
  /안 되/,
  /안되/,
  /못 찾/,
  /Library not loaded/i,
  /SIGABRT/i,
  /SIGSEGV/i,
  /undefined is not/i,
  /cannot read prop/i,
  /TypeError/i,
  /SyntaxError/i,
  // CI/CD
  /billing/i,
  /차단/,
  /blocked/i,
  /timeout/i,
];

// ── 기술 용어 (검색 가치가 높은 도메인 키워드) ──
const TECH_KEYWORDS = [
  // 도구/프레임워크
  /mermaid/i,
  /tuist/i,
  /swiftui/i,
  /next\.?js/i,
  /github\s*actions/i,
  /self-hosted/i,
  /runner/i,
  /webpack/i,
  /vite/i,
  // AI/ML
  /프롬프트/,
  /prompt/i,
  /캐싱/,
  /caching/i,
  /임베딩/,
  /embedding/i,
  /rag/i,
  /토큰/,
  /token/i,
  // 패턴
  /패턴/,
  /pattern/i,
  /아키텍처/,
  /architecture/i,
  /circuit\s*breaker/i,
  /fallback/i,
  /validator/i,
  // 하네스
  /하네스/,
  /harness/i,
  /compound/i,
  /journal/i,
  /솔루션/,
  /solution/i,
  // 질문 패턴 (how-to)
  /어떻게/,
  /방법/,
  /how to/i,
  /왜\s/,
  /why\s/i,
  /차이/,
  /비교/,
  /vs\s/i,
];

// ── 무시 패턴 (일반 대화, 검색 불필요) ──
const SKIP_PATTERNS = [
  /^(안녕|hi|hello|hey|감사|thank|좋아|ok|네|ㅇㅇ|ㅋ|ㅎ)\b/i,
  /^.{0,5}$/,  // 5자 이하 (너무 짧은 쿼리)
];

/**
 * 쿼리 라우팅 결정.
 *
 * @param {string} query - 사용자 쿼리
 * @returns {{ shouldSearch: boolean, reason: string, confidence: 'high'|'medium'|'low' }}
 */
export function routeQuery(query) {
  const trimmed = query.trim();

  // 1. 무시 패턴 체크
  for (const pattern of SKIP_PATTERNS) {
    if (pattern.test(trimmed)) {
      return { shouldSearch: false, reason: "skip_pattern", confidence: "high" };
    }
  }

  // 2. 명시 트리거 체크
  for (const pattern of EXPLICIT_TRIGGERS) {
    if (pattern.test(trimmed)) {
      return { shouldSearch: true, reason: "explicit_trigger", confidence: "high" };
    }
  }

  // 3. 에러 키워드 체크
  for (const pattern of ERROR_KEYWORDS) {
    if (pattern.test(trimmed)) {
      return { shouldSearch: true, reason: "error_keyword", confidence: "high" };
    }
  }

  // 4. 기술 용어 체크
  let techHits = 0;
  for (const pattern of TECH_KEYWORDS) {
    if (pattern.test(trimmed)) techHits++;
  }
  if (techHits >= 1) {
    return {
      shouldSearch: true,
      reason: `tech_keyword (${techHits} hits)`,
      confidence: techHits >= 2 ? "high" : "medium",
    };
  }

  // 5. 길이 기반 휴리스틱 — 긴 쿼리는 구체적일 가능성 높음
  if (trimmed.length >= 20) {
    return { shouldSearch: true, reason: "long_query", confidence: "low" };
  }

  // 6. 기본: 검색 skip
  return { shouldSearch: false, reason: "no_match", confidence: "medium" };
}
