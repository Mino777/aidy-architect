# WO-176: Server Repository 테스트 보강

**담당**: server
**우선순위**: P1
**상태**: done

## 배경
43개 Repository 중 3개만 테스트 존재 (7%). DB 레이어 검증 부재로 마이그레이션/쿼리 오류 감지 불가.

## 구현 요구사항

### 1. Repository 테스트 추가
- 기존 테스트 없는 40개 Repository에 대해 주요 CRUD 테스트 작성
- `@DataJpaTest` + H2 인메모리 DB 사용
- 최소 커버: save, findById, findAll(페이지네이션), delete
- 커스텀 쿼리 메서드가 있는 Repository는 해당 쿼리도 검증

### 2. 우선순위 (상위 10개 먼저)
- MemoryRepository, ChatMessageRepository, PersonRepository
- AnniversaryRepository, NudgeRepository, InteractionRepository
- MoodRepository, FrequencyGoalRepository, MilestoneRepository
- TagRepository

### 3. 테스트 패턴
```kotlin
@DataJpaTest
class XxxRepositoryTest {
    @Autowired lateinit var repo: XxxRepository
    @Autowired lateinit var userRepo: UserRepository
    
    @Test fun `save and findById`() { ... }
    @Test fun `findByUser returns only user data`() { ... }
    @Test fun `custom query returns expected results`() { ... }
}
```

## 완료 기준
- [ ] 상위 10개 Repository 테스트 작성
- [ ] 나머지 30개 중 최소 20개 추가
- [ ] 전체 테스트 green (기존 + 신규)
- [ ] 최종 테스트 숫자 보고
