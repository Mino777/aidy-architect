# iOS TMA 마이그레이션 후 테스트 인프라 깨짐

## 증상
TMA 5-타겟 구조(Sources/Interface/Tests/Testing/Example) 적용 후:
- xcodebuild test가 1시간+ 소요 (90 타겟 전체 빌드)
- static framework 전환 시 Testing 타겟 링킹 에러
- Feature Tests에서 Interface 타겟 import 실패

## 해결 (before → after)
- Before: dynamic framework + xcodebuild test 전체 실행
- After: static framework 전환 + tuist build만 사용, xcodebuild는 Gate-2에서만

## 근본 원인
TMA 구조에서 각 모듈이 5개 타겟을 가지면 26모듈 × 5 = 130타겟. xcodebuild가 전체를 순차 빌드하여 시간 폭발. static framework로 전환하면 링킹이 빨라지지만, Testing 타겟의 의존성 선언이 누락되면 import 에러 발생.

## 체크리스트 (재발 방지)
- [ ] iOS WO에 "tuist build만, xcodebuild test 금지" 명시
- [ ] TMA 모듈 추가 시 Testing 타겟 의존성 확인
- [ ] 새 Feature 모듈 생성 시 Module.swift 헬퍼 사용
