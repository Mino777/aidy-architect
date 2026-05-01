# WO-205: Android Calendar Integration UI (v6.0)

## 목표
캘린더 이벤트 조회 + .ics 내보내기 + 구독 URL 관리.

## 스펙 참조
`specs/api-contract.md` §5.50 Calendar Integration (v6.0)

## 구현 범위
1. `CalendarRepository` — GET events, GET export, POST/DELETE subscribe API 호출
2. `CalendarViewModel` — 이벤트 목록, 내보내기, 구독 관리
3. `CalendarScreen` (Compose) — 이벤트 리스트, 내보내기 버튼, 구독 URL 복사
4. Settings 화면에 "캘린더 연동" 메뉴 추가

## 제약
- 커밋 메시지: `[R3-android] feat: WO-205 Calendar Integration UI`
- testDebugUnitTest 통과 필수
- 새 패키지 설치 금지

## 완료 기준
- [ ] 이벤트 목록 + 내보내기 + 구독 관리 동작
- [ ] testDebugUnitTest 빌드 성공
