# /ingest s34 회고 — 토스 TMA 마이그레이션

**일시**: 2026-04-25
**출처**: [토스 Slash 23 — 레고처럼 조립하는 토스 앱](https://toss.tech/article/slash23-iOS)
**소요**: ~2시간

## 이번에 한 것
- 토스의 Microfeatures (TMA) 아키텍처를 Aidy iOS에 완전 적용
- 단일 모놀리식 App → 26개 멀티모듈 TMA 구조로 전환
- Core 12개 + Feature 14개 모듈, 각 5-타겟 (Sources/Interface/Tests/Testing/Example)
- ProjectDescriptionHelpers: 1줄 모듈 생성 헬퍼
- 268 files changed, 7276 insertions, 3492 deletions
- ADR-011 작성

## 잘된 것
- iOS 워커가 Core Phase 1 경험을 Feature Phase 2에 적용 → Feature가 Core보다 빠름
- Agent Teams 활용: 파일 이동 + Project.swift + import 수정을 병렬로
- Architect가 ProjectDescriptionHelpers 인프라를 직접 작성 → 워커에게 명확한 기반 제공
- 교차 검증: 토스 테크블로그 + Tuist 공식 TMA 문서 + GitHub example로 3소스 확인

## 아쉬운 것
- **Core Phase 1에 1시간+**: public 접근제어 추가 + 빌드 에러 루프가 예상보다 길었음. **범위 추정 실패 — 모놀리식→멀티모듈에서 public 추가가 핵심 병목임을 사전에 인지 못함**
- **이름 충돌 7개 모듈**: 모듈명과 타입명 충돌 (SmartNotification 모듈 + SmartNotification struct). **TMA 설계 시 모듈명≠타입명 규칙을 명시하지 않음**
- **Example 앱 미생성**: 시간 제약으로 Example 타겟 생성 스킵. TMA의 핵심 이점 중 하나를 놓침
- **People → Haptics 의존성 경고**: Project.swift에서 누락

## 다음에 적용할 것
- 모듈명은 복수형(Features) 또는 접미사(Feature) 사용하여 타입명과 구분
- TMA 마이그레이션 시 public 접근제어 일괄 추가 스크립트를 먼저 준비
- Example 앱은 다음 세션에서 주요 4개 피처 (Chat, Memory, People, Auth)에 생성

## Compound Assets
- Tuist/ProjectDescriptionHelpers/Module.swift
- specs/decisions/ADR-011-tma-migration.md
- gates/reviews/gate1-s34-tma.md

## For AI Agents
다음 세션에서 이 회고를 입력으로 받을 때:
- Aidy iOS는 TMA 구조 (26 모듈). 새 피처 추가 시 Module 헬퍼 사용
- 새 모듈 생성: Module(name:layer:dependencies:) → targets() 호출
- Feature 간 의존은 .interface() 사용 (구현 직접 참조 금지)
- public 접근제어 잊지 말 것 (모듈 경계에서 필수)
- Example 앱은 아직 미생성 — 추후 추가 필요
