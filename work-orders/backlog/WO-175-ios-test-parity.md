# WO-175: iOS 테스트 커버리지 보강

**담당**: ios
**우선순위**: P3
**상태**: backlog

## 배경
iOS 748 tests vs Android 998 / Server 1086. TMA 마이그레이션 후 Testing 타겟 활용 + 테스트 갭 해소.

## 구현 요구사항

### 1. TMA Testing 타겟 활용
- 각 Feature 모듈의 Testing 타겟에 mock/stub 추가
- Interface 타겟에 정의된 프로토콜 기반으로 TestDouble 생성
- 최소 Core/Network, Feature/Chat, Feature/Memory, Feature/People

### 2. 테스트 갭 해소
- 현재 테스트 실행하여 커버 안 된 Feature 식별
- 우선순위: Chat (가장 복잡), Memory, People, Settings
- 각 Feature의 주요 Reducer 액션 + Effect 테스트

### 3. 목표
- 748 → 900+ tests
- 0 failures 유지

## 완료 기준
- [ ] Testing 타겟에 mock/stub 추가 (4개+ 모듈)
- [ ] 테스트 150개+ 추가
- [ ] 전체 테스트 green
- [ ] 최종 테스트 숫자 보고
