# WO-204: Android Contact Import UI (v5.9)

## 목표
전화번호부 연락처를 People로 일괄 등록하는 UI.

## 스펙 참조
`specs/api-contract.md` §5.49 Contact Import (v5.9)

## 구현 범위
1. `ContactImportRepository` — POST import, GET preview API 호출
2. `ContactImportViewModel` — 연락처 읽기 권한, 미리보기, 등록 상태
3. `ContactImportScreen` (Compose) — 연락처 선택, 중복 표시, 등록 결과
4. People 탭에 "연락처 가져오기" 버튼 추가
5. ContactsContract 연동 (READ_CONTACTS 권한)

## 제약
- 커밋 메시지: `[R3-android] feat: WO-204 Contact Import UI`
- testDebugUnitTest 통과 필수
- 새 패키지 설치 금지
- AndroidManifest에 READ_CONTACTS 권한 추가

## 완료 기준
- [ ] 연락처 선택 → 미리보기 → 등록 플로우 동작
- [ ] testDebugUnitTest 빌드 성공
