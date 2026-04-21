# WO-138: Memory Archive UI (v4.0) — Android

## 담당: android
## 스펙: api-contract.md § 5.31

## 작업
1. `MemoryArchive` 데이터 클래스 + `MemoryArchiveApi` Retrofit
2. `MemoryArchiveRepository` + `MemoryArchiveViewModel`
3. Compose UI
   - 아카이브 목록 화면
   - 메모리 스와이프 → 아카이브 액션
   - 복원 버튼
   - 통계 카드
4. Memory 화면에 "아카이브" 진입점 추가
5. 테스트 각 최소 3개

## 금지
- 기존 Memory 화면 변경 금지
- 커밋 1건당 파일 10개 이하
