# 보안 강화 체크리스트 — Aidy 프로젝트

> ai-study 보안 스프린트에서 검증된 패턴을 Aidy 스택에 맞게 적용.

---

## 공통 (전 플랫폼)

- [ ] 환경변수에 default 값 없음 (`|| "dev-secret"` 패턴 금지)
- [ ] API 키 / 시크릿이 코드에 하드코딩 없음
- [ ] 에러 메시지에 내부 정보 노출 없음 (스택 트레이스, DB 쿼리 등)
- [ ] Request body 크기 제한 적용
- [ ] 의존성 취약점 감사 (gradle audit / npm audit / SPM 검증)
- [ ] HTTPS 전용 통신 (HTTP 허용 안 함)
- [ ] 로깅에 민감 정보 없음 (비밀번호, 토큰, 개인정보)

---

## 서버 (Spring Boot + Kotlin)

### Critical
- [ ] `CLAUDE_API_KEY` 등 API 키가 `application.yml`에 하드코딩 없음 → 환경변수만
- [ ] 비밀번호 저장 시 BCrypt (PasswordEncoder) 사용
- [ ] SQL Injection 방지 — JPA/Spring Data 사용, raw query 금지
- [ ] CORS 설정 — 허용 origin 명시 (`*` 금지)

### High
- [ ] Rate Limiting 적용 (Spring Boot Bucket4j 또는 커스텀)
- [ ] Security Headers 설정 (X-Frame-Options, X-Content-Type-Options, HSTS)
- [ ] JWT 토큰 검증 시 Timing-Safe 비교 (v0.2 auth 구현 시)
- [ ] Flyway migration에 destructive DDL 없음 (DROP TABLE 등)

### Medium
- [ ] 입력 값 검증 (@Valid, @NotBlank 등)
- [ ] Actuator 엔드포인트 보안 (production에서 비활성화 또는 인증)
- [ ] Docker 이미지 non-root 사용자

---

## iOS (TCA + SwiftUI)

### Critical
- [ ] API 키가 소스코드에 하드코딩 없음 → Keychain 또는 xcconfig
- [ ] Keychain에 민감 데이터 저장 (UserDefaults 금지)
- [ ] ATS (App Transport Security) 예외 없음 — HTTPS 전용

### High
- [ ] Certificate Pinning 적용 (URLSession delegate)
- [ ] 탈옥 탐지 (선택, 금융 앱 수준 필요 시)
- [ ] 바이오메트릭 인증 시 LocalAuthentication 정확히 사용

### Medium
- [ ] 스크린 캡처 방지 (민감 화면)
- [ ] 디버그 빌드에서만 콘솔 로그 (Release에서 제거)
- [ ] Info.plist 권한 설명 정확히 기재

---

## Android (Jetpack Compose)

### Critical
- [ ] API 키가 소스코드에 하드코딩 없음 → BuildConfig 또는 encrypted SharedPreferences
- [ ] EncryptedSharedPreferences 사용 (일반 SharedPreferences로 토큰 저장 금지)
- [ ] WebView 사용 시 JavaScript Interface 보안 (@JavascriptInterface 최소화)

### High
- [ ] Network Security Config — cleartext 금지
- [ ] ProGuard/R8 난독화 (release 빌드)
- [ ] Root 탐지 (선택, 금융 앱 수준 필요 시)

### Medium
- [ ] 디버그 빌드에서만 Logcat (Release에서 제거 or Timber 사용)
- [ ] 백업 비활성화 (`android:allowBackup="false"`) 또는 암호화
- [ ] ContentProvider export 비활성화 (불필요 시)

---

## For AI Agents

워커 세션에서 이 체크리스트를 사용할 때:
1. 자기 플랫폼 섹션 + 공통 섹션을 확인
2. Critical 항목은 **코드 작성 시 즉시 적용**
3. High 항목은 **PR 전 확인**
4. Medium 항목은 **Gate 2 전 확인**
5. 체크리스트 항목 위반 발견 시 **즉시 수정** (다음 WO로 미루지 않음)
