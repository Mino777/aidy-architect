# WO-020: Server 테스트 커버리지 갭 해소

**담당**: server
**우선순위**: P2-보통 (품질 강화)
**상태**: in-progress
**의존**: 없음

## 목표
ChatService 단위 테스트 + 핵심 Repository 통합 테스트를 추가하여 테스트 갭을 해소한다.

## 구현 요구사항

### 1. ChatService 단위 테스트 (`ChatServiceTest.kt`)
- `chat()` — 메시지 저장 + AI 호출 + 메모리 추출 + 응답 반환 전체 플로우
- `chat()` — 빈 히스토리에서 첫 메시지
- `chat()` — AI 호출 실패 시 예외 전파
- `chatStream()` — 콜백 호출 순서 (onToken → onDone)
- `getHistory()` — since 파라미터 유무에 따른 분기
- `getHistory()` — 최근 20건 제한 확인

### 2. Repository 통합 테스트 (핵심 3개)
기존 @DataJpaTest 또는 @SpringBootTest 스타일 따르기.

**ChatMessageRepositoryTest.kt:**
- findByUserIdOrderByCreatedAtDesc — 정렬 순서
- findByUserIdAndCreatedAtAfter — since 필터

**MemoryRepositoryTest.kt:**
- findByUserIdAndCategory — 카테고리 필터
- countByUserId — 카운트
- 페이지네이션 (offset/limit)

**PersonMemoryRepositoryTest.kt:**
- findByUserIdAndNormalizedName — exact match
- 중복 방지 (UNIQUE constraint)

### 3. ErrorLogService 독립 테스트 (`ErrorLogServiceTest.kt`)
- 로그 기록
- 최근 N건 조회
- 초기화

## 검증 기준
- [ ] ChatServiceTest 6건 이상
- [ ] Repository 테스트 3개 파일, 각 2건 이상
- [ ] ErrorLogServiceTest 3건 이상
- [ ] 기존 207 tests 통과 유지
- [ ] 새 테스트 포함 총 테스트 수 보고
