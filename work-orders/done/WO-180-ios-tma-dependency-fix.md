# WO-180: iOS TMA Feature 간 의존성 위반 수정

**담당**: ios
**우선순위**: P2
**상태**: done

## 배경
Settings Feature가 Avatar, Dashboard, Sentiment, ActivityHeatmap 등 다른 Feature를 직접 import. TMA 원칙(Feature→Feature는 Interface만 참조) 위반.

## 구현 요구사항

### 1. 위반 현황 파악
- Settings 모듈에서 다른 Feature 모듈 직접 import 목록 정리
- 각 import가 Interface vs Sources 참조인지 확인

### 2. Interface 분리
- 직접 참조를 `.interface()` 의존으로 전환
- 필요 시 해당 Feature의 Interface 타겟에 공개 뷰/타입 추가
- DI: TCA `@Dependency`로 런타임 주입

### 3. Project.swift 수정
- Settings 모듈의 dependencies에서 직접 참조 → `.interface("FeatureName")` 변경
- 순환 참조 없는지 `tuist graph` 또는 빌드로 검증

## 빌드 검증
- `tuist build` 통과 필수
- `xcodebuild test` 금지

## 완료 기준
- [ ] Settings → 다른 Feature 직접 import 0개
- [ ] 모든 Feature 간 참조가 Interface 경유
- [ ] tuist build 통과
- [ ] 의존성 변경 전후 목록 보고
