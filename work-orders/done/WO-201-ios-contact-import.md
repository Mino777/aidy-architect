# WO-201: iOS Contact Import UI (v5.9)

## 목표
전화번호부 연락처를 People로 일괄 등록하는 UI.

## 스펙 참조
`specs/api-contract.md` §5.49 Contact Import (v5.9)

## 구현 범위
1. `ContactImportClient` — POST import, GET preview API 클라이언트
2. `ContactImportFeature` (TCA) — 연락처 접근 권한 요청, 미리보기, 등록 플로우
3. `ContactImportView` — 연락처 선택 리스트, 중복 표시, 등록 결과
4. People 탭에 "연락처 가져오기" 버튼 추가
5. CNContactStore 연동 (Contacts framework)

## 제약
- 커밋 메시지: `[R3-ios] feat: WO-201 Contact Import UI`
- tuist build 통과 필수 (xcodebuild test 금지)
- 새 패키지 설치 금지
- Info.plist에 NSContactsUsageDescription 추가

## 완료 기준
- [ ] 연락처 선택 → 미리보기 → 등록 플로우 동작
- [ ] tuist build 성공
