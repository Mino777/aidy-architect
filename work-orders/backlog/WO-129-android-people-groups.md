# WO-129: People Groups UI (v3.7) — Android

## 담당: android
## 스펙: api-contract.md § 5.28

## 작업
1. `PersonGroup` 데이터 클래스 + `PersonGroupApi` Retrofit
2. `PersonGroupRepository` + `PersonGroupViewModel`
   - 그룹 CRUD
   - 그룹에 인물 추가/제거
   - AI 그룹 추천 수락/거부
3. Compose UI
   - 그룹 목록 (색상 태그 + 멤버 수)
   - 그룹 생성/편집 다이얼로그 (이름 + 색상)
   - 멤버 관리 (체크박스)
   - AI 추천 카드
4. People 화면 상단에 그룹 필터 칩 추가
5. 테스트 각 최소 3개

## 금지
- 기존 People 화면 변경 금지
- 커밋 1건당 파일 10개 이하
