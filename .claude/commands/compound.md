# /compound — WO 완료 후 복리형 지식 축적

WO가 Gate 2를 통과하고 done이 된 후 실행. 이번 사이클의 학습을 박제하여 다음 사이클의 입력으로 만든다.

**핵심**: 박제 없이 done 처리된 WO는 복리 계산에서 제외된다.

---

## Phase 1 — 변경사항 수집

```bash
# 해당 WO의 워커 프로젝트에서 변경 범위 파악
cd ~/Develop/aidy-<worker>
git log --oneline -10
git diff main~N..main --stat
```

이번 대화에서의 디버깅/문제해결 과정도 추출.

---

## Phase 2 — 3가지 문서 생성 (병렬 가능)

### 1. WO 회고 (`docs/retros/WO-{번호}-retro.md`)

```markdown
# WO-{번호} 회고 — {제목}

**일시**: YYYY-MM-DD
**워커**: {server/ios/android}
**소요**: (추정)

## 이번에 한 것
- ...

## 잘된 것
- ...

## 아쉬운 것 (다음 사이클 입력)
- ...

## 다음에 적용할 것
- ...

## Compound Assets (이번 사이클에서 생성된 재사용 자산)
- ...

## For AI Agents
다음 세션에서 이 회고를 입력으로 받을 때:
- ...
```

### 2. 솔루션 (`docs/solutions/YYYY-MM-DD-{slug}.md`)

"다음에 또 만날 수 있는가?" YES일 때만 작성.

```markdown
# {문제 제목}

## 증상
...

## 해결 (before → after)
...

## 근본 원인
...

## 체크리스트 (재발 방지)
- [ ] ...
```

### 3. 의사결정 업데이트 (`specs/decisions/`)

이번 WO에서 아키텍처 결정이 있었으면 ADR 추가.

---

## Phase 3 — CLAUDE.md 동기화

새 API / 컴포넌트 / 구조 변경이 있으면:
- 워커 프로젝트 CLAUDE.md 업데이트
- architect CLAUDE.md 업데이트 (필요시)

---

## Phase 4 — 단일 커밋

```bash
cd ~/Develop/aidy-architect
git add docs/ specs/ gates/ CLAUDE.md
git commit -m "compound: WO-{번호} 사이클 문서화"
```

---

## 안티패턴

- ❌ "특이사항 없음"으로 회고 스킵 — 항상 최소 "다음에 적용할 것" 1개
- ❌ 솔루션을 회고에 섞기 — 솔루션은 독립 파일 (검색 가능해야)
- ❌ 사람용 서술 — LLM-First로 써라. For AI Agents 섹션 필수
