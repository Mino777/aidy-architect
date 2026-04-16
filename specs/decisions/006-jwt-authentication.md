# ADR-006: JWT 인증

**상태**: 승인
**일시**: 2026-04-16
**결정자**: Architect (Jo)

## 컨텍스트
P-001에서 대기 중이던 인증 방식 결정. 관계 메모리(가장 개인적인 데이터)가 서버에 저장되므로 인증 필수.

## 결정
- **방식**: JWT (JSON Web Token) Bearer 인증
- **라이브러리**: jjwt (io.jsonwebtoken)
- **비밀번호**: bcrypt 해시 (Spring Security PasswordEncoder)
- **토큰 만료**: 7일
- **JWT Secret**: 환경변수 JWT_SECRET (기본값 없음)
- **iOS 저장**: Keychain
- **Android 저장**: EncryptedSharedPreferences
- **401 처리**: 자동 로그아웃 (토큰 삭제 → Auth 화면)
- **제외 경로**: /api/auth/**, /api/health

## 대안
- Session 기반 인증: 모바일 앱에 부적합 (stateless 선호)
- OAuth2/Social login: 초기 단계에서 과도 (v0.3+에서 검토)

## 영향
- X-User-Id 헤더 완전 제거
- 모든 API 요청에 Authorization: Bearer 필수
- 기존 테스트에 JWT 토큰 추가
