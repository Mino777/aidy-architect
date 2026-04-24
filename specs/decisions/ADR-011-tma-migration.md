# ADR-011: iOS TMA (The Modular Architecture) 마이그레이션

**상태**: 승인
**날짜**: 2026-04-24
**출처**: [토스 Slash 23 — 레고처럼 조립하는 토스 앱](https://toss.tech/article/slash23-iOS)

## 컨텍스트
Aidy iOS는 단일 App 타겟에 모든 코드가 집중된 모놀리식 구조.
14개 Feature, 14개 Core 모듈이 하나의 프레임워크로 컴파일됨.
빌드 시간 최적화, 모듈 간 의존성 관리, 테스트 격리가 어려움.

## 결정
토스가 채택한 Tuist TMA (The Modular Architecture, 구 µFeatures) 패턴을 적용.

### TMA 5-타겟 구조
각 모듈은 5개 타겟으로 분리:
1. **Sources**: 기능 구현 코드
2. **Interface**: 공개 인터페이스 + 모델 (다른 모듈은 이것만 의존)
3. **Tests**: 단위/통합 테스트
4. **Testing**: Mock 데이터 (테스트/Example에서 사용)
5. **Example**: 미니 앱 (빠른 빌드로 독립 개발)

### 의존성 규칙
- Feature → Feature: Interface만 의존 (구현 참조 금지)
- Feature → Core: Interface 또는 직접 의존 (Core는 유틸이므로)
- Core → Core: 직접 의존 허용
- DI: TCA Dependencies로 런타임 주입

### 레이어 구조
```
App (조립 + DI 등록)
├── Feature/ (각 피처 TMA 5-타겟)
└── Core/ (공통 유틸 TMA)
```

## 도구
- Tuist 4.180.0
- ProjectDescriptionHelpers/Module.swift — 1줄 모듈 생성 헬퍼

## 대안 검토
- SPM 모듈화: Tuist와 호환성 이슈, 기존 Tuist 인프라 활용이 더 효율적
- XcodeGen: Swift DSL이 아닌 YAML 기반, Tuist 이미 사용 중이므로 불필요

## 리스크
- 마이그레이션 중 빌드 깨짐 (전체 구조 변경)
- import 경로 대량 변경
- CI 워크플로 수정 필요 (Workspace 기반으로 전환 가능성)
