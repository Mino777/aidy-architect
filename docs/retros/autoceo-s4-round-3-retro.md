---
round: 3
session: autoceo-s4
date: 2026-04-16
status: PASS
---

# R3 — 에러 응답 표준화 + 클라이언트 retryable 매핑

## 결과
| 워커 | 작업 | 커밋 | 파일/라인 |
|------|------|------|----------|
| server | VALIDATION_ERROR 코드 + 필드별 메시지 보존 | 1 | 4 files, +136 |
| ios | APIError.isRetryable + 채팅 재시도 UI | 1 | 4 files, +186 |
| android | ApiException.isRetryable + 채팅 재시도 UI | 1 | 5 files, +289 |

## 스펙 변경
- `specs/api-contract.md` v0.2.1: Error Codes 표에 retryable 컬럼 추가, VALIDATION_ERROR + AI_UNAVAILABLE 문서화, 클라이언트 처리 규칙 추가.

## 관찰
- 두 클라이언트 모두 테스트가 프로덕션 코드보다 많음 (a11y 없이도 ViewModel 로직 검증 가능). 건강한 패턴.
- Server GlobalExceptionHandler 테스트 103줄 — validation 케이스 전수 커버.
- API 계약 스키마 `{error, code}` 유지 — 클라이언트 기존 파서 무변경.

## 다음
- R4: DB 인덱스 + 쿼리 최적화 (server 단독). iOS/Android 독립 소규모.
