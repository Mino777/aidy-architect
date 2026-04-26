# WO-179: iOS Force Unwrap 제거

**담당**: ios
**우선순위**: P1
**상태**: done

## 배경
프로젝트 전체 250+ force unwrap(!) 존재. 특히 Networking 모듈의 URL(string:)! 28개는 런타임 크래시 위험.

## 구현 요구사항

### 1. Networking 모듈 (최우선)
- `URL(string:)!` → `guard let url = URL(string:) else { throw NetworkError.invalidURL }` 패턴
- `URLComponents.url!` → optional binding 처리
- `JSONEncoder/Decoder` force try → do-catch

### 2. Feature 모듈
- UI 관련 force unwrap: `UIImage(named:)!` 등 → nil coalescing 또는 guard
- TCA Store 관련: 필요 시 `@Dependency` 패턴 활용

### 3. 제외 대상
- 테스트 코드의 force unwrap은 허용 (XCTUnwrap 권장하되 필수 아님)
- SwiftUI Preview의 force unwrap은 허용

## 빌드 검증
- `tuist build` 통과 필수
- `xcodebuild test` 금지 (tuist build만 사용)

## 완료 기준
- [ ] Networking 모듈 force unwrap 0개
- [ ] Feature 모듈 force unwrap 50개 이하 (테스트/Preview 제외)
- [ ] tuist build 통과
- [ ] 제거 전후 개수 보고
