# WO-188: Server — People Comparison API (v5.7)

## 담당: server
## 우선순위: P4
## 관련 스펙: api-contract.md § 5.47

## 작업 내용
1. `GET /api/people/compare` — 두 관계인 소통 패턴 비교
2. 기존 데이터(Chat, Mood, Quality, Topic) 집계 + 비교
3. comparison.insights AI 생성
4. 동일 인물 비교 시 VALIDATION_ERROR

## 완료 기준
- [ ] 엔드포인트 스펙 100% 일치
- [ ] personId1 == personId2 검증
- [ ] commonTopics 교집합 계산
- [ ] insights 2개 이상 생성
- [ ] 테스트 작성
- [ ] 커밋: `[R2-server] feat: WO-188 People Comparison API`

## 제약
- 커밋 1건당 파일 10개 이하
- 기존 패키지만 사용
