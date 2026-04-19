# WO-068: Chat Sentiment UI (Android, v1.7)

**담당**: android
**우선순위**: P2
**상태**: backlog
**API 버전**: v1.7.0

## 작업 내용

### Sentiment Dashboard UI
- 새 화면: SentimentScreen + SentimentViewModel
- 위치: 대시보드 화면 또는 인사이트 탭에 "감정 분석" 섹션 추가
- 전체 감정: 이모지 + overall 텍스트 + LinearProgressIndicator(score)
- 일별 추이: Compose 커스텀 바 차트 (Canvas 또는 간단한 Column 바)
- 감정 분포: 5대 감정 가로 바 (percentage 기반)
- 기간 선택: Material3 SegmentedButton (7/14/30일)
- AidyApiService: `getSentiment(days: Int)`

### 참조
- `specs/api-contract.md` v1.7 섹션

## 완료 기준
- [ ] 감정 대시보드 화면 존재
- [ ] 일별 추이 차트 + 감정 분포 차트
- [ ] 기간 선택 동작
- [ ] 테스트 최소 8건
- [ ] 커밋: `[R4-android] feat: Chat Sentiment UI (v1.7)`
