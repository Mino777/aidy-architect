# WO-211: Android Conversation Summary UI (v6.2)

## 목표
채팅 화면에서 대화 요약 생성 + 요약 목록 조회.

## 스펙 참조
`specs/api-contract.md` §5.52 Conversation Summary (v6.2)

## 구현 범위
1. AidyApiService에 createSummary/getSummaries/deleteSummary 추가
2. ChatSummaryRepository
3. ChatSummaryViewModel — 요약 생성, 목록 조회, 삭제
4. ChatSummaryScreen (Compose) — 요약 목록 + 생성 버튼
5. ChatScreen에 "대화 요약" 메뉴 추가
6. ViewModel 테스트

## 제약
- 커밋 메시지: `[R3-android] feat: WO-211 Conversation Summary UI`
- testDebugUnitTest 통과 필수
- 새 패키지 설치 금지

## 완료 기준
- [ ] 요약 생성 + 목록 + 삭제 동작
- [ ] testDebugUnitTest 빌드 성공
