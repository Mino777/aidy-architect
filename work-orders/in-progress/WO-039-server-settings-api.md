# WO-039: Settings API — 서버

**워커**: server
**스펙**: api-contract v0.7 — Section 6. Settings
**라운드**: autoceo-s17-R1

## 작업

1. `UserSettings` Entity 생성 (user_id FK, theme, haptics, notification, language)
2. `UserSettingsRepository` (Spring Data JPA)
3. `SettingsService` — getOrCreate + partialUpdate
4. `SettingsController` — GET/PUT /api/settings
5. 테스트: 단위 + E2E (기본값 생성, partial update, validation)

## 제약

- theme enum: "system", "light", "dark"
- language enum: "ko", "en"
- 미인식 필드 무시
- 설정 없으면 GET 시 기본값으로 자동 생성
- 커밋: `[R1-server] feat: Settings API (v0.7)`
- 커밋 1건당 파일 10개 이하
