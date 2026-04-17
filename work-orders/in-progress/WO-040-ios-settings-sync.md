# WO-040: Settings 동기화 — iOS

**워커**: ios
**스펙**: api-contract v0.7 — Section 6. Settings
**라운드**: autoceo-s17-R1

## 작업

1. `SettingsClient` API 클라이언트 (GET/PUT /api/settings)
2. 기존 로컬 설정과 서버 동기화 로직
3. Settings 화면에서 변경 시 서버에 PUT
4. 앱 시작 시 서버에서 GET하여 로컬 반영
5. 테스트: SettingsClient mock + ViewModel 테스트

## 제약

- 오프라인 시 로컬만 변경, 다음 온라인 시 동기화
- 커밋: `[R1-ios] feat: Settings 동기화 (v0.7)`
- 커밋 1건당 파일 10개 이하
