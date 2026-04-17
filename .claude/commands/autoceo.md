# /autoceo — 멀티에이전트 풀 자동 스프린트 루프

Research → 기획 → Architect 명령 → 워커 개발 → QA → Compound를 자동으로 반복한다.
**유저에게 묻지 않고 추천 옵션으로 자동 진행한다.**

## 파라미터

`$ARGUMENTS`에서 모드와 반복 횟수를 파싱한다.

- `/autoceo` → 기본 2회
- `/autoceo 3` → 3회
- `/autoceo dry` → 드라이런 (계획만 출력, 실행 안 함)
- `/autoceo dry 3` → 3라운드 계획만 출력
- 최대 10회, 10 초과 시 10으로 제한

---

## 안전장치 (모든 라운드에 적용)

### 1. Git 체크포인트 + 자동 롤백
라운드 시작 전 **각 워커 프로젝트에** 체크포인트 태그를 생성:
```bash
for project in aidy-server aidy-ios aidy-android; do
  cd ~/Develop/$project
  git tag autoceo-round-N-before
done
```
QA가 3회 연속 실패하면 해당 워커의 라운드를 롤백:
```bash
cd ~/Develop/aidy-<worker>
git reset --hard autoceo-round-N-before
```

### 2. 보호 파일 — 절대 수정 금지
- `specs/api-contract.md` — 스펙은 Step 2에서만 Architect가 수정
- `.claude/settings.json` — 훅 설정
- `.env*` — 환경변수
- Flyway `db/migration/` 기존 파일 (새 파일 생성만 가능)
- Entity 클래스 (구조 변경은 ADR 필요)

### 3. 원자적 커밋
- 커밋 1건당 변경 파일 10개 이하
- 커밋 메시지에 라운드 + 워커: `[R1-server] feat: 메모리 검색 개선`
- 워커에게 전송 시 이 규칙을 명시

### 4. 금지 행동
- `git push` 금지 (유저가 수동으로)
- `git reset --hard` (롤백 제외) 금지
- `rm -rf` 금지
- 새 패키지 설치 금지 (기존만 사용)
- DB 마이그레이션 실행 금지 (파일 생성만)

---

## 매 라운드 실행 (Round N of M)

라운드 시작 시:
```
🔄 Round N/M 시작
📌 Checkpoint: autoceo-round-N-before (3개 프로젝트)
```

### Step 1: Research (리서치)

1. 각 워커 프로젝트 상태 분석:
```bash
for project in aidy-server aidy-ios aidy-android; do
  echo "=== $project ==="
  cd ~/Develop/$project
  git log --oneline -5
  git diff --stat
  grep -rn "TODO\|FIXME\|HACK" src/ --include="*.kt" --include="*.swift" | head -10
done
```

2. `specs/decisions/BACKLOG.md` — 미결정 이슈 확인
3. `docs/solutions/` — 기존 솔루션 참조
4. Gate 리뷰 이력 확인: `gates/reviews/` 에서 이전 FAIL 패턴
5. **JIT 검색** — 이번 라운드 작업 키워드로 관련 지식 조회:
```bash
npm run search -- "<이번 작업 키워드>" 3
```
   과거 솔루션, ADR, 회고에서 관련 교훈이 있으면 Plan에 반영.

6. 우선순위 자동 결정:
   - P0: 깨진 빌드/테스트 → 즉시 수정
   - P1: Gate FAIL 잔여 이슈 → 해결
   - P2: TODO/FIXME → 해결
   - P3: 기술 부채, 아키텍처 개선
   - P4: 새 기능 (다음 WO)

### Step 2: Plan (기획)

1. 이번 라운드 작업 목록 선정 (워커별 3-5개)
2. 스펙 변경이 필요하면 `specs/api-contract.md` 수정 (Architect만)
3. 필요 시 WO 발행 (`work-orders/backlog/`)
4. 워커별 작업 프롬프트 작성

**드라이런 모드 (`dry`):** 여기서 멈춤. 작업 목록만 출력.

### Step 3: Dispatch (Architect → 워커 명령)

