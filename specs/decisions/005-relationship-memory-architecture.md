# ADR-005: 관계 메모리 아키텍처

**상태**: 승인
**일시**: 2026-04-16
**결정자**: Architect (Jo)

## 컨텍스트

Aidy V1의 킬러 피처로 "관계 메모리"를 선택. 대화에서 사람/관계/맥락을 자동 추출하여 구조화된 DB에 저장. ChatGPT 메모리와의 차별화: 구조화 DB(정량 쿼리), 자체 인프라(프라이버시), 전용 UI(피플카드).

## 결정

### 데이터 모델: B+C 합성
- **B (전용 피플 엔드포인트):** GET /api/memories/people + 피플 카드 UI
- **C (별도 Person 엔티티):** persons, person_memories, memory_feedback 테이블 분리

### 핵심 기술 결정
1. **Person upsert:** UNIQUE(userId, normalizedName) + INSERT ON CONFLICT UPDATE
2. **userId 비정규화:** person_memories에 userId 중복 저장 (JOIN 없이 조회)
3. **인물 동일성:** V1은 LLM normalizedName 의존. V1.5에서 수동 merge UI
4. **만남 브리핑:** 비동기 처리 (채팅 응답 레이턴시 무영향)
5. **피드백 "틀려":** memory_feedback 저장 + PersonMemory 삭제 + 확인 다이얼로그
6. **프라이버시:** V1 서버 저장 (자체 인프라). E2E 암호화는 V2+
7. **DB 에러:** 서버 retry queue (3회 재시도)

### Phase 분리
- **Phase 1 (Core):** 인물 추출 + DB + 피플카드 + 확인카드 + 피드백 + 아바타
- **Phase 2 (Delight):** 그룹 + 브리핑 + 타임라인 + 감쇠알림

### 디자인 시스템
- Organic/Natural 방향, 딥 그린 #2D7D46 액센트
- Pretendard 폰트, 따뜻한 베이지 #FAFAF7 배경
- 바텀시트 확인카드, 리스트행 피플목록

## 대안 검토
- **A (프롬프트만 강화):** 전용 UI 없어서 차별화 부족 → 기각
- **C (지식 그래프만):** 데이터 없이 과도한 복잡도 → 데이터 모델만 채택

## 근거
- Outside Voice 2회 실행: Phase 1/2 분리, partial extraction 처리, retry queue 필요성 확인
- Cross-project learning: profile-likes-fk-asymmetry → userId 비정규화로 선제 대응
- 디자인 리뷰 7 패스: 3/10 → 7/10 (정보계층, 상태커버리지, 감정아크 추가)

## 리스크
- **CRITICAL:** normalizedName 분산 (같은 사람이 여러 레코드로 쪼개짐)
- 완화: V1.5 수동 merge + 피드백 데이터로 프롬프트 개선
