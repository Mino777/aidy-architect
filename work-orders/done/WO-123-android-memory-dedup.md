# WO-123: Memory Deduplication UI (v3.5) — Android

## 담당: android
## 스펙: api-contract.md § 5.26

## 작업
1. `MemoryDuplicateGroup` 데이터 클래스 + `MemoryDeduplicationApi` Retrofit
2. `MemoryDeduplicationRepository` + `MemoryDeduplicationViewModel`
   - 중복 그룹 목록 로드
   - 병합 실행 (mergedContent 편집 가능)
   - 그룹 무시 처리
3. `MemoryDeduplicationScreen` Compose
   - 중복 그룹 카드 (유사도 % 표시)
   - 각 그룹 내 메모리 비교 뷰
   - 병합/무시 버튼
4. Memory 화면에서 "중복 정리" 진입점 추가
5. 테스트 각 최소 3개

## 금지
- 기존 Memory 화면 변경 금지
- 커밋 1건당 파일 10개 이하
