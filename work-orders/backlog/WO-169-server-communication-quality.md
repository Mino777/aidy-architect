# WO-169: Communication Quality Score API

**담당**: server
**우선순위**: P4
**상태**: backlog
**스펙**: api-contract.md §5.42

## 구현 요구사항

### 1. Controller + Service
- GET /api/insights/communication-quality
- period: week/month/year (기본 month)

### 2. 점수 계산 (AI 불필요, 순수 통계 기반)
- consistency (25%): 연락 목표 달성률 기반. 목표 없으면 주 1회 기준
- depth (25%): 평균 대화 길이 + 메모리 추출률 (메모리수/대화수)
- diversity (25%): 대화한 인물 수 / 전체 인물 수
- responsiveness (25%): 대화 세션 지속률 (2턴 이상 비율)
- overallScore: 4개 차원 가중 평균 (0~100)

### 3. AI suggestions
- suggestions: AI가 분석 결과 기반 조언 2~3개 생성 (한국어)
- 낮은 차원을 중심으로 개선 제안

### 4. 테스트
- CommunicationQualityControllerTest: 점수 계산/빈 데이터/트렌드

## 완료 기준
- [ ] GET /api/insights/communication-quality 구현
- [ ] 4개 차원 점수 정확 (0~100)
- [ ] AI suggestions 생성
- [ ] 빌드 PASS + 테스트 숫자 보고
