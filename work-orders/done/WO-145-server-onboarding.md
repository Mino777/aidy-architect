# WO-145: Onboarding Progress API (v4.3)

**담당**: server
**우선순위**: P2
**상태**: done

## 구현 요구사항

### 1. Entity + Repository
- `OnboardingStep` 엔티티: userId, stepKey(enum), completed, completedAt
- stepKey enum: `first_chat`, `check_memory`, `view_person`, `give_feedback`, `explore_people`

### 2. Service
- `getOnboardingStatus(userId)` — 전체 진행 상황 조회
- `completeStep(userId, key)` — 스텝 완료 처리 (멱등)
- `skipOnboarding(userId)` — 전체 건너뛰기

### 3. Controller (3 endpoints)
- `GET /api/onboarding` — §5.34 스키마 준수
- `POST /api/onboarding/steps/{key}/complete` — §5.34
- `POST /api/onboarding/skip` — §5.34

## 완료 기준
- [ ] 빌드 PASS + 테스트 숫자 보고
- [ ] 응답 스키마가 api-contract §5.34 필드와 일치
- [ ] 에러: INVALID_ONBOARDING_STEP (400)
- [ ] 멱등성: 이미 완료된 스텝 재완료 시 동일 응답
