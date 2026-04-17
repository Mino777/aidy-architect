# 워커 장시간 Stall 감지 + 개입 프로토콜

**발견일**: 2026-04-17 (s11-R3)
**상황**: iOS 워커가 테스트 통과 루프에 10분+ 갇힘 → architect는 "아직 working" 폴링만 반복

## 문제

기존 모니터링: `inbox/worker-status.json`의 `working/idle` 확인 + `git log` 변화 체크.
이 방식의 한계:
- "working"이면 무조건 대기 → 병목 감지 불가
- xcodebuild 35초 × N회 반복 같은 **무의미한 루프** 구분 불가
- 유저가 직접 지적할 때까지 인지 불가

## 해결: 3단계 모니터링 프로토콜

### Stage 1: 정상 폴링 (0~5분)
```
dispatch 후 1분: 조기 실행 확인 (tmux capture → "esc to interrupt" 확인)
dispatch 후 5분: git log + status 체크
```
- 새 커밋 또는 diff 증가 → 정상 진행

### Stage 2: 지연 감지 (5~10분, 2회 연속 working)
```
2회 연속 working + 커밋 없음 → tmux capture-pane으로 직접 확인
```
**진단 명령:**
```bash
# 워커 pane 최근 25줄 캡처
tmux capture-pane -t "aidy:architect.{pane_idx}" -p | tail -25

# 에러 패턴 검색
tmux capture-pane -t "aidy:architect.{pane_idx}" -p -S -200 | grep -E "error:|Error|fail|❌|FAIL|compilation"
```

**병목 패턴 분류:**

| 패턴 | 증상 | 개입 방법 |
|------|------|----------|
| **테스트 루프** | xcodebuild/gradlew 반복, 같은 에러 | "먼저 커밋, 테스트 별도" 지시 |
| **빌드 에러 루프** | compilation error 반복 | 에러 메시지 파악 → 구체적 수정 힌트 |
| **Rate limit** | 429, "usage limit" | 대기 또는 다음 라운드로 defer |
| **Permission 대기** | "bypass permissions" + 프롬프트 입력 상태 | Enter 전송 |
| **무응답** | idle인데 diff 없음, 커밋 없음 | 프롬프트 재전송 |

### Stage 3: 원격 개입 (10분+)
```
1. 유저에게 보고: "[워커]가 [병목 패턴]에 [N분째] — 개입합니다"
2. 워커에게 탈출 지시 전송 (예: "먼저 커밋, 테스트 별도")
3. 2분 후 효과 확인
4. 2회 개입 실패 → Stage 4로 에스컬레이션
```

### Stage 4: Architect 직접 개발 개입 (15분+ 또는 개입 2회 실패)
워커가 풀지 못하는 병목을 Architect(Opus 4.6)가 직접 해결.

```
1. 유저에게 보고: "[워커] 병목 미해결 — Architect가 직접 코드 수정합니다"
2. 워커 프로젝트 디렉토리에서 직접 작업:
   - Agent(subagent_type=general-purpose) 또는 직접 Read/Edit으로 코드 수정
   - 워커가 못 고친 테스트 에러, 빌드 에러 등을 직접 fix
3. 수정 후 커밋: [R{N}-{worker}] fix: architect 직접 개입 — {수정 내용}
4. 워커에게 "다음 작업 진행" 지시 (이미 고쳐놨으니 이어서)
```

**직접 개입 판단 기준:**
- 같은 에러로 3회+ xcodebuild/gradlew 반복
- 워커가 "해결 불가" 또는 동일 패턴 반복 감지
- 시간 압박 (autoceo 라운드 지연이 전체 스프린트에 영향)

**직접 개입 시 주의:**
- 워커의 unstaged 변경과 충돌하지 않도록 `git stash` 후 작업
- 커밋 메시지에 "architect 직접 개입" 명시 (회고 추적용)
- 개입 후 반드시 워커에게 상황 공유 (다음 프롬프트에 포함)

## architect-cli.sh 개선 사항 (s11)

### Enter flush 강화
- 3회 → 5회 재시도
- 0.4초 → 1.5초 대기
- 실행 마커 감지 (스피너, Reading, Brewing, esc to interrupt)
- 최종 5초 확인 + 실패 시 경고 출력

### 향후 개선 후보
- [ ] `architect-cli.sh monitor <target>` — 자동 Stage 2 진단 (tmux capture + 패턴 매칭)
- [ ] `/monitor` 슬래시 커맨드에 stall detection 통합
- [ ] 워커별 예상 소요 시간 baseline 추적 (작업 유형별)
- [ ] 자동 개입 옵션 (Stage 3 자동화)
- [ ] Stage 4 자동 트리거 — 에러 패턴 3회 반복 감지 시 Architect Agent 자동 spawn

## 교훈

- **폴링 ≠ 모니터링**. status 확인은 감시가 아니다. 실제 pane을 봐야 한다.
- **빠른 실패가 낫다**: 기능 커밋 먼저 → 테스트 수정 별도가 루프보다 효율적.
- **조기 감지**: 1분 후 실행 확인, 2회 연속 working이면 직접 진단.
