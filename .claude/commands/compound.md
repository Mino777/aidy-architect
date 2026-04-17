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

## Phase 4 — 프로세스 개선 (자동)

스프린트에서 발생한 **인시던트, 병목, 비효율**을 재료로 프로세스를 개선한다.
유저가 시키지 않아도 compound 시 자동으로 수행.

### 수집할 재료
1. **인시던트**: Enter flush 실패, 워커 stall, tmux 문제, rate limit 등
2. **병목**: 테스트 루프, 빌드 시간, 폴링 대기, 워커 무응답
3. **비효율**: 수동으로 한 작업 중 자동화 가능한 것
4. **에이전트/스킬 갭**: 있었으면 좋았을 에이전트나 커맨드

### 개선 액션 (해당 시에만)
- `architect-cli.sh` 패치 → 커밋
- 에이전트 추가/수정 → 해당 워커 프로젝트에 커밋
- 슬래시 커맨드 추가/수정 → `.claude/commands/`에 커밋
- `docs/solutions/` 에 프로토콜/가이드 작성
- CLAUDE.md 규칙 보강 → 해당 프로젝트에 커밋
- 피드백 메모리 저장 (다음 세션에서 반복 방지)

### 보고 형식 (retro에 포함)
```markdown
## 프로세스 개선 (이번 스프린트)
| 재료 | 개선 | 파일 |
|------|------|------|
| Enter flush 실패 | CLI 5회 재시도 + 실행 마커 | architect-cli.sh |
| iOS 테스트 루프 10분 | Stall Detection 프로토콜 | docs/solutions/ |
```

---

## Phase 5 — 단일 커밋

```bash
cd ~/Develop/aidy-architect
git add docs/ specs/ gates/ CLAUDE.md architect-cli.sh .claude/
git commit -m "compound: WO-{번호} 사이클 문서화 + 프로세스 개선"
```

---

## 안티패턴

- ❌ "특이사항 없음"으로 회고 스킵 — 항상 최소 "다음에 적용할 것" 1개
- ❌ 솔루션을 회고에 섞기 — 솔루션은 독립 파일 (검색 가능해야)
- ❌ 사람용 서술 — LLM-First로 써라. For AI Agents 섹션 필수
