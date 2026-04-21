# WO-157: CI Smoke Test 스케줄 워크플로

**담당**: server
**우선순위**: P3
**상태**: backlog

## 배경
뱅크샐러드는 Smoke Test를 GitHub Actions로 4시간마다 실행. Aidy는 daily (매일 06:00 KST)로 시작.

## 구현 요구사항

### 1. GitHub Actions 워크플로
각 프로젝트 (aidy-server, aidy-ios, aidy-android)에 `.github/workflows/smoke-test.yml`:

```yaml
name: Smoke Test
on:
  schedule:
    - cron: '0 21 * * *'  # 매일 06:00 KST (21:00 UTC)
  workflow_dispatch:        # 수동 실행 가능
```

### 2. 서버 (aidy-server)
- 테스트 프로파일로 서버 시작 (테스트 계정 자동 시딩)
- E2E 테스트 실행
- 실패 시 알림 (GitHub 이슈 자동 생성 또는 Slack)

### 3. iOS (aidy-ios)
- macOS runner에서 시뮬레이터 부팅
- `SmokeTests` 타겟만 실행
- 실패 시 스크린샷 아티팩트 업로드

### 4. Android (aidy-android)
- Android 에뮬레이터 부팅 (API 34)
- `connectedDebugAndroidTest --tests "*.smoke.*"` 실행
- 실패 시 스크린샷 아티팩트 업로드

## 완료 기준
- [ ] 3개 프로젝트에 smoke-test.yml 생성
- [ ] 수동 실행 (workflow_dispatch) 동작 확인
- [ ] 실패 시 아티팩트 (스크린샷/로그) 업로드
