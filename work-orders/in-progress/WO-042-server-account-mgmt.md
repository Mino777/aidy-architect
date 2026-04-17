# WO-042: ���정 관리 API — 서버

**워커**: server
**스펙**: api-contract v0.7 — PUT /api/auth/password + DELETE /api/auth/account
**라운드**: autoceo-s17-R2

## 작업

1. `AuthService`에 changePassword(userId, currentPw, newPw) 추가
2. `AuthService`에 deleteAccount(userId, password) 추가
3. `AuthController`에 PUT /api/auth/password + DELETE /api/auth/account 추가
4. CASCADE 삭제: User → ChatMessage, Memory, PersonMemory, UserSettings, PasswordResetToken
5. 테스트: 단위 + E2E

## 제약

- currentPassword bcrypt 비교
- newPassword 8자 이상
- 계정 삭제 시 비밀번호 확인 필수
- 커밋: `[R2-server] feat: 비밀번호 변경 + ��정 삭제 (v0.7)`
- 커밋 1건당 파일 10개 이하
