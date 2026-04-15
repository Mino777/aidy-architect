# Gate 1 Review: WO-004 (server)

**일시**: 2026-04-16
**검증자**: Architect
**커밋**: a838644

## 결과: CONDITIONAL

---

## WO 요구사항 대조

### 1. AI Client Wrapper
| 요구 | 코드 | 상태 |
|------|------|------|
| timeout 채팅 30초 | `chatTimeout: Long` + `buildClient(chatTimeout)` (AiService:59) | ✅ |
| timeout 메모리 추출 15초 | `memoryExtractTimeout: Long` + `buildClient(memoryExtractTimeout)` (AiService:60) | ✅ |
| maxRetries 2 | `maxRetries: Int` = 2 (AiService:49) | ✅ |
| model 환경변수 | `@Value("\${aidy.ai.model}")` (AiService:45) | ✅ |

### 2. 에러 분류
| 분류 | WO 스펙 | 코드 (classifyHttpError:179-184) | 상태 |
|------|---------|----------------------------------|------|
| RETRYABLE | 429, 529 | `429, 529 -> AiErrorType.RETRYABLE` | ✅ |
| NON_RETRYABLE | 400, 401 | `in 400..499 -> AiErrorType.NON_RETRYABLE` | ✅ |
| TIMEOUT | SocketTimeoutException | `catch (e: SocketTimeoutException)` (AiService:150) | ✅ |
| UNKNOWN | 5xx | `in 500..599 -> AiErrorType.UNKNOWN` | ✅ |

재시도 정책:
- RETRYABLE: 지수 백오프 (1초, 2초) → ✅ (AiService:104)
- TIMEOUT: 재시도 → ✅ (AiService:158 `if (attempt < maxRetries) continue`)
- NON_RETRYABLE: 즉시 실패 → ✅ (AiService:135 `throw`)
- UNKNOWN (IOException): 즉시 실패 → ✅ (AiService:168 `throw`)

### 3. 비용 로깅
| 요구 | 코드 | 상태 |
|------|------|------|
| model 기록 | `AiCallLog(model = model, ...)` (AiService:201) | ✅ |
| input_tokens | `inputTokens = inputTokens` (AiService:204) | ✅ |
| output_tokens | `outputTokens = outputTokens` (AiService:205) | ✅ |
| duration_ms | `durationMs = durationMs` (AiService:206) | ✅ |
| success/failure | `success = success` (AiService:207) | ✅ |
| fire-and-forget | try-catch로 로그 저장 실패 무시 (AiService:210) | ✅ |
| Flyway migration | V2__create_ai_call_logs.sql 존재 | ✅ |

### 4. 타임아웃 처리
| 요구 | 코드 | 상태 |
|------|------|------|
| AI_TIMEOUT 에러 코드 | `ErrorCode.AI_TIMEOUT` (ApiException:12) | ✅ |
| HTTP 504 | `HttpStatus.GATEWAY_TIMEOUT` | ✅ |
| 사용자 메시지 | "AI 응답이 느려요. 잠시 후 다시 시도해주세요." | ✅ |

### 5. API Contract 일치
| 코드 | 스펙 | 상태 |
|------|------|------|
| AI_TIMEOUT / 504 | api-contract.md Error Codes 표 | ✅ |
| 기존 에러 코드 전체 | 변경 없음 (추가만) | ✅ |

---

## 보안 체크
- [x] API 키 하드코딩 없음 — `${CLAUDE_API_KEY:}` 환경변수
- [x] 에러 메시지에 내부 정보 노출 없음 — errorBody는 로그에만 출력
- [x] 로깅에 민감 정보 없음

---

## 발견 사항

### 🟡 수정필요 (CONDITIONAL 사유)

1. **application.yml 보안**: `DB_PASSWORD:aidy`, `ADMIN_PASSWORD:admin` — default 값이 있음.
   - WO-004 범위는 아니지만 security-hardening-checklist 위반 (line 9, 25).
   - **판정**: 기존 코드(WO-001)부터 존재하던 이슈. WO-004 범위 밖이므로 CONDITIONAL 처리. 다음 WO에서 수정.

2. **타임아웃 재시도 제한**: WO 스펙은 "타임아웃 1회만 재시도"인데, 코드는 `if (attempt < maxRetries) continue`로 maxRetries(=2)까지 재시도 가능.
   - AiService:158 — 타임아웃도 최대 2회 재시도됨.
   - **판정**: 더 안전한 방향이므로 CONDITIONAL. 스펙과 코드를 맞출 필요 있음.

### 🟢 다음 WO
- DB default password 제거 (보안 체크리스트)
- WO-005에서 Layer 1-4 검증 추가 시 AiService 구조와 자연스럽게 연결됨

### ⚪ OK
- 에러 분류 enum 4종 정확
- 지수 백오프 정확 (1초, 2초)
- fire-and-forget 로깅 패턴 정확 (저장 실패 시 warn 로그만)
- Flyway V2 마이그레이션 구조 정상 (created_at 인덱스 포함)
- 테스트 11건 — 에러 분류 5건 + errorCode 매핑 3건 + 로깅 3건

---

## 다음 액션
- [ ] 타임아웃 재시도 횟수: 스펙(1회) vs 코드(maxRetries=2) 정리 → 스펙 업데이트 또는 코드 수정
- [ ] DB default password → 다음 WO에서 제거
- [ ] Gate 2 진행 (빌드 + 테스트 + 통합 검증)
