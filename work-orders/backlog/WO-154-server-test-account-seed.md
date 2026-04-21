# WO-154: UI 테스트 전용 계정 시딩 (v4.6)

**담당**: server
**우선순위**: P1
**상태**: backlog

## 구현 요구사항

### 1. 설정
- `application.yml`에 `aidy.test-account.enabled: false` 추가
- `application-test.yml` (테스트 프로파일)에서 `aidy.test-account.enabled: true`

### 2. TestAccountSeeder (ApplicationRunner)
- `aidy.test-account.enabled=true`일 때만 실행
- 서버 시작 시 `uitest@aidy.com` 계정 존재 여부 확인
- 없으면 AuthService.signup 호출하여 생성:
  - email: `uitest@aidy.com`
  - password: `AidyTest2026!`
  - nickname: `Aidy 테스터`
- 있으면 스킵 (멱등)
- 로그 출력: `[TestAccount] 테스트 계정 생성 완료` 또는 `[TestAccount] 이미 존재, 스킵`

### 3. 프로덕션 안전장치
- `@Profile("test")` 또는 `@ConditionalOnProperty(name = "aidy.test-account.enabled")`
- 프로덕션에서는 절대 실행되지 않아야 함

## 완료 기준
- [ ] 빌드 PASS + 테스트 숫자 보고
- [ ] 테스트 프로파일에서 서버 시작 시 계정 자동 생성
- [ ] 이미 존재하는 경우 에러 없이 스킵
- [ ] 기본(프로덕션) 프로파일에서 시딩 안 됨
