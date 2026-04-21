# WO-151: Onboarding Progress UI (v4.3)

**담당**: android
**우선순���**: P2
**상태**: in-progress

## 구현 요구사항

### 1. API 클라이언트
- OnboardingApi: getStatus, completeStep, skip
- OnboardingResponse 모델 (§5.34 스키마)

### 2. ViewModel
- `OnboardingViewModel`: 상태 로드, 스텝 완료, 건너뛰기
- UiState: Loading / Success(steps, progress) / Error

### 3. UI (Jetpack Compose, DESIGN.md 준수)
- 스텝 리스트 (체크리스트 UI)
- 상단 LinearProgressIndicator (Accent #2D7D46)
- 각 스텝: 아이콘 + 타이틀 + Checkbox
- 완료 시 축하 애니메이션 → 메인 화면 전환
- "건너뛰기" TextButton (하단)

### 4. 통합
- 앱 시작 시 GET /api/onboarding 호출
- completed=false면 온보딩 화면 표시
- 각 기능 수행 시 자동으로 completeStep 호출

## 완료 기준
- [ ] 빌드 PASS + 테스트 숫자 보고
- [ ] 온보딩 미완료 시 앱 진입점에서 가이드 표시
- [ ] 5개 스텝 완료 → 축하 화면 → 메인 전환
