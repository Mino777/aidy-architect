# Round 2 회고

**일시**: 2026-04-16
**라운드**: autoceo Round 2/2

## 이번에 한 것
- **server**: AiService 타임아웃/에러 핸들링 강화, CORS 설정, 500 에러 로깅
- **ios**: 스킵됨 (R1에서 이미 Memory 리스트+삭제 구현 완료)
- **android**: Settings 화면 (서버 URL 동적 변경 + 닉네임 + 앱 버전)

## 잘된 것
- 서버 품질 개선 (타임아웃, CORS, 에러 로깅) — 프로덕션 준비도 향상
- Android Settings 화면 완성도 높음 (동적 URL 변경까지)

## 아쉬운 것
- iOS/Android 작업이 달랐음 (iOS: Memory, Android: Settings) → 진도 불일치
- iOS 워커가 R2를 스킵함 — 작업 지시가 더 구체적이어야 했음

## 교훈 → ADR 박제
- **iOS/Android는 항상 같은 화면을 같은 라운드에 구현해야 한다**
- 서버 API 변경 → 클라이언트 동시에 같은 화면 순서로

## 다음에 적용할 것
- iOS Settings 화면 구현 (Android와 동일하게)
- iOS/Android Memory 화면 동일 수준으로 맞추기
- 핸드오프 정책: 매번 재시작 → 같은 세션 유지 (토큰 절약)

## For AI Agents
- R2에서 iOS/Android 작업 불일치 발생. 다음 autoceo부터 반드시 동일 작업 dispatch.
- 서버는 API 추가 없이 품질 개선만 했으므로 클라이언트 영향 없음.
