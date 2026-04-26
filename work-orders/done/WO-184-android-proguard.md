# WO-184: Android ProGuard/R8 규칙 추가

**담당**: android
**우선순위**: P2
**상태**: done

## 배경
ProGuard/R8 규칙 파일이 기본 설정만 사용 중. 릴리스 빌드 시 난독화/최적화에서 크래시 위험.

## 구현 요구사항

### 1. proguard-rules.pro 작성
```proguard
# Retrofit + OkHttp
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.aidy.android.data.model.** { *; }
-keep class com.aidy.android.data.dto.** { *; }

# Kotlin Serialization
-keepclassmembers class kotlinx.serialization.** { *; }

# Compose
-keep class androidx.compose.** { *; }

# Biometric / Crypto
-keep class androidx.security.crypto.** { *; }
```

### 2. 릴리스 빌드 검증
- `./gradlew assembleRelease` 성공 확인
- R8 매핑 파일 생성 확인

### 3. 빌드 검증
- `./gradlew testDebugUnitTest` 통과 필수

## 완료 기준
- [ ] proguard-rules.pro 작성 (Data 모델, 네트워크, Compose 보존)
- [ ] `./gradlew assembleRelease` 성공
- [ ] `./gradlew testDebugUnitTest` 통과
- [ ] R8 매핑 파일 생성 확인
