# WO-137: Memory Archive UI (v4.0) — iOS

## 담당: ios
## 스펙: api-contract.md § 5.31

## 작업
1. `MemoryArchive` 모델 + `MemoryArchiveClient` API
2. `MemoryArchiveFeature` (TCA Reducer)
   - 아카이브 목록 / 아카이브 / 복원 / 통계
3. `MemoryArchiveView`
   - 아카이브 목록 화면
   - 메모리 스와이프 → 아카이브 액션
   - 복원 버튼
   - 통계 카드 (카테고리별 파이차트)
4. Memory 탭에 "아카이브" 진입점 추가
5. 테스트 각 최소 3개

## 금지
- 기존 Memory 화면 구조 변경 금지
- 커밋 1건당 파일 10개 이하
