# WO-004 회고 — AI 호출 안정성

**일시**: 2026-04-16
**워커**: server
**소요**: ~6분 (워커 구현) + ~15분 (Gate 1+2 검증)

## 이번에 한 것
- AiService에 에러 분류(4종) + 지수 백오프 재시도 + OkHttpClient 타임아웃 분리 적용
- ai_call_logs 테이블 (Flyway V2) + fire-and-forget 비용 로깅
- AI_TIMEOUT 에러 코드 (504) 추가
- 테스트 11건 (에러 분류 5 + errorCode 매핑 3 + 로깅 3)

## 잘된 것
- /ingest에서 발견한 패턴(ai-study Journal 006)이 그대로 WO로 연결됨 — Compound 원칙 1 (사이클이 곧 자산)
- 워커가 WO 스펙을 정확히 읽고 6분 만에 구현 완료
- Resilience4j 같은 외부 의존성 없이 자체 구현 — 의존성 최소화 판단 적절
- OkHttpClient readTimeout으로 타임아웃 제어 — coroutine withTimeout보다 현재 동기 아키텍처에 적합한 판단
- Gate 1에서 스펙-코드 불일치 1건 발견 → 즉시 수정 (Compound 원칙 10 작동)

## 아쉬운 것 (다음 사이클 입력)
- Gate 1에서 타임아웃 재시도 횟수 스펙-코드 불일치 발견 — WO 작성 시 더 정밀하게
- DB default password 이슈가 WO-001부터 계속 미해결 — 보안 WO 우선순위 올려야
- 테스트가 reflection으로 private 메서드 직접 호출 — 코드 구조 개선 여지

## 다음에 적용할 것
- WO 작성 시 재시도 정책을 표로 더 정밀하게 명시 (횟수, 조건, 백오프)
- DB default password 제거 WO 발행 (보안 체크리스트 일괄 적용)
- WO-005 (5-Layer 검증)는 이번 AiService 구조 위에 바로 쌓을 수 있음

## Compound Assets (이번 사이클에서 생성된 재사용 자산)
- `AiErrorType` enum — 다른 AI 호출에도 재사용 가능
- `executeWithRetry` 패턴 — WO-005 Layer 3 retry와 별개로 동작
- `ai_call_logs` 인프라 — 비용 대시보드, 모니터링 기반
- Gate 1/2 리뷰 문서 — 검증 프로세스 반복 가능

## For AI Agents
다음 세션에서 이 회고를 입력으로 받을 때:
- WO-005 착수 전 AiService.kt의 executeWithRetry 구조를 먼저 이해할 것
- Layer 3 retry는 executeWithRetry와 별개 (네트워크 재시도 vs 검증 재시도)
- ai_call_logs 테이블이 이미 존재하므로 V3 마이그레이션부터 시작
- 테스트 작성 시 reflection 대신 패키지-프라이빗 또는 내부 클래스 추출 고려
