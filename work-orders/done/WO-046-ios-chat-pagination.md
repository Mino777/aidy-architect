# WO-046: Chat pagination + 전체 삭제 — iOS

**워커**: ios
**스펙**: api-contract v0.8
**라운드**: autoceo-s17-R3

## 작업

1. APIClient: chat history에 offset/limit 파라미터 지원
2. ChatView: 스크롤 상단 도달 시 이전 메시지 로드 (infinite scroll)
3. Settings에 전체 대화 삭제 버튼 + 확인 다이얼로그
4. 테스트

## 제약

- 커밋: `[R3-ios] feat: Chat pagination + 전체 삭제 (v0.8)`
- 커밋 1건당 파일 10개 이하
