# WO-193: Android — Relationship Report UI (v5.4)

## 담당: android
## 우선순위: P4
## 관련 스펙: api-contract.md § 5.44

## 작업 내용
1. RelationshipReportRepository + API
2. RelationshipReportViewModel (UiState data class 패턴)
3. RelationshipReportScreen — 종합 리포트 Compose UI
4. PersonReportScreen — 인물별 상세 리포트

## 완료 기준
- [ ] Request/Response 스펙 일치
- [ ] UiState data class 패턴 사용
- [ ] period 선택 (monthly/weekly) UI
- [ ] testDebugUnitTest 통과
- [ ] 커밋: `[R3-android] feat: WO-193 Relationship Report UI`

## 제약
- 커밋 1건당 파일 10개 이하
- 기존 패키지만 사용
