# WO-077: Server — Daily Digest API (v2.1)

**담당**: server
**스펙**: `specs/api-contract.md` § 5.12 Daily Digest (v2.1)
**선행**: WO-076 (health score 데이터 활용)

## 구현 범위

### 1. DB 마이그레이션
- `daily_digest_cache` 테이블 (Flyway 새 파일만)
  - id, user_id, date, greeting, reminders_json, highlights_json, stats_json, generated_at
  - UNIQUE(user_id, date)

### 2. 엔드포인트 1개
**GET /api/digest/today**
- 오늘 날짜 캐시 확인 → hit이면 반환
- miss → AI 호출로 생성:
  1. 최근 7일 chat history 조회
  2. 전체 메모리 중 최근 변경/추가된 것
  3. 인물 목록 + relationship health score (WO-076 서비스 재사용)
  4. 연속 대화 일수 (streak) 계산
- 24시간 TTL (date 기준)

### 3. AI 프롬프트
- 입력: 최근 대화 요약, 새 메모리, 인물 health 데이터, 현재 시간/요일
- 출력: JSON (greeting, reminders[], highlights[], stats)
- reminders 최대 5개, highlights 최대 3개
- Circuit Breaker 적용

### 4. 테스트
- 단위 테스트: Service (캐시, streak 계산, 빈 데이터 처리)
- 통합 테스트: 엔드포인트

### 커밋 규칙
- 메시지: `[R3-server] feat: Daily Digest API (v2.1)`
- 파일 10개 이하/커밋
