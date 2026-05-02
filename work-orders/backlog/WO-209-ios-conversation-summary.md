# WO-209: iOS Conversation Summary UI (v6.2)

## 목표
채팅 화면에서 대화 요약 생성 + 요약 목록 조회.

## 스펙 참조
`specs/api-contract.md` §5.52 Conversation Summary (v6.2)

## 구현 범위
1. APIClient에 createSummary/getSummaries/deleteSummary 추가
2. ChatSummaryFeature (TCA) — 요약 생성 요청, 목록 관리
3. ChatSummaryView — 요약 목록 + 생성 버튼
4. ChatView에 "대화 요약" 메뉴 추가

## 제약
- 커밋 메시지: `[R3-ios] feat: WO-209 Conversation Summary UI`
- tuist build 통과 필수 (xcodebuild test 금지)
- DerivedData 전체 삭제 금지 — build.db만 삭제 후 증분 빌드
- 새 패키지 설치 금지

## 완료 기준
- [ ] 요약 생성 + 목록 조회 + 삭제 동작
- [ ] tuist build 성공
