# WO-182: Android 보안 라이브러리 안정 버전 전환

**담당**: android
**우선순위**: P2
**상태**: done

## 배경
crypto-1.1.0-alpha06, biometric-1.2.0-alpha05 알파 버전 사용 중. 보안 관련 라이브러리에서 알파 버전은 API 변경/버그 위험.

## 구현 요구사항

### 1. 안정 버전 전환
- `androidx.security:security-crypto` → 최신 안정 버전 확인 후 전환
  - 안정 버전이 없으면 `1.1.0-alpha06` 유지하되 사유 코멘트 추가
- `androidx.biometric:biometric` → 최신 안정 버전 확인 후 전환
  - 안정 버전이 없으면 유지하되 사유 코멘트 추가

### 2. API 호환성 확인
- 버전 전환 후 deprecated API 사용 여부 확인
- 컴파일 에러 발생 시 API 마이그레이션

### 3. 빌드 검증
- `./gradlew testDebugUnitTest` 통과 필수

## 완료 기준
- [ ] crypto/biometric 라이브러리 최신 안정 버전으로 전환 (또는 불가 사유 보고)
- [ ] `./gradlew testDebugUnitTest` 통과
- [ ] 변경 전후 버전 보고
