# WO-181: iOS 네트워크 에러 처리 중앙화

**담당**: ios
**우선순위**: P2
**상태**: done

## 배경
네트워크 에러 처리가 비일관적. do-catch 26개뿐이며 각 Feature에서 개별 처리. 중앙화된 에러 전략 필요.

## 구현 요구사항

### 1. Core/Networking 에러 처리 강화
- `APIClient`에 통합 에러 매핑 로직 추가
- HTTP 상태코드 → `APIError` enum 매핑 일관화
- 401 → 자동 로그아웃 (ADR-006)
- 429 → Retry-After 파싱 + 재시도 대기
- 5xx → 재시도 가능 표시

### 2. TCA Reducer 에러 처리 패턴 통일
- 각 Feature Reducer에서 `.failure` 액션 처리 패턴 통일
- 토스트/알림 표시를 위한 공통 에러 State 정의
```swift
// 공통 패턴
case .fetchFailed(let error):
    state.error = error.toUserMessage()
    return .none
```

### 3. 에러 로깅
- Core/ErrorLog 모듈 활용하여 네트워크 에러 기록
- 크래시 방지를 위한 fallback 처리

## 빌드 검증
- `tuist build` 통과 필수
- `xcodebuild test` 금지

## 완료 기준
- [ ] APIClient 에러 매핑 통일
- [ ] Feature Reducer 에러 처리 패턴 통일 (최소 Chat, Memory, People)
- [ ] 401 자동 로그아웃 동작 확인
- [ ] tuist build 통과
