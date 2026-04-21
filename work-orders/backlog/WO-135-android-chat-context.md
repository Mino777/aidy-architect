# WO-135: Chat Context Memory UI (v3.9) — Android

## 담당: android
## 스펙: api-contract.md § 5.30

## 작업
1. `ChatContext` 데이터 클래스 + `ChatContextApi` Retrofit
2. `ChatContextRepository` + ViewModel 통합
3. Compose UI
   - 채팅 화면 상단 맥락 요약 배너
   - "맥락 초기화" / "맥락 갱신" 버튼
4. 테스트 각 최소 3개

## 금지
- 기존 Chat 화면 변경 금지
- 커밋 1건당 파일 10개 이하
