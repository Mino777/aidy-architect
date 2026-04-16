# 워커 프롬프트 로그

> architect-cli.sh `send` 로 워커(server/ios/android)에게 dispatch한 프롬프트 원문 저장소.
> 목적: 프롬프트 엔지니어링 학습/회고 · 과거 WO 재현 · 프롬프트 패턴 발굴.

## 파일 구조

```
docs/worker-prompts/
├── README.md                          # 이 파일
├── YYYY-MM-DD.md                      # architect-cli.sh 자동 기록 (매 send 호출 시 append)
└── autoceo-sN-backfill.md             # 자동 로깅 이전 스프린트의 수동 백필
```

## 자동 로깅 (R10+ autoceo-s6 이후)
`architect-cli.sh tmux_send` 가 매 호출 시:
- 오늘 날짜로 `YYYY-MM-DD.md` 생성 (없으면)
- `## HH:MM:SS → target` 헤더 + 프롬프트 원문 fenced block 으로 append
- 워커 응답은 기록하지 않음 (커밋 메시지와 retro 로 충분)

## 기록된 정보
- **언제**: timestamp (HH:MM:SS)
- **누구에게**: server / ios / android
- **무엇을**: 프롬프트 원문 (`작업 지시`, 금지 사항, 커밋 규칙, 테스트 요구 포함)

## 학습 포인트 예시

### 잘 작동하는 패턴
- 번호 매긴 작업 단계 (1, 2, 3…)
- `금지:` 섹션 — 범위 이탈 방지
- `실행 증거 필수:` — 테스트 숫자 요구
- 커밋 메시지 형식 지정 `[Rn-target] type: 설명`
- 파일 수 제한 `파일 N개 이하`

### 세션 3~5 교훈 박제된 규칙
- "테스트 통과" 자체 보고 신뢰 금지 → 실행 숫자 요구 (gates/test-policy.md)
- 새 dependency 금지 (예외는 명시적 허용)
- 보호 파일 (api-contract, Flyway V1~Vn, Entity) 건드리지 말 것

### 안티 패턴 (피해야 할 것)
- 모호한 "개선해줘" 지시 — 구체적 파일명/함수명 명시
- 검증 불가능한 요구 ("깔끔하게") — 측정 가능한 기준으로 치환
- 너무 많은 의존 작업 한 라운드에 — WO 분할 권장

## 참고
- 각 스프린트 retro: `docs/retros/autoceo-sN-round-M-retro.md`
- 솔루션 기록: `docs/solutions/`
- 정책: `gates/test-policy.md` + 영역별
