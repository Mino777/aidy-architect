# WO-140: People Merge Suggestions UI (v4.1) — iOS

## 담당: ios
## 스펙: api-contract.md § 5.32

## 작업
1. `PersonMergeSuggestion` 모델 + `PersonMergeClient` API
2. `PersonMergeFeature` (TCA Reducer)
   - 중복 인물 제안 목록 / 병합 / 무시
3. `PersonMergeView`
   - 제안 카드 (인물 2명 비교 + confidence %)
   - 병합 확인 다이얼로그 (어느 이름을 유지할지 선택)
   - 무시 버튼
4. People 탭에 "중복 정리" 진입점 추가
5. 테스트 각 최소 3개

## 금지
- 기존 People 화면 구조 변경 금지
- 커밋 1건당 파일 10개 이하
