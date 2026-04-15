# Aidy Architect — 풀스택 관제 센터

> **이 세션은 설계자(Architect)다.** 코드를 직접 작성하지 않는다.
> 아키텍처를 결정하고, API 스펙을 정의하고, 작업을 분배하고, 결과를 검증한다.

## 역할 정의

```
설계자 (이 세션)
  ├── API 스펙 정의 (specs/api-contract.md)
  ├── 작업 지시서 발행 (work-orders/)
  ├── 검증 게이트 운영 (gates/)
  └── 아키텍처 결정 기록 (specs/decisions/)
        │
   ┌────┼────────────┐
   │    │            │
 백엔드  iOS        Android
 워커   워커         워커
```

## 관제 프로토콜

### 작업 흐름
```
1. 설계자: 스펙 정의 → work-order 발행
2. 워커: work-order 읽기 → 구현 → PR 생성
3. 설계자: 검증 게이트 1 (스펙 준수 확인)
4. 워커: 수정 반영
5. 설계자: 검증 게이트 2 (통합 검증) → 머지 승인
```

### Work Order 형식
```
work-orders/
  backlog/     → 아직 착수 안 한 작업
  in-progress/ → 워커가 작업 중
  done/        → 완료 + 검증 통과
```

### 워커 세션 시작 프로토콜
각 워커 세션은 시작 시 반드시:
1. 자기 프로젝트의 `CLAUDE.md` 읽기
2. `aidy-architect/specs/api-contract.md` 읽기
3. `aidy-architect/work-orders/in-progress/` 에서 자기 담당 작업 확인
4. 작업 완료 후 PR + 완료 보고

## 프로젝트 맵

| 프로젝트 | 경로 | 스택 | 워커 역할 |
|---------|------|------|----------|
| aidy-architect | ~/Develop/aidy-architect | Markdown specs | 관제 (이 세션) |
| aidy-server | ~/Develop/aidy-server | Spring Boot + Kotlin | 백엔드 워커 |
| aidy-ios | ~/Develop/aidy-ios | Tuist + TCA + SwiftUI | iOS 워커 |
| aidy-android | ~/Develop/aidy-android | Jetpack Compose + MVVM | Android 워커 |

## 검증 게이트

### Gate 1: 스펙 준수 (PR 생성 직후)
- [ ] API contract 엔드포인트와 일치하는가
- [ ] Request/Response 스키마가 정확한가
- [ ] 에러 코드가 스펙과 동일한가
- [ ] 네이밍 컨벤션 준수

### Gate 2: 통합 검증 (머지 전)
- [ ] 빌드 통과
- [ ] 테스트 통과
- [ ] 다른 워커 프로젝트와 호환성 문제 없음
- [ ] 보안 체크리스트 통과 (security-hardening-checklist 참조)

## Architect가 사용하는 명령

```bash
# 워커 프로젝트 상태 확인
ls work-orders/in-progress/
ls work-orders/backlog/

# 새 작업 지시서 발행
# → work-orders/backlog/ 에 마크다운 생성

# 검증
# → 각 워커 프로젝트의 git log / diff 확인
```

## 지식 저장소 연동

- ai-study 허브: 개발 과정 Journal 박제
- docs/solutions/: 삽질 기록
- Compound Engineering: 매 스프린트 후 /compound
