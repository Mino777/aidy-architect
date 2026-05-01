# WO-202: iOS Calendar Integration UI (v6.0)

## 목표
캘린더 이벤트 조회 + .ics 내보내기 + 구독 URL 관리.

## 스펙 참조
`specs/api-contract.md` §5.50 Calendar Integration (v6.0)

## 구현 범위
1. `CalendarClient` — GET events, GET export, POST/DELETE subscribe API 클라이언트
2. `CalendarFeature` (TCA) — 이벤트 목록, 내보내기, 구독 관리
3. `CalendarView` — 이벤트 리스트, 내보내기 버튼, 구독 URL 복사
4. Settings 화면에 "캘린더 연동" 메뉴 추가

## 제약
- 커밋 메시지: `[R3-ios] feat: WO-202 Calendar Integration UI`
- tuist build 통과 필수 (xcodebuild test 금지)
- 새 패키지 설치 금지

## 완료 기준
- [ ] 이벤트 목록 + 내보내기 + 구독 관리 동작
- [ ] tuist build 성공
