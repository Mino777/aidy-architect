# WO-116: Memory Tags UI (v3.3) — iOS

## 담당: ios
## 스펙: api-contract.md § 5.24

## 작업
1. `TagClient` — API 5개
2. `TagFeature` (TCA: fetchTags/createTag/deleteTag/addToMemory/removeFromMemory)
3. 태그 관리 화면 (목록 + 생성 + 삭제)
4. 메모리 상세에 태그 칩 표시 + 추가/제거
5. 메모리 목록에서 태그 필터
6. 색상 picker (6~8개 프리셋)
7. 테스트 최소 3개

## 금지
- 새 외부 패키지 금지
- 커밋 1건당 파일 10개 이하
