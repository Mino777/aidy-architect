# WO-200: iOS Data Export UI (v5.8)

## 목표
설정 화면에서 데이터 내보내기 요청 + 다운로드 UI.

## 스펙 참조
`specs/api-contract.md` §5.48 Data Export (v5.8)

## 구현 범위
1. `DataExportClient` — POST export, GET status, GET download API 클라이언트
2. `DataExportFeature` (TCA) — 내보내기 요청, 폴링, 다운로드 상태 관리
3. `DataExportView` — 내보내기 버튼, 진행률 표시, 다운로드 완료 후 공유 시트
4. Settings 화면에 "데이터 내보내기" 메뉴 추가

## 제약
- 커밋 메시지: `[R3-ios] feat: WO-200 Data Export UI`
- tuist build 통과 필수 (xcodebuild test 금지)
- 새 패키지 설치 금지

## 완료 기준
- [ ] 설정에서 내보내기 버튼 → 진행률 → 다운로드 플로우 동작
- [ ] tuist build 성공
