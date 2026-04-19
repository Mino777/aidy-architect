# Gate-1: WO-091 Server Relationship Nudges (v2.5)

**일시**: 2026-04-19
**결과**: ✅ PASS

## 검증 항목
- [x] GET /api/nudges (limit 파라미터)
- [x] POST /api/nudges/{id}/dismiss
- [x] GET/PUT /api/nudges/settings
- [x] Flyway V29 마이그레이션 (nudges + nudge_settings)
- [x] priority 계산: high(30+), medium(14~29), low(7~13)
- [x] excludedPersonIds JSON 저장
- [x] silentDaysThreshold 1~90, maxNudgesPerDay 1~10 검증
- [x] NUDGE_NOT_FOUND 에러 코드
- [x] 748 tests, 0 failures
- [x] 빌드 PASS (verify server)
