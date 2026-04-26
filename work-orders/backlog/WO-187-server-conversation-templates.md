# WO-187: Server — Conversation Templates API (v5.6)

## 담당: server
## 우선순위: P4
## 관련 스펙: api-contract.md § 5.46

## 작업 내용
1. `GET /api/templates/conversation` — 카테고리별 맞춤 대화 템플릿
2. `POST /api/templates/conversation/{id}/use` — 사용 기록 (AI 개선용)
3. AI가 관계 맥락 + 최근 대화 분석하여 템플릿 생성
4. 카테고리: congratulation, comfort, gratitude, catchup, apology

## 완료 기준
- [ ] 2개 엔드포인트 스펙 100% 일치
- [ ] personId 필터 시 해당 인물 맥락 반영
- [ ] confidence 점수 포함
- [ ] 테스트 작성
- [ ] 커밋: `[R2-server] feat: WO-187 Conversation Templates API`

## 제약
- 커밋 1건당 파일 10개 이하
- 기존 패키지만 사용
