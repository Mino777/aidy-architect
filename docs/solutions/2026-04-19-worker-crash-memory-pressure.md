# 워커 반복 크래시 — macOS 메모리 압력 + Swap 포화

**발견일**: 2026-04-19 (s24-R3)
**상황**: autoceo 10R 중 서버 2회 + iOS 1회 크래시 → 코드 보존되나 커밋 유실

## 증상
- `zsh: killed` — SIGKILL로 Claude Code 프로세스 강제 종료
- 워커가 빌드/테스트 실행 중에 주로 발생
- 코드 변경사항은 git working tree에 남지만, 커밋은 안 됨

## 근본 원인

### 메모리 압력 + Swap 포화
- Swap 사용: **14 GB / 15 GB (93.6%)**
- Architect + 3 워커 = 4 Claude 인스턴스 (각 200-400 MB, 총 ~1.5 GB)
- 빌드 도구(gradlew, xcodebuild)가 추가 메모리 소비
- macOS jetsam이 메모리 압력 하에서 프로세스를 선제 SIGKILL

### 악화 요인
- Architect 세션의 컨텍스트 누적 (autoceo 10R + 효율성 분석 + 학습 = 거대 컨텍스트)
- 긴 세션일수록 Architect 프로세스 메모리 증가 → 워커 kill 확률 증가

## 해결

### 세션 수명 제한 (핵심)
- **Compound 완료 → /exit → 새 세션 재시작** (기본 정책)
- /compact로 이어가지 않음 — 프로세스 메모리는 compact로 줄지 않음
- 새 세션 = 새 프로세스 = 깨끗한 메모리

### 동시 인스턴스 최소화
- 2-way 병렬 유지 (3-way 금지)
- 워커 빌드 중에는 다른 워커 dispatch 자제
- 16GB MacBook Air에서 안전한 동시 인스턴스: **최대 3개** (architect + 2 워커)

### 크래시 복구 프로토콜
1. `git status --short` → 변경사항 확인
2. 변경 있으면 Architect 대리 커밋 (`— architect 대리 커밋 (워커 크래시)`)
3. 워커 재시작: `tmux send-keys ... "claude --dangerously-skip-permissions" Enter`
4. 다음 작업 지시 (이전 작업 이어서가 아닌, 다음 단계로)

## 체크리스트
- [ ] autoceo 시작 전 `vm_stat` / `sysctl vm.swapusage` 확인
- [ ] Swap 80%+ 면 불필요 프로세스 정리 후 시작
- [ ] Compound 후 반드시 /exit (compact 아님)
- [ ] 16GB 머신: 동시 Claude 인스턴스 3개 이하
