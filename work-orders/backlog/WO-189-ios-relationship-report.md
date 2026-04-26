# WO-189: iOS — Relationship Report UI (v5.4)

## 담당: ios
## 우선순위: P4
## 관련 스펙: api-contract.md § 5.44

## 작업 내용
1. ReportClient (Interface/Live) — API 연동
2. RelationshipReportFeature (TCA Reducer)
3. RelationshipReportView — 종합 리포트 화면
4. PersonReportView — 인물별 상세 리포트
5. 리포트 Summary 카드, TopPeople 리스트, Insights 섹션

## 완료 기준
- [ ] ReportClient Interface + Live 분리 (TMA)
- [ ] Request/Response 스펙 일치
- [ ] period 선택 (monthly/weekly) UI
- [ ] tuist build 통과
- [ ] 커밋: `[R3-ios] feat: WO-189 Relationship Report UI`

## 제약
- 커밋 1건당 파일 10개 이하
- xcodebuild test 금지, tuist build만
- Interface 의존성만 허용 (TMA)
