# WO-067: Chat Sentiment UI (iOS, v1.7)

**담당**: ios
**우선순위**: P2
**상태**: backlog
**API 버전**: v1.7.0

## 작업 내용

### Sentiment Dashboard UI
- 새 화면: SentimentFeature + SentimentView
- 위치: 대시보드 화면 또는 인사이트 탭에 "감정 분석" 섹션 추가
- 전체 감정: 이모지 + overall 텍스트 + score 바
- 일별 추이: 심플 라인 차트 (SwiftUI Chart 또는 커스텀 바 차트)
- 감정 분포: 5대 감정 가로 바 차트 (percentage 기반)
- 기간 선택: 7일 / 14일 / 30일 Picker
- APIClient: `getSentiment(days:)`

### 참조
- `specs/api-contract.md` v1.7 섹션

## 완료 기준
- [ ] 감정 대시보드 화면 존재
- [ ] 일별 추이 차트 + 감정 분포 차트
- [ ] 기간 선택 동작
- [ ] 테스트 최소 8건
- [ ] 커밋: `[R4-ios] feat: Chat Sentiment UI (v1.7)`
