# WO-158: User Avatar API

**담당**: server
**우선순위**: P4
**상태**: backlog
**스펙**: api-contract.md §5.37

## 구현 요구사항

### 1. Entity
- `UserAvatar` 엔티티: userId(unique), filename, thumbnailFilename, mimeType, size, createdAt
- User 엔티티에 avatarUrl 필드 추가 (nullable)

### 2. Controller + Service
- POST /api/auth/avatar — multipart upload, max 2MB, jpeg/png/webp
- GET /api/auth/avatar — 현재 아바타 정보
- DELETE /api/auth/avatar — 아바타 삭제
- GET /api/auth/avatar/{filename} — 이미지 서빙
- 기존 login/signup/refresh 응답에 avatarUrl 추가

### 3. 파일 저장
- Memory Media와 동일 패턴 (로컬 파일시스템, uploads/avatars/)
- 썸네일: 200x200 리사이즈 (javax.imageio 사용, 새 패키지 금지)

### 4. 테스트
- AvatarControllerTest: upload/get/delete + 에러 케이스

## 완료 기준
- [ ] 4개 엔드포인트 구현
- [ ] login/signup/refresh 응답에 avatarUrl 추가
- [ ] 빌드 PASS + 테스트 숫자 보고
