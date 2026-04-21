# WO-143: Chat Export UI (v4.2) — iOS

## 담당: ios
## 스펙: api-contract.md § 5.33

## 작업
1. `ChatExport` 모델 + `ChatExportClient` API
2. `ChatExportFeature` (TCA Reducer)
   - 기간 선택 + 포맷 선택 + 내보내기 실행
   - 내보내기 통계 조회
3. `ChatExportView`
   - 기간 선택 (DatePicker)
   - 포맷 선택 (JSON / 텍스트)
   - 내보내기 버튼 → ShareSheet로 공유
   - 통계 표시 (총 메시지 수, 기간)
4. Chat 설정에서 "대화 내보내기" 진입점 추가
5. 테스트 각 최소 3개

## 금지
- 기존 Chat 화면 구조 변경 금지
- 커밋 1건당 파일 10개 이하
