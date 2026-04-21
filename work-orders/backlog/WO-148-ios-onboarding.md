# WO-148: Onboarding Progress UI (v4.3)

**담당**: ios
**우선순위**: P2
**상태**: backlog

## 구현 요구사항

### 1. API 클라이언트
- OnboardingAPI: getStatus, completeStep, skip
- OnboardingStep 모델 (§5.34 스키마)

### 2. Feature (TCA)
- `OnboardingFeature`: State/Action/Reducer
- 스텝 리스트 화면 (체크리스트 UI)
- 완료 시 축하 애니메이션 → 메인 화면 전환
- "건너뛰기" 버튼 (하단)

### 3. UI
- DESIGN.md 준수: Accent #2D7D46, 체크마크 아이콘
- 프로그레스 바 (상단, Accent color)
- 각 스텝: 아이콘 + 타이틀 + 체크 상태
- spring 애니메이션: 스텝 완료 시

### 4. 통합
- 앱 시작 시 GET /api/onboarding 호출
- completed=false면 온보딩 화면 표시
- 각 기능 수행 시 자동으로 completeStep 호출 (채팅 전송 → first_chat 등)

## 완료 기준
- [ ] 빌드 PASS + 테스트 숫자 보고
- [ ] 온보딩 미완료 시 앱 진입점에서 가이드 표시
- [ ] 5개 스텝 완료 → 축하 화면 → 메인 전환
