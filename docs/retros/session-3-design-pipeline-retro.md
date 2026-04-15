# 세션 3 회고 — 관계 메모리 설계 풀 파이프라인

**일시**: 2026-04-16
**범위**: 설계 전용 (코드 변경 없음)
**스킬 체인**: /office-hours → /plan-ceo-review → /plan-eng-review → /plan-design-review → /design-consultation

## 이번에 한 것
- /office-hours: "관계 메모리"를 V1 킬러 피처로 확정. ChatGPT 대비 차별화 정의 (구조화 DB + 프라이버시 + 전용 UI)
- /plan-ceo-review: SCOPE EXPANSION 모드. 7개 확장안 전부 수락 → Outside Voice 피드백으로 Phase 1/2 분리
- /plan-eng-review: UNIQUE(userId, normalizedName) + ON CONFLICT, userId 비정규화, 서버 retry queue, 비동기 브리핑
- /plan-design-review: 와이어프레임 3개 화면, 상태 표, 바텀시트/리스트행/확인다이얼로그 결정
- /design-consultation: DESIGN.md 생성 (Organic/Natural, 딥 그린 #2D7D46, Pretendard)

## 잘된 것
- 5개 스킬 연속 실행이 매끄러웠음. 각 스킬의 출력이 다음 스킬의 입력으로 자연스럽게 흘러감
- Outside Voice가 2번(CEO, Eng)에서 실행되어 "7개 전부 수용 = 스코프 관리 실패" 지적 → Phase 1/2 분리라는 핵심 결정으로 이어짐
- 디자인 문서 리뷰 2라운드(6.4 → 7.4)가 품질을 실제로 올림
- 디자인 시스템까지 한 세션에 완성하여, WO 발행 시 워커가 참조할 스펙이 모두 준비됨

## 아쉬운 것 (다음 사이클 입력)
- gstack designer OpenAI API 키 미설정으로 비주얼 목업 생성 실패 → 텍스트 기반 와이어프레임으로 대체
- normalizedName 동명이인 문제는 여전히 CRITICAL GAP — V1.5 수동 merge UI로 미룸
- 디자인 리뷰 Pass 5 (Design System) 5/10에서 멈춤 — DESIGN.md가 세션 마지막에 생성되어 리뷰에 반영 안 됨
- 한국어로 진행하면서 gstack 스킬의 영어 출력과 혼재. 문서는 한국어 통일 필요

## 다음에 적용할 것
- OpenAI API 키 설정 후 /design-shotgun으로 실제 비주얼 목업 생성
- WO 발행 시 DESIGN.md 참조를 명시적으로 포함
- Phase 1 WO를 서버 우선으로 발행 (WO-006 예상), iOS/Android는 서버 완료 후
- normalizedName 품질 측정을 WO-005 (AI 출력 검증)과 묶어서 처리

## Compound Assets (이번 사이클에서 생성된 재사용 자산)
- `~/.gstack/projects/Mino777-aidy-architect/jominho-main-design-20260416-021457.md` — 관계 메모리 디자인 문서 (APPROVED)
- `~/.gstack/projects/Mino777-aidy-architect/ceo-plans/2026-04-16-relationship-memory.md` — CEO 플랜 (Phase 1/2 분리)
- `~/.gstack/projects/Mino777-aidy-architect/jominho-main-eng-review-test-plan-20260416-024500.md` — 테스트 플랜 (17 경로)
- `DESIGN.md` — Aidy 디자인 시스템 (Organic/Natural, 딥 그린)
- gstack learnings 2건 (aidy-relationship-memory-wedge, person-upsert-on-conflict)

## For AI Agents
다음 세션에서 이 회고를 입력으로 받을 때:
- Phase 1 Core WO 발행이 최우선. 선행 조건: WO-002/003 완료 + DB 비밀번호 변경
- 서버 WO에 포함할 것: Person/PersonMemory/MemoryFeedback 테이블, UNIQUE + ON CONFLICT, userId 비정규화, GET /memories/people, retry queue, 피드백 API
- 클라이언트 WO에 포함할 것: 피플 탭 (리스트 행), 기억 확인 카드 (바텀시트), 피드백 버튼 (맞아/틀려 + 확인 다이얼로그), 이니셜 아바타. DESIGN.md 참조 필수
- CEO Plan의 Phase 2 (그룹/브리핑/타임라인/감쇠알림)는 Phase 1 성공 후에만
- normalizedName CRITICAL GAP은 V1 출시 후 데이터 기반으로 판단
