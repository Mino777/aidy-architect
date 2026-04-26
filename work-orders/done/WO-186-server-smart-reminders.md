# WO-186: Server — Smart Contact Reminders API (v5.5)

## 담당: server
## 우선순위: P4
## 관련 스펙: api-contract.md § 5.45

## 작업 내용
1. `GET /api/reminders/smart` — AI 생성 스마트 리마인더 목록
2. `PATCH /api/reminders/smart/{id}` — 상태 변경 (completed/dismissed)
3. `PUT /api/reminders/smart/settings` — 설정 저장
4. `GET /api/reminders/smart/settings` — 설정 조회
5. SmartReminder 엔티티 + Repository + Service
6. 리마인더 생성 로직 (FREQUENCY_GAP, MILESTONE_APPROACHING, MOOD_DROP, LONG_SILENCE)

## 완료 기준
- [ ] 4개 엔드포인트 스펙 100% 일치
- [ ] 리마인더 생성 트리거 4종 구현
- [ ] settings 기본값 제공
- [ ] Flyway 마이그레이션 파일 생성 (실행 금지)
- [ ] 테스트 작성
- [ ] 커밋: `[R2-server] feat: WO-186 Smart Contact Reminders API`

## 제약
- 커밋 1건당 파일 10개 이하
- 기존 패키지만 사용
