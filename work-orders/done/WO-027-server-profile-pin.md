# WO-027: Server — 프로필 수정 + 메모리 핀

**담당**: server
**우선순위**: P1
**상태**: in-progress
**의존**: api-contract v0.4.0

## 구현 요구사항

### 1. PATCH /api/auth/profile
- AuthController에 PATCH 엔드포인트 추가
- Request: { nickname: string } — 1~20자 검증
- AuthService에 updateProfile 메서드
- User 엔티티의 nickname 업데이트
- 응답: { userId, nickname }

### 2. POST /api/memories/{id}/pin
- MemoryController에 POST 엔드포인트 추가
- Request: { pinned: boolean }
- Memory 엔티티에 `pinned` 필드 추가 (Boolean, default false)
- Flyway 마이그레이션: ALTER TABLE memory ADD COLUMN pinned BOOLEAN DEFAULT FALSE
- 소유권 검증, 존재 확인

### 3. GET /api/memories 확장
- 응답에 `pinned` 필드 포함
- ?pinned=true 쿼리 파라미터 지원
- MemoryResponse DTO에 pinned 추가

### 4. 테스트
- PATCH profile: 성공, 빈 닉네임, 20자 초과 — 3건+
- POST pin: 성공(pin), 성공(unpin), 404, 403 — 4건+
- GET memories pinned filter — 1건+

## 검증 기준
- [ ] PATCH /api/auth/profile 스펙 일치
- [ ] POST /api/memories/{id}/pin 스펙 일치
- [ ] GET /api/memories?pinned=true 동작
- [ ] Flyway 마이그레이션 파일 생성 (실행은 금지)
- [ ] 테스트 8건+ 추가
- [ ] ./gradlew test 전체 통과
