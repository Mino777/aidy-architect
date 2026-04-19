# WO-087: Android — Anniversary Reminders UI (v2.3)

**담당**: android
**스펙**: `specs/api-contract.md` § 5.14 Anniversary Reminders (v2.3)
**선행**: WO-085 (서버 API)

## 구현 범위

### 화면
1. **AnniversaryListScreen** — 다가오는 기념일 카드 리스트
   - daysUntil에 따라 긴급도 색상 (7일 이내 빨강, 30일 이내 주황)
   - type별 아이콘 (birthday: 케이크, anniversary: 하트, custom: 별)
2. **AnniversaryFormScreen** — 기념일 등록/수정 폼
   - personId 선택 (People 목록에서)
   - date picker (MM-dd)
   - type 선택
3. **AnniversaryDetectScreen** — AI 감지 결과 화면
   - 후보 리스트 + confidence 표시
   - 체크박스로 선택 → 일괄 등록

### 데이터
1. **AnniversaryApi** — Retrofit 인터페이스
2. **AnniversaryRepository**
3. **AnniversaryViewModel** — 상태 관리
4. 탭에 기념일 배지 (7일 이내 기념일 수)

### 커밋 규칙
- 메시지: `[R4-android] feat: Anniversary Reminders UI (v2.3)`
- 파일 10개 이하/커밋