서버 먼저, 클라이언트 병렬이 기본. 독립 작업이면 3개 동시.

```bash
# 서버 우선 (API 변경이 있는 경우)
./architect-cli.sh send server "[R{N}] 작업 지시:
1. ~/Develop/aidy-server/CLAUDE.md 읽기
2. ~/Develop/aidy-architect/specs/api-contract.md 읽기
3. 작업: {구체적 작업 목록}
커밋 메시지: [R{N}-server] type: 설명
커밋 1건당 파일 10개 이하."

# 서버 완료 후 또는 독립 작업이면 동시에
./architect-cli.sh send ios "[R{N}] 작업 지시: ..."
./architect-cli.sh send android "[R{N}] 작업 지시: ..."
```

워커 완료 대기:
- 2분 간격으로 `inbox/worker-status.json` 확인
- 전원 idle 되면 Step 4로
- **재시작하지 않음** — 같은 세션에 다음 라운드 프롬프트를 바로 전송 (토큰 절약)
- 재시작은 CLAUDE.md/settings 변경 시 또는 10+ 라운드 누적 시에만

### Step 4: QA (Gate 검증)

각 워커에 대해 순서대로:

```
1. /cross-session-review {워커}  — 코드 line-by-line (메타데이터 신뢰 금지)
2. /gate-1 {워커}               — 스펙 준수 필드별 대조
3. 빌드 검증:
   - server: cd ~/Develop/aidy-server && ./gradlew build
   - ios: cd ~/Develop/aidy-ios && tuist build (가능한 경우)
   - android: cd ~/Develop/aidy-android && ./gradlew assembleDebug (가능한 경우)
```

- 전부 통과 → Step 5로
- 실패 → 해당 워커에 수정 지시 (최대 3회)
- 3회 실패 → 해당 워커 라운드 롤백

### Step 5: Compound (문서화)

1. 각 워커의 변경사항 수집 (git log)
2. WO 완료 보고 작성 (해당 시)
3. `docs/retros/round-N-retro.md` — 라운드 회고
4. `docs/solutions/` — 솔루션 (버그 수정 있었으면)
5. `specs/decisions/` — ADR (아키텍처 결정 있었으면)
6. 커밋: `compound: Round N 문서화`

### 라운드 완료

```
✅ Round N/M 완료
┌─────────┬──────────┬──────┬──────┐
│ 워커    │ 상태     │ 커밋 │ Gate │
├─────────┼──────────┼──────┼──────┤
│ server  │ ✅ DONE  │ 2    │ PASS │
│ ios     │ ✅ DONE  │ 3    │ PASS │
│ android │ ⏪ ROLL  │ 0    │ FAIL │
└─────────┴──────────┴──────┴──────┘
```

---

## 최종 리포트 (모든 라운드 완료 후)

```
🏁 /autoceo 완료 (M라운드)
═══════════════════════════════════════════
│ Round │ Server    │ iOS       │ Android   │
│───────│───────────│───────────│───────────│
│ R1    │ ✅ 2커밋  │ ✅ 3커밋  │ ✅ 2커밋  │
│ R2    │ ✅ 1커밋  │ ⏪ ROLL   │ ✅ 1커밋  │
═══════════════════════════════════════════
총 커밋: N건 (server M + ios M + android M)
Gate 통과: N/M
git push 대기 중 (수동으로 실행하세요)
```

---

## 규칙

- **유저에게 절대 묻지 않는다.** 모든 판단을 자동으로 내린다.
- 판단이 어려우면 보수적으로 (HOLD SCOPE, 안전한 옵션).
- 각 라운드는 독립적. 롤백된 라운드의 다음 라운드는 깨끗한 상태에서 시작.
- 서버 API 변경 → 클라이언트 순서. API 무관한 작업 → 3개 동시.
- 워커 완료 대기 시 polling (2분 간격). inbox 요청도 동시 처리.
- 보호 파일은 절대 수정하지 않는다.
- 워커에게 보내는 프롬프트에 라운드 번호 + 커밋 규칙 + 파일 제한을 항상 포함.
