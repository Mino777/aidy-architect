# WO-185: Server — Relationship Report API (v5.4)

## 담당: server
## 우선순위: P4
## 관련 스펙: api-contract.md § 5.44

## 작업 내용
1. `GET /api/reports/relationship` — 월간/주간 종합 관계 리포트
2. `GET /api/reports/relationship/{personId}` — 인물별 상세 리포트
3. 기존 데이터(Chat, Memory, Mood, Frequency, Quality, Milestone) 집계 로직
4. insights/actionItems AI 생성 (기존 AI 서비스 활용)

## 완료 기준
- [ ] 두 엔드포인트 스펙 100% 일치
- [ ] period=monthly|weekly, date 파라미터 검증
- [ ] 빈 데이터 시 빈 배열 반환 (에러 아님)
- [ ] 테스트 작성
- [ ] 커밋: `[R2-server] feat: WO-185 Relationship Report API`

## 제약
- 커밋 1건당 파일 10개 이하
- 기존 패키지만 사용
