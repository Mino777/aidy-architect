# WO-004: AI 호출 안정성 — Circuit Breaker + Timeout + Retry

**담당**: server
**우선순위**: P2-보통
**상태**: done
**의존**: WO-001 완료 (기존 AI 호출 로직 위에 래핑)

## 목표
AI 호출(Claude API)에 timeout + retry + 에러 분류 + 비용 로깅을 적용하여, 단일 장애가 전체 서비스를 멈추지 않게 한다.

## 배경
- ai-study wiki: Harness Journal 006 (Anthropic 클라이언트 wrapper 이식 패턴)
- ai-study wiki: AI 호출 패턴 — Circuit Breaker, Multi-Provider 폴백
- 현재 aidy-server: AI 호출에 timeout/retry 없음 → API 응답 무한 대기 가능

## 구현 요구사항

### 1. AI Client Wrapper
기존 직접 호출을 wrapper로 감싼다:
```
AiClient.chat(messages, options) → AiResponse
```

options:
- `timeout`: 30초 기본 (채팅), 15초 (메모리 추출)
- `maxRetries`: 2 (재시도 가능한 에러만)
- `model`: 설정값 (환경변수)

### 2. 에러 분류
| 분류 | HTTP Status | 재시도 | 예시 |
|------|------------|--------|------|
| RETRYABLE | 429, 529 | O (지수 백오프) | Rate limit, Overloaded |
| NON_RETRYABLE | 400, 401 | X | Invalid request, Auth fail |
| TIMEOUT | - | O (maxRetries까지, 지수 백오프) | 응답 없음 |
| UNKNOWN | 5xx | X | 서버 에러 |

### 3. 비용 로깅 (fire-and-forget)
매 AI 호출마다 로깅:
- model, input_tokens, output_tokens
- duration_ms
- 성공/실패 여부
- DB 테이블: `ai_call_logs` (Flyway migration)

### 4. 타임아웃 처리
- Kotlin coroutine `withTimeout` 사용
- 타임아웃 시 사용자에게 "AI 응답이 느려요. 잠시 후 다시 시도해주세요." 반환
- Error code: `AI_TIMEOUT` (api-contract에 추가 필요)

## 테스트 요구사항
- [ ] 타임아웃 시 적절한 에러 반환 (AI_TIMEOUT)
- [ ] 429 에러 시 재시도 후 성공
- [ ] 재시도 불가 에러 시 즉시 실패
- [ ] ai_call_logs 테이블에 로그 적재 확인
- [ ] 정상 호출 시 기존 동작과 동일

## 검증 기준 (Gate 통과 조건)
- [ ] 기존 채팅 + 메모리 추출 정상 동작 (회귀 없음)
- [ ] `./gradlew test` 전체 통과
- [ ] `./gradlew build` 통과
- [ ] AI 호출에 timeout이 설정되어 있음 (코드 확인)
- [ ] 에러 분류가 위 표와 일치
- [ ] ai_call_logs 마이그레이션 + 로깅 동작

## API Contract 변경 필요
- Error Codes 표에 `AI_TIMEOUT | 504 | AI 응답 시간 초과` 추가
- Architect가 api-contract.md 업데이트 후 워커 시작

## 워커 세션 시작 명령
```
이 세션의 역할: aidy-server 백엔드 워커
프로젝트: ~/Develop/aidy-server

시작 전 반드시 읽기:
1. ~/Develop/aidy-server/CLAUDE.md
2. ~/Develop/aidy-architect/specs/api-contract.md
3. ~/Develop/aidy-architect/specs/conventions.md
4. 이 work-order (WO-004)

작업 완료 후:
- git commit + push
- 이 파일의 "완료 보고" 섹션 작성
- ~/Develop/aidy-architect/inbox/ 에 완료 알림
```

## 완료 보고
- 커밋: a838644 `[WO-004] feat: AI 호출 안정성 — 에러 분류 + 재시도 + 타임아웃 + 비용 로깅`
- 변경 파일: 8개 (370 insertions, 33 deletions)
- 빌드/테스트: `./gradlew build` 전체 통과
- 특이사항:
  - Circuit Breaker 라이브러리(Resilience4j) 없이 자체 재시도 로직으로 구현 (외부 의존성 최소화)
  - WO에 명시된 coroutine `withTimeout` 대신 OkHttpClient의 readTimeout으로 타임아웃 제어 (현재 동기 호출 기반이므로 더 적합)
  - `build.gradle.kts` 빈 줄 1개 추가됨 (mockwebserver 의존성 추가/제거 과정에서 발생, 기능 영향 없음)
