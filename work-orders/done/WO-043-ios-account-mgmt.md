# WO-043: 계정 관리 — iOS

**워커**: ios
**스펙**: api-contract v0.7 — PUT /api/auth/password + DELETE /api/auth/account
**라운드**: autoceo-s17-R2

## 작업

1. APIClient에 changePassword + deleteAccount 엔드포인트 추가
2. Settings 화면에 비밀번호 변경 + 계정 삭제 UI 추가
3. 계정 삭제 시 확인 다이얼로그 + 비밀번호 입력
4. 삭제 성공 시 로그아웃 + 로그인 화면 이동
5. 테스트

## 제약

- 커밋: `[R2-ios] feat: 비밀번호 변경 + 계정 삭제 (v0.7)`
- 커밋 1건당 파일 10개 이하
