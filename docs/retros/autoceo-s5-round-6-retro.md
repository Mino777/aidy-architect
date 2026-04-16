---
round: 6
session: autoceo-s5
date: 2026-04-16
status: PASS
---

# R6 — 에러 로그 집계 (서버 + 클라)

## 결과
| 워커 | 작업 | 커밋 | 테스트 |
|------|------|------|--------|
| server | ErrorLog entity + V10 migration + GET /api/internal/error-logs | 1 (8 files, +486) | 154 passed |
| ios | ErrorLogClient (file-based) + Settings 뷰어 | 1 (5 files, +272) | 76 passed |
| android | ErrorLogRepository (Encrypted) + 전역 CrashHandler | 1 (5 files, +430) | 69 passed |

## 관찰
- V10 Flyway — `error_logs` 테이블 신설 (id/userId/errorCode/path/message 256/stacktraceHash/createdAt)
- 스택트레이스 raw 저장 금지 → hash만 (중복 감지는 가능하나 PII 노출 없음)
- 클라 모두 로컬 저장만 — 서버 전송 없음 (프라이버시)
- Android Application 클래스에 CoroutineExceptionHandler 전역 설치

## 누적 테스트
- server 154 · iOS 76 · Android 69 → **299 tests · 0 failures**

## 다음
- R7: SSE 스트리밍 채팅 ADR-008 + 서버 엔드포인트
