# WO-009: 서버 JWT 인증

**담당**: server
**우선순위**: P1
**상태**: done
**참조**: API Contract § 1. Auth, P-001

## 목표
JWT 기반 인증 구현. signup/login API + JWT 토큰 발급 + 기존 API에 인증 미들웨어 적용.

## 스펙 참조
- `specs/api-contract.md` § 1. Auth

## 구현 요구사항

### 1. User 엔티티 + 마이그레이션
- Flyway V6: users 테이블 (id, email UNIQUE, password_hash, nickname, created_at)
- User JPA 엔티티
- UserRepository

### 2. Auth Service
- signup: 이메일 중복 체크 → bcrypt 해시 → User 저장 → JWT 발급
- login: 이메일/비밀번호 검증 → JWT 발급
- JWT: io.jsonwebtoken (jjwt) 라이브러리 사용 (이미 Spring Boot에 포함 가능)
- JWT payload: { userId, email, iat, exp }
- JWT 만료: 7일 (168시간)
- JWT secret: 환경변수 JWT_SECRET (기본값 없음)

### 3. Auth Controller
- POST /api/auth/signup → 201 + { userId, token, nickname }
- POST /api/auth/login → 200 + { userId, token, nickname }
- 에러: DUPLICATE_EMAIL (409), INVALID_CREDENTIALS (401)

### 4. JWT 인증 필터
- JwtAuthenticationFilter: Authorization: Bearer {token} 파싱
- 유효한 토큰 → SecurityContext에 userId 세팅
- 무효/만료 → 401 UNAUTHORIZED
- Auth 엔드포인트 (/api/auth/**)는 인증 제외
- Health 엔드포인트 (/api/health)도 제외

### 5. 기존 API 마이그레이션
- X-User-Id 헤더 제거 → JWT에서 userId 추출
- ChatService, MemoryService, PersonService에서 userId 파라미터 대신 SecurityContext 사용

### 6. 테스트
- AuthController 통합 테스트 (signup, login, 에러)
- JwtAuthenticationFilter 단위 테스트
- 기존 ChatController 테스트에 JWT 토큰 추가

## 주의
- 새 패키지 설치 필요 시: jjwt 라이브러리만 허용 (build.gradle.kts에 추가)
- 비밀번호는 반드시 bcrypt 해시
- JWT secret은 환경변수 필수 (기본값 금지)

## 검증 기준
- [ ] `./gradlew build` 통과
- [ ] POST /api/auth/signup → 201 + JWT
- [ ] POST /api/auth/login → 200 + JWT
- [ ] JWT 없이 /api/chat 호출 → 401
- [ ] 유효한 JWT로 /api/chat 호출 → 기존과 동일 동작
