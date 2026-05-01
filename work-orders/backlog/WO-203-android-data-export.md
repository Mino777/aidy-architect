# WO-203: Android Data Export UI (v5.8)

## 목표
설정 화면에서 데이터 내보내기 요청 + 다운로드 UI.

## 스펙 참조
`specs/api-contract.md` §5.48 Data Export (v5.8)

## 구현 범위
1. `DataExportRepository` — POST export, GET status, GET download API 호출
2. `DataExportViewModel` — 내보내기 요청, 폴링, 다운로드 상태 관리
3. `DataExportScreen` (Compose) — 내보내기 버튼, 진행률, 다운로드 완료 후 공유
4. Settings 화면에 "데이터 내보내기" 메뉴 추가

## 제약
- 커밋 메시지: `[R3-android] feat: WO-203 Data Export UI`
- testDebugUnitTest 통과 필수
- 새 패키지 설치 금지

## 완료 기준
- [ ] 설정에서 내보내기 플로우 동작
- [ ] testDebugUnitTest 빌드 성공
