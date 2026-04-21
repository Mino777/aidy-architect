# WO-122: Memory Deduplication UI (v3.5) — iOS

## 담당: ios
## 스펙: api-contract.md § 5.26

## 작업
1. `MemoryDuplicateGroup` 모델 + `MemoryDeduplicationClient` API
2. `MemoryDeduplicationFeature` (TCA Reducer)
   - 중복 그룹 목록 로드
   - 병합 확인 다이얼로그 (suggestedMerge 편집 가능)
   - 그룹 무시 처리
3. `MemoryDeduplicationView`
   - 중복 그룹 카드 (유사도 표시)
   - 각 그룹 내 메모리 비교 뷰
   - 병합/무시 버튼
4. Memory 탭에서 "중복 정리" 진입점 추가
5. 테스트 각 최소 3개

## 금지
- 기존 Memory 화면 레이아웃 변경 금지
- 커밋 1건당 파일 10개 이하
