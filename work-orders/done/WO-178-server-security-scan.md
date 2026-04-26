# WO-178: Server 의존성 보안 스캔 설정

**담당**: server
**우선순위**: P2
**상태**: done

## 배경
의존성 취약점 스캔 도구가 없음. Spring Boot 3.5.0 + 다수 라이브러리 사용 중 보안 점검 자동화 필요.

## 구현 요구사항

### 1. OWASP Dependency-Check Gradle 플러그인 추가
```kotlin
// build.gradle.kts
plugins {
    id("org.owasp.dependencycheck") version "12.1.1"
}

dependencyCheck {
    failBuildOnCVSS = 7.0f  // HIGH 이상 빌드 실패
    formats = listOf("HTML", "JSON")
}
```

### 2. CI 워크플로에 보안 스캔 추가
- `.github/workflows/security-scan.yml` 생성
- 주 1회 스케줄 (매주 월요일 09:00 KST)
- PR 시에도 실행 (선택적)
- 결과 아티팩트 업로드

### 3. 현재 의존성 1회 스캔
- 스캔 실행하여 현재 취약점 확인
- HIGH/CRITICAL 발견 시 즉시 보고

## 완료 기준
- [ ] OWASP dependency-check 플러그인 추가
- [ ] `./gradlew dependencyCheckAnalyze` 실행 가능
- [ ] CI 워크플로 추가 (주 1회 스케줄)
- [ ] 첫 스캔 결과 보고 (취약점 유무)
