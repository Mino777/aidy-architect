# 멀티에이전트 autoceo 스프린트 효율성 최적화

**발견일**: 2026-04-19 (s23 종료 후 분석)
**상황**: 11세션 × 10라운드 데이터 분석 → Architect idle 시간이 55%로 가장 큰 병목

## 문제

### Architect idle 시간 55%
- 워커가 구현하는 동안 Architect(Opus 4.6)는 `sleep 300` + pane 확인 반복
- 가장 비싼 모델이 절반 이상 idle → 토큰 대비 산출 비효율

### Gate-1 서브에이전트 과다 소비
- 3개 프로젝트 × sonnet 서브에이전트 = 6만+ 토큰/회
- 신규 엔드포인트 3개에 API contract 전체를 매번 재독

### Android 빌드 미검증 4세션 연속
- s20, s21, s22, s23 — retro에서 언급만 반복, 자동화 안 됨
- 워커 자기보고에만 의존 → s4 iOS 테스트 미실행 사건의 Android 버전 잠복

## 해결

### 1. 라운드 파이프라이닝

**원칙**: 워커가 일하는 동안 Architect도 일한다.

```
Before: [서버 dispatch] → [대기 8분] → [클라 dispatch] → [대기 8분]
After:  [서버 dispatch] → [다음 스펙 작성] → [서버 완료] → [클라 dispatch + 서버 Gate-1]
```

적용 위치: `.claude/commands/autoceo.md` Step 3.5

### 2. 축약 Gate-1

신규 엔드포인트 3개 이하면 Architect가 직접 `git diff` → 스펙 대조:
- 서브에이전트 spawn 없음
- API contract 해당 섹션만 읽음
- 결과를 `gates/reviews/`에 기록

풀 Gate-1은 엔드포인트 4개 이상 또는 복잡한 구조 변경일 때만.

적용 위치: `.claude/commands/autoceo.md` Step 4

### 3. `./architect-cli.sh verify` 명령

```bash
./architect-cli.sh verify server    # gradlew build + test + 숫자 집계
./architect-cli.sh verify android   # assembleDebug + testDebugUnitTest + 숫자 집계
./architect-cli.sh verify all       # 전체 (iOS 제외 — xcodebuild 소요 시간 문제)
```

매 구현 라운드 완료 후 **필수 실행**. 더 이상 retro 언급만으로 넘어가지 않음.

적용 위치: `architect-cli.sh` verify 함수

### 4. 라운드 구조 압축 (10R → 8R)

| 기존 10R | 최적 8R |
|---------|--------|
| R1 스펙1 | R1 스펙1+2 한번에 |
| R2 서버1 | R2 서버1 + (파이프라인: WO 상세화) |
| R3 클라1 | R3 서버2 + 클라1 병렬 |
| R4 Gate-1 | R4 클라2 + Gate-1 축약 |
| R5 스펙2 | R5 Gate-1 전체 + 수정 |
| R6 서버2 | R6 품질 + 테스트 |
| R7 클라2 | R7 verify all |
| R8 Gate-1 | R8 Compound |
| R9 품질 | — |
| R10 Compound | — |

동일 산출, 2라운드 절감.

## 예상 효과

| 지표 | Before | After | 개선 |
|------|--------|-------|------|
| Architect idle | 55% | 30% | -25% |
| 라운드당 시간 | ~10분 | ~7분 | -30% |
| Gate-1 토큰 | 6만+ | 2만 | -67% |
| Android 미검증 | 4세션 | 0 | 완전 해결 |
| 10R 총 시간 | ~100분 | ~56분 | -44% |

## 체크리스트 (다음 autoceo 세션)

- [ ] Step 3.5 파이프라이닝 실행 (서버 대기 중 다음 스펙 작성)
- [ ] 완료된 워커부터 즉시 Gate-1 (전원 대기 안 함)
- [ ] 축약 Gate-1 사용 (EP ≤ 3개)
- [ ] `./architect-cli.sh verify android` 매 구현 라운드 후 실행
- [ ] 라운드 구조 8R 시도

## 정책 박제

- `architect-cli.sh` verify 명령 추가
- `.claude/commands/autoceo.md` Step 3.5 + Step 4 + 라운드 구조 최적화 섹션
- ai-study 위키: `multi-agent-sprint-optimization-patterns.mdx`
