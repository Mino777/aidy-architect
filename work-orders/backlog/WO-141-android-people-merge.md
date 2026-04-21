# WO-141: People Merge Suggestions UI (v4.1) — Android

## 담당: android
## 스펙: api-contract.md § 5.32

## 작업
1. `PersonMergeSuggestion` 데이터 클래스 + `PersonMergeApi` Retrofit
2. `PersonMergeRepository` + `PersonMergeViewModel`
3. Compose UI
   - 제안 카드 (인물 2명 비교 + confidence %)
   - 병합 확인 다이얼로그
   - 무시 버튼
4. People 화면에 "중복 정리" 진입점 추가
5. 테스트 각 최소 3개

## 금지
- 기존 People 화면 변경 금지
- 커밋 1건당 파일 10개 이하
