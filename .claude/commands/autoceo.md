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

### Step 0: Preflight (시스템 점검)

매 autoceo 시작 전 반드시 실행:
```bash
./architect-cli.sh preflight
```
- Swap 80%+ → 경고. 불필요 앱 종료 후 시작.
- Claude 인스턴스 4개+ → 경고. 워커 수 줄이기.
- 경고 시에도 유저에게 묻지 않고 보수적으로 진행 (1-way 순차 dispatch).

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
- **5분 간격** 폴링 (토큰 버스트 방지 — s6 교훈)
- 전원 idle 되면 Step 4로
- **재시작하지 않음** — 같은 세션에 다음 라운드 프롬프트를 바로 전송 (토큰 절약)
- 재시작은 CLAUDE.md/settings 변경 시 또는 10+ 라운드 누적 시에만

### Step 3.5: 파이프라이닝 (워커 대기 중 선행 작업)

**워커가 일하는 동안 Architect는 idle하지 않는다.**

서버 워커가 구현 중일 때:
- 다음 피처의 스펙 초안 작성
- 다음 라운드 WO 미리 작성
- 이전 라운드 Gate-1 리뷰 정리

클라이언트 워커가 일하는 동안:
- 완료된 워커부터 즉시 Gate-1 시작 (전원 대기 불필요)
- 서버 빌드 직접 검증 (`./architect-cli.sh verify server`)

```
파이프라인 예시:
[서버 dispatch] → [다음 스펙 작성] → [서버 완료] → [클라 dispatch + 서버 Gate-1] → [클라 완료] → [클라 Gate-1]
```

### Step 4: QA (Gate 검증)

**축약 Gate-1**: 신규 엔드포인트 3개 이하면 Architect가 직접 검증 (서브에이전트 불필요):

```
1. git diff HEAD~N 으로 변경 범위 확인
2. 신규 엔드포인트의 URL/Method/Request/Response를 api-contract.md와 직접 대조
3. 에러 코드 일치 확인
4. 빌드+테스트 직접 검증: ./architect-cli.sh verify <server|android|all>
5. 결과를 gates/reviews/ 에 기록
```

**풀 Gate-1** (서브에이전트): 엔드포인트 4개 이상 또는 복잡한 구조 변경 시:
```
/gate-1 {워커} — 전용 gate-reviewer 에이전트가 line-by-line 검증
```

**빌드 직접 검증 (필수 — s20~s23 4세션 미이행 교훈)**:
```bash
# 매 구현 라운드 완료 후 반드시 실행
./architect-cli.sh verify server   # 항상
./architect-cli.sh verify android  # 항상 (더 이상 생략 금지!)
# iOS는 xcodebuild 소요 시간이 길어 워커 자기보고 + 숫자 확인으로 대체 허용
```

- 전부 통과 → Step 5로
- 실패 → 해당 워커에 수정 지시 (최대 3회)
- 3회 실패 → 해당 워커 라운드 롤백

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

## 마무리: Compound + 워커 재시작

모든 라운드 완료 후, 최종 리포트 출력 → **자동으로 /compound 실행** → 워커 세션 재시작.

1. `/compound` 실행 (Phase 1~5: 회고 + 솔루션 + 인덱스 갱신)
2. 워커 세션 종료 + 재시작:
```bash
./architect-cli.sh send server "/exit"
./architect-cli.sh send ios "/exit"
./architect-cli.sh send android "/exit"
sleep 3
for pane in 1 2 3; do
  tmux send-keys -t aidy:0.$pane "claude --dangerously-skip-permissions" Enter
done
```
3. 워커 idle 확인 후 세션 종료

**Compound를 별도로 돌릴 필요 없다.** autoceo가 끝나면 자동으로 포함된다.

---

## 규칙

- **유저에게 절대 묻지 않는다.** 모든 판단을 자동으로 내린다.
- 판단이 어려우면 보수적으로 (HOLD SCOPE, 안전한 옵션).
- 각 라운드는 독립적. 롤백된 라운드의 다음 라운드는 깨끗한 상태에서 시작.
- 서버 API 변경 → 클라이언트 순서. API 무관한 작업 → 2-way 병렬 (3-way 금지).
- 워커 완료 대기 시 **5분 간격** polling. **idle 시간에 다음 라운드 선행 작업 수행**.
- 보호 파일은 절대 수정하지 않는다.
- 워커에게 보내는 프롬프트에 라운드 번호 + 커밋 규칙 + 파일 제한을 항상 포함.

## 라운드 구조 최적화 (s23 분석 적용)

### 최적 라운드 배치 (피처 2개 기준 8R)
```
R1: 스펙 2개 한 번에 정의 + WO 6개 발행
R2: 서버 피처1 + (파이프라인: 피처2 WO 상세화)
R3: 서버 피처2 + 클라 피처1 병렬
R4: 클라 피처2 + (파이프라인: Gate-1 축약 검증 시작)
R5: Gate-1 전체 + 수정
R6: 품질 + 테스트 보강 (3개 동시)
R7: 빌드 직접 검증 (verify all) + 수정
R8: Compound
```

### 효율성 지표 (목표)
- Architect idle 시간: 55% → 30% 이하
- 라운드당 평균 시간: 10분 → 7분
- Gate-1 소요: 15분 → 8분 (축약 모드)
- Android 빌드 미검증: 0건 (verify 명령 의무화)
