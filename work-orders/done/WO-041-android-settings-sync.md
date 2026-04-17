# WO-041: Settings 동기화 — Android

**워커**: android
**스펙**: api-contract v0.7 — Section 6. Settings
**라운드**: autoceo-s17-R1

## 작업

1. `SettingsApi` Retrofit 인터페이스 (GET/PUT /api/settings)
2. 기존 SettingsPreferences와 서버 동기화 로직
3. Settings 화면에서 변경 시 서버에 PUT
4. 앱 시작 시 서버에서 GET하여 로컬 반영
5. 테스트: SettingsViewModel 테스트

## 제약

- 오프라인 시 로컬만 변경, 다음 온라인 시 동기화
- 커밋: `[R1-android] feat: Settings 동기화 (v0.7)`
- 커밋 1건당 파일 10개 이하
