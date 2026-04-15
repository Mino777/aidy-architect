# WO-008: Android 피플 탭 Phase 1

**담당**: android
**우선순위**: P1
**상태**: done
**의존**: WO-006 완료 (서버 People API)
**참조**: ADR-005, DESIGN.md, API Contract § 4

## 목표
피플 탭에서 인물 목록을 보고, 인물별 기억 타임라인을 탐색하고, 기억 정확도 피드백을 줄 수 있게 한다.

## 구현 요구사항

### 1. 피플 목록 화면 (PeopleScreen + PeopleViewModel)
- 리스트 행 패턴 (카드 아님): 이니셜 아바타(40dp 원형) + 이름 + relationship + 최근 기억 snippet + 날짜
- 정렬: 최근 기억순
- 빈 화면: 일러스트 + "대화에서 사람을 언급하면 Aidy가 기억합니다" + 채팅 시작 CTA

### 2. 인물 상세 화면 (PersonDetailScreen + PersonDetailViewModel)
- 큰 아바타 + 이름 + relationship + 기억 수 + 첫 대화 날짜
- 기억 타임라인 (날짜별 그룹핑, LazyColumn)
- 각 기억에 피드백 버튼 (맞아 ✓ / 틀려 ✗)

### 3. 기억 확인 카드 (BottomSheet)
- 채팅 후 memoriesExtracted에 people 카테고리가 있으면 BottomSheet로 표시
- 인물 아바타 + 이름 + 추출된 trait
- 피드백 버튼

### 4. 피드백 API 연동
- POST /api/memories/{id}/feedback { isCorrect: true/false }
- isCorrect=false → AlertDialog "이 기억을 삭제할까요?" → 삭제

### 5. 이니셜 아바타
- 이름 첫 글자 기반
- 색상: normalizedName hashCode 기반 결정적 배정
- 색상 팔레트: #5B8A72, #4A7AB5, #8B6DAF, #C4754B, #B5544D

### 6. 디자인
- DESIGN.md 참조 (배경 #FAFAF7, 액센트 #2D7D46)
- 터치 타겟 48dp 이상

### 7. 네비게이션
- BottomNavigation에 People 탭 추가 (Chat, People, Settings)

## 검증 기준
- [ ] `./gradlew assembleDebug` 통과
- [ ] 피플 탭에서 인물 목록 표시
- [ ] 인물 상세 타임라인 동작
- [ ] 피드백 버튼 동작
