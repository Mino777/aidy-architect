# ADR-002: 멀티 세션 오케스트레이션 패턴

**상태**: 확정
**날짜**: 2026-04-15

## 배경

Aidy는 4개 프로젝트(server/ios/android/web)를 동시에 개발한다.
각 프로젝트는 별도 Claude 세션에서 작업하며, 설계자 세션이 관제한다.

## 결정: Hub-Worker Architect 패턴

```
aidy-architect (허브, 이 세션)
  │
  ├── specs/          → 모든 워커가 읽는 절대 스펙
  ├── work-orders/    → 작업 지시서 (backlog → in-progress → done)
  ├── gates/          → 검증 결과 기록
  │
  ├── aidy-server     → 백엔드 워커
  ├── aidy-ios        → iOS 워커
  └── aidy-android    → Android 워커
```

## 핵심 원칙

1. **스펙이 코드보다 먼저**: API contract가 확정된 후에만 구현 시작
2. **워커는 자기 프로젝트만 터치**: 크로스 프로젝트 변경은 설계자 승인 필요
3. **검증 게이트 2단**: Gate 1(스펙 준수) → Gate 2(통합 검증)
4. **Work Order = 최소 실행 단위**: 한 번에 한 기능, 한 PR
5. **Compound 누적**: 매 스프린트 후 ai-study에 Journal 박제

## ai-study 허브-워커 모델에서 검증된 것

- Journal 011: 동시 세션 안전 (3층 충돌 방어)
- Journal 012: /projects-sync 실시간 제약 기반 의사결정
- Journal 014: 양방향 기여 (워커→허브, 허브→워커)
- Journal 019: 크로스 세션 리뷰 5단 프로토콜
