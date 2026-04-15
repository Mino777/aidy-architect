# WO-005: AI 출력 런타임 검증 — 5-Layer 방어 체계

**담당**: server
**우선순위**: P2-보통
**상태**: in-progress
**의존**: WO-004 완료 (AI Client Wrapper 위에 검증 레이어 추가)

## 목표
AI가 반환하는 메모리 추출 결과를 5단계로 검증하여, 환각/구조 오류가 사용자에게 도달하지 않게 한다.

## 배경
- ai-study wiki: Harness Journal 009-023 (Zod 5-Layer 패턴, type guard 결정)
- ai-study wiki: AI 출력 Zod 검증 패턴
- 현재 aidy-server: AI 응답을 파싱하지만 구조 검증 없음 → 환각이 그대로 통과

## 5-Layer 구조

### Layer 1: 텍스트 가드 (자연어 응답 검증)
- `reply` 필드: 길이 제한 (10~2000자)
- 금지 용어 필터 (내부 프롬프트 노출 방지)
- 빈 응답 차단

### Layer 2: 구조 검증 (메모리 추출 결과)
type guard 방식으로 검증 (Kotlin data class 타입 체크):
- `memoriesExtracted`: Array 타입
- 각 항목: `category` ∈ Memory Categories enum
- 각 항목: `title` string, `content` string 필수
- 검증 실패 시 해당 메모리 항목 drop (전체 실패 아님)

### Layer 3: Retry with Validation
- Layer 1 또는 2 실패 시, 실패 이유를 프롬프트에 추가하여 재요청
- 최대 1회 재시도 (WO-004의 retry와 별도 — 이건 검증 재시도)
- 재시도 시 instruction augmentation:
  ```
  이전 응답에서 다음 문제가 발견되었습니다: {issues}
  올바른 형식으로 다시 응답해주세요.
  ```

### Layer 4: Fallback
- Layer 3까지 실패 시:
  - `reply`는 "죄송해요, 다시 말씀해주세요." 반환
  - `memoriesExtracted`는 빈 배열 반환
  - Error code: `AI_VALIDATION_FAILED` (내부 로깅용, 사용자에게는 정상 응답)

### Layer 5: 품질 로깅 (fire-and-forget, 선택)
- 매 AI 응답의 검증 결과를 DB에 기록
  - 통과 Layer, 실패 사유, 재시도 횟수
  - 테이블: `ai_validation_logs` (Flyway migration)
- LLM-as-Judge는 이번 WO 범위 밖 (P-006에서 검토)

## 구현 요구사항
1. `AiResponseValidator` 클래스 생성
   - `validateReply(reply: String): ValidationResult`
   - `validateMemories(memories: List<*>): ValidationResult`
2. `AiClient.chat()` 호출 후 validation 파이프라인 적용
3. Layer 3 retry는 WO-004의 `AiClient` wrapper와 별도 (검증 레벨 재시도)
4. Flyway migration: `ai_validation_logs` 테이블

## 테스트 요구사항
- [ ] Layer 1: 빈 reply → fallback 동작
- [ ] Layer 1: 금지 용어 포함 reply → 차단
- [ ] Layer 2: category가 enum 밖 → 해당 메모리 drop
- [ ] Layer 2: title/content 누락 → 해당 메모리 drop
- [ ] Layer 3: 검증 실패 → 재시도 → 성공 케이스
- [ ] Layer 4: 재시도도 실패 → fallback 응답
- [ ] 정상 케이스: 기존 동작과 동일

## 검증 기준 (Gate 통과 조건)
- [ ] 기존 채팅 + 메모리 추출 정상 동작 (회귀 없음)
- [ ] `./gradlew test` 전체 통과
- [ ] `./gradlew build` 통과
- [ ] 5-Layer 중 Layer 1~4 구현 확인 (Layer 5는 선택)
- [ ] 환각 카테고리 (enum 밖) → 메모리 저장 안 됨

## 워커 세션 시작 명령
```
이 세션의 역할: aidy-server 백엔드 워커
프로젝트: ~/Develop/aidy-server

시작 전 반드시 읽기:
1. ~/Develop/aidy-server/CLAUDE.md
2. ~/Develop/aidy-architect/specs/api-contract.md
3. ~/Develop/aidy-architect/specs/conventions.md
4. 이 work-order (WO-005)
5. WO-004 완료 보고 (AiClient wrapper 구조 파악)

작업 완료 후:
- git commit + push
- 이 파일의 "완료 보고" 섹션 작성
- ~/Develop/aidy-architect/inbox/ 에 완료 알림
```

## 완료 보고
- PR:
- 소요 시간:
- 특이사항:
