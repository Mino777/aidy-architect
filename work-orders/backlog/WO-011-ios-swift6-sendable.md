# WO-011: iOS Swift 6 Sendable 경고 정리

**담당**: ios
**우선순위**: P2-보통 (현재 빌드 통과, Swift 6 모드 전환 시 에러)
**상태**: backlog → in-progress → gate-1 → gate-2 → done
**의존**: 없음

## 목표
Swift 6 언어 모드 전환에 대비해 누적된 Sendable 경고를 모두 해소한다.

## 발견 경로
WO-010 완료 보고(2026-04-17)에서 워커 보고:
- `SearchHistoryClient.swift`, `ErrorLogClient.swift`, `DraftQueueClient.swift` 등에서
  `concurrently-executed local function ... must be marked as '@Sendable'` 경고 다수
- 현재는 빌드 통과(경고만), Swift 6 언어 모드 전환 시 에러

## 구현 요구사항
1. **현황 수집**: `xcodebuild -project ... build 2>&1 | grep -E "Sendable|@Sendable"` 로 전수
2. **경고 카테고리 분류**:
   - actor isolation 누락
   - 클로저 capture 시 Sendable 미선언
   - protocol 요구사항 변경 (Sendable 추가)
3. **카테고리별 수정 패턴 결정** (예: actor 도입 vs @Sendable 마킹 vs MainActor 격리)
4. **수정 + 테스트 통과 유지** (124 tests 기존 baseline)
5. (선택) `SWIFT_STRICT_CONCURRENCY = complete` 빌드 설정 → 모든 경고 강제

## 검증 기준
- [ ] xcodebuild에서 Sendable 관련 경고 0건
- [ ] 124 tests 통과 유지 (test-policy-ios.md)
- [ ] `tuist build` 통과
- [ ] (선택) Swift 6 언어 모드 활성화 시 빌드 통과
