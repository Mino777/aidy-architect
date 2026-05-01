# WO-199: Server Calendar Integration API (v6.0)

## 목표
기념일/스마트 리마인더를 .ics 캘린더로 내보내기 + 구독 URL 제공.

## 스펙 참조
`specs/api-contract.md` §5.50 Calendar Integration (v6.0)

## 구현 범위
1. `CalendarController` — GET /api/calendar/export, GET /api/calendar/events, POST /api/calendar/subscribe, DELETE /api/calendar/subscribe, GET /api/calendar/feed/{feedToken}
2. `CalendarService` — anniversary_reminders + smart_reminders 테이블에서 이벤트 수집, .ics 생성
3. `CalendarSubscription` Entity — feedToken, userId, createdAt
4. Flyway migration — calendar_subscriptions 테이블
5. .ics 생성 유틸 (iCalendar RFC 5545 준수, 외부 라이브러리 없이 문자열 생성)
6. 단위 테스트

## 제약
- 커밋 1건당 파일 10개 이하
- 커밋 메시지: `[R2-server] feat: WO-199 Calendar Integration API`
- 새 패키지 설치 금지 (.ics는 문자열 직접 생성)
- feedToken은 UUID 기반, 인증 헤더 불필요

## 완료 기준
- [ ] 5개 엔드포인트 동작
- [ ] .ics 형식 RFC 5545 준수
- [ ] 단위 테스트 통과
- [ ] 빌드 성공
