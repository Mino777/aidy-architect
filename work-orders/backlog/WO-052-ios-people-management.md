# WO-052: People 관리 UI — iOS

**워커**: ios
**스펙**: api-contract v1.2 — People list + merge + edit
**라운드**: autoceo-s22-R3

## 작업

1. AidyAPI에 3개 엔드포인트 추가 (people list, merge, edit)
2. PeopleTab에 전체 인물 목록 표시 (memoryCount, relationship, lastMentionedAt)
3. 인물 상세에서 relationship/displayName 수정 기능
4. 인물 병합: 목록에서 2명 선택 → 병합 확인 → merge API 호출
5. TCA Feature + Unit 테스트

## 제약

- 커밋: `[R3-ios] feat: People 관리 UI (v1.2)`
- 커밋 1건당 파일 10개 이하
- DESIGN.md 참조하여 UI 스타일 맞출 것
