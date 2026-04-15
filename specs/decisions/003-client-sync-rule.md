# ADR-003: iOS/Android 동기화 규칙

**상태**: 확정
**일시**: 2026-04-16
**맥락**: autoceo Round 2에서 iOS(Memory 완성)와 Android(Settings 구현)가 다른 화면을 작업하여 진도 불일치 발생.

## 결정

**iOS와 Android는 항상 같은 화면을 같은 라운드에 구현한다.**

## 규칙

1. 작업 순서: API contract 섹션 순서 (Chat → Memory → Settings → Auth)
2. 서버 API가 먼저 → 클라이언트 2개가 동시에 같은 화면
3. dispatch 시 iOS/Android 프롬프트의 **기능 범위를 동일하게** 명시
4. Gate 2 크로스 검증에서 iOS-Android 간 기능 범위 일치 확인

## 이유

- 크로스 플랫폼 일관성 (같은 기능이 양쪽에 동시 존재)
- Gate 2 통합 검증이 의미를 가짐
- 진도 추적이 단순해짐 (화면 단위)

## 참조

- Round 2 회고: `docs/retros/round-2-retro.md`
