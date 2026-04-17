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

### Slash Commands (행동 레벨 가드)
```
/dispatch    — WO 활성화 + 워커에게 전송 (부분 실행 불가)
/gate-1      — 스펙 준수 검증 (코드 line-by-line, 메타데이터 신뢰 금지)
/gate-2      — 통합 검증 (빌드 + 테스트 + 크로스 프로젝트 호환성)
/cross-session-review — 워커 결과물 크로스 검증 (Journal 019 프로토콜)
/monitor     — 전체 워커 상태 + WO 현황 모니터링
/compound    — WO 완료 후 회고 + 솔루션 + 의사결정 문서화
/autoceo     — 풀 자동 스프린트 (Research→기획→명령→개발→QA→Compound × N라운드)
/ingest      — 외부 URL/키워드 → 교차 검증 → Aidy에 적용 가능한 패턴 흡수
```

### CLI 명령
```bash
./architect-cli.sh wo <번호>            # WO 활성화 (backlog → in-progress)
./architect-cli.sh wo-done <번호>       # WO 완료 (in-progress → done)
./architect-cli.sh send <워커> "<msg>"  # tmux로 워커에게 명령
./architect-cli.sh status               # WO 현황
```

### 워크플로 (4단계 루프)
```
Plan:     WO 발행 + /dispatch
Work:     워커가 구현
Review:   /gate-1 → /gate-2 → /cross-session-review
Compound: /compound (회고 + 솔루션 + ADR)
```

## JIT 검색 (시맨틱 검색)

위키/스펙/가이드 지식이 필요할 때 먼저 검색을 실행:

```bash
npm run search -- "<질문>" 5 --inject
```

예시:
```bash
npm run search -- "Stall Detection 프로토콜" 3
npm run search -- "아키텍처 설계 패턴" --inject
```

**구성:**
- 모델: `Xenova/multilingual-e5-small` (로컬, 384d)
- 소스: `docs/` (53개 .md) + 루트 가이드 (5개 .md) = 308개 청크
- 속도: 1~3ms (brute force, 1000개 미만은 ANN 불필요)
- 라우터: 기술용어/에러/명시트리거만 검색 실행, 일반대화는 skip

**언제 사용:**
- 아키텍처 결정 시 기존 스펙/패턴 확인
- 에러 메시지 → 과거 솔루션 검색
- WO 구성 시 관련 기준 자료 조회

## 토큰 최적화 규칙

### 모델 라우팅
- 서브에이전트 frontmatter: 탐색/조회 → `model: haiku`, 검증/판단 → `model: sonnet`
- Explore subagent로 코드 탐색 격리 (새 컨텍스트, haiku 전용)
- `/compact` 습관화 — 대화 길어지면 압축

### 캐시 보존 (Frozen Snapshot 원칙)
- 활성 세션 중 CLAUDE.md 수정 금지 (캐시 전체 무효화 + 1.25x 오버헤드)
- 변경이 필요하면 메모리에 기록만 하고, `/compound` Phase 3에서 일괄 반영
- 5분 TTL — 휴식 전 세션 정리, 돌아와서 새 세션 시작

### Prefix 다이어트
- CLAUDE.md ≤ 200줄 유지, 상세는 슬래시 커맨드로 분리
- `.claudeignore`로 done/ WO, lock 파일 등 제외

## 성숙도 Ladder (Compound Engineering)

| Stage | 상태 | 현재 |
|-------|------|------|
| 1. 수동 | 사람이 기억해서 수행 | |
| 2. 리마인드 | 훅/알림이 상기 | |
| 3. 슬래시 커맨드 | /compound 등으로 통합 | **← 현재** |
| 4. 자동 루프 | /autoceo가 N 라운드 반복 | 실험 중 |
| 5. 완전 자율 | 입력→실행→박제→다음 사이클 | 목표 |

## 지식 저장소 연동

- ai-study 허브: 개발 과정 Journal 박제
- docs/solutions/: 삽질 기록
- Compound Engineering: 매 스프린트 후 /compound

## Design System
Always read DESIGN.md before making any visual or UI decisions.
All font choices, colors, spacing, and aesthetic direction are defined there.
Do not deviate without explicit user approval.
In QA mode, flag any code that doesn't match DESIGN.md.

## Skill routing

When the user's request matches an available skill, ALWAYS invoke it using the Skill
tool as your FIRST action. Do NOT answer directly, do NOT use other tools first.
The skill has specialized workflows that produce better results than ad-hoc answers.

Key routing rules:
- Product ideas, "is this worth building", brainstorming → invoke office-hours
- Bugs, errors, "why is this broken", 500 errors → invoke investigate
- Ship, deploy, push, create PR → invoke ship
- QA, test the site, find bugs → invoke qa
- Code review, check my diff → invoke review
- Update docs after shipping → invoke document-release
- Weekly retro → invoke retro
- Design system, brand → invoke design-consultation
- Visual audit, design polish → invoke design-review
- Architecture review → invoke plan-eng-review
- Save progress, checkpoint, resume → invoke checkpoint
- Code quality, health check → invoke health
