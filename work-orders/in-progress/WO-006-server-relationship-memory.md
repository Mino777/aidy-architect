# WO-006: 서버 관계 메모리 Phase 1

**담당**: server
**우선순위**: P1
**상태**: in-progress
**의존**: WO-004 완료 (AI 안정성), API Contract v0.2.0
**참조**: ADR-005, DESIGN.md

## 목표
대화에서 인물/관계 정보를 자동 추출하여 구조화된 DB에 저장. 인물별 기억 조회 API 제공.

## 스펙 참조
- `specs/api-contract.md` § 4. People
- `specs/decisions/005-relationship-memory-architecture.md`

## DB 스키마 (3개 새 테이블)

### persons
| 컬럼 | 타입 | 제약 |
|------|------|------|
| id | BIGINT | PK, AUTO |
| user_id | BIGINT | NOT NULL |
| normalized_name | VARCHAR(100) | NOT NULL |
| display_name | VARCHAR(100) | |
| relationship | VARCHAR(50) | |
| created_at | TIMESTAMP | |
| updated_at | TIMESTAMP | |
| **UNIQUE** | (user_id, normalized_name) | |

### person_memories
| 컬럼 | 타입 | 제약 |
|------|------|------|
| id | BIGINT | PK, AUTO |
| person_id | BIGINT | FK → persons |
| memory_id | BIGINT | FK → memories |
| user_id | BIGINT | NOT NULL (비정규화) |
| trait | VARCHAR(200) | |
| context | TEXT | |
| sentiment | VARCHAR(20) | nullable |
| created_at | TIMESTAMP | |

### memory_feedback
| 컬럼 | 타입 | 제약 |
|------|------|------|
| id | BIGINT | PK, AUTO |
| memory_id | BIGINT | FK → memories |
| is_correct | BOOLEAN | NOT NULL |
| created_at | TIMESTAMP | |

## 구현 요구사항

### 1. DB 마이그레이션
- Flyway 마이그레이션 3개 (persons, person_memories, memory_feedback)
- 인덱스: (user_id, normalized_name) UNIQUE on persons, (user_id, person_id) on person_memories

### 2. LLM 추출 프롬프트 강화
- 기존 채팅 응답 생성 LLM 호출에 인물 추출 지시 추가
- 추출 스키마: `{ normalizedName, relationship, trait, context, sentiment }`
- normalizedName 규칙: 공백 제거, 가장 완전한 형태 (예: "김 팀장" → "김팀장")
- Partial extraction 처리: 이름만 있고 trait 없으면 Person만 upsert, PersonMemory 생성 안 함

### 3. Person Upsert
- INSERT ON CONFLICT (user_id, normalized_name) DO UPDATE
- display_name, relationship은 최신 값으로 업데이트

### 4. API 엔드포인트
- `GET /api/memories/people?person={normalizedName}` — API Contract § 4 참조
- `POST /api/memories/{id}/feedback` — 피드백 저장, isCorrect=false 시 PersonMemory 삭제

### 5. 에러 처리
- 추출 실패 → 스킵 (채팅 정상 진행)
- DB 에러 → 서버 retry queue (3회 재시도)
- Person upsert race condition → ON CONFLICT로 자동 해결

## 테스트 요구사항
- [ ] Person upsert 테스트 (동일 normalizedName 중복 시 UPDATE)
- [ ] PersonMemory 생성 테스트
- [ ] GET /memories/people 정상 조회
- [ ] GET /memories/people 404 (인물 없음)
- [ ] POST /memories/{id}/feedback isCorrect=true
- [ ] POST /memories/{id}/feedback isCorrect=false → 삭제 확인
- [ ] LLM 추출 실패 시 채팅 정상 진행

## 검증 기준
- [ ] `./gradlew build` 통과
- [ ] `./gradlew test` 통과
- [ ] POST /chat → personDetail 포함 확인
- [ ] GET /memories/people 정상 동작
