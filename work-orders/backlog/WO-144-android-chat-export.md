# WO-144: Chat Export UI (v4.2) — Android

## 담당: android
## 스펙: api-contract.md § 5.33

## 작업
1. `ChatExport` 데이터 클래스 + `ChatExportApi` Retrofit
2. `ChatExportRepository` + `ChatExportViewModel`
3. Compose UI
   - 기간 선택 (DateRangePicker)
   - 포맷 선택 (JSON / 텍스트)
   - 내보내기 버튼 → Intent.ACTION_SEND로 공유
   - 통계 표시
4. Chat 설정에서 "대화 내보내기" 진입점 추가
5. 테스트 각 최소 3개

## 금지
- 기존 Chat 화면 변경 금지
- 커밋 1건당 파일 10개 이하
