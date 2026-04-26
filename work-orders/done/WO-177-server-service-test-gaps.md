# WO-177: Server Service 테스트 갭 해소

**담당**: server
**우선순위**: P1
**상태**: done

## 배경
51개 Service 중 8개 미테스트 (84% 커버). 누락된 서비스 테스트 보강.

## 구현 요구사항

### 1. 미테스트 Service 식별 및 테스트 작성
- 기존 테스트가 없는 8개 Service 식별
- 각 Service의 public 메서드에 대해 최소 happy path + error path 테스트
- Mockito/MockK 활용하여 의존성 모킹

### 2. 테스트 패턴
```kotlin
@ExtendWith(MockKExtension::class)
class XxxServiceTest {
    @MockK lateinit var repo: XxxRepository
    @InjectMockKs lateinit var service: XxxService
    
    @Test fun `method - happy path`() { ... }
    @Test fun `method - not found throws ApiException`() { ... }
}
```

### 3. 기존 테스트 보강
- 기존 43개 Service 테스트 중 edge case 누락 확인
- AI 관련 서비스: circuit breaker 상태별 테스트 확인

## 완료 기준
- [ ] 8개 미테스트 Service 전부 테스트 작성
- [ ] 각 Service 최소 3개 이상 테스트 케이스
- [ ] 전체 테스트 green
- [ ] 최종 테스트 숫자 보고
