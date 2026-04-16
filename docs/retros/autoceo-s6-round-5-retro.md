---
round: 5
session: autoceo-s6
date: 2026-04-16
status: PASS
---

# R5 — Password Reset 서버 + SSE 회복성

## 스펙 변경
`api-contract.md` v0.2.5:
- POST /api/auth/password/reset/request (이메일 토큰 발급, 로그 출력)
- POST /api/auth/password/reset/confirm (토큰 + 새 비번 검증 후 변경)
- ErrorCode.PASSWORD_RESET_TOKEN_INVALID (400)

## 결과
| 워커 | 작업 | 커밋 | 테스트 |
|------|------|------|--------|
| server | V11 + PasswordResetToken + request/confirm 서비스 + 컨트롤러 + 테스트 227 라인 | 1 (10 files, +435) | 192 passed |
| ios | SSE 중간 끊김 1회 자동 재시도 + latency 측정 + 연결중 UI | 1 (3 files, +158) | 99 passed |
| android | SseClient 재시도 + ViewModel 상태 + 테스트 70 라인 | 1 (3 files, +142) | 108 passed |

## 관찰
- 서버: Reset 토큰 32자 SecureRandom URL-safe, 30min 만료, 1회용 (usedAt NOT NULL이 되면 재사용 불가)
- 이메일 발송은 **로그 출력**만 — 실제 SMTP 통합은 다음 iteration
- 존재하지 않는 이메일은 200 응답 (사용자 유출 방지) + no-op
- 클라: SSE 중간 끊김 시 1회만 재시도 (백프레셔 악순환 방지)

## 누적 테스트
- server 192 · iOS 99 · Android 108 → **399 tests · 0 failures**

## 다음
- R6: Password reset 클라 UI (iOS/Android 2단계 플로우)
