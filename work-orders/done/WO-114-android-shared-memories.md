# WO-114: Shared Memories UI (v3.2) — Android

## 담당: android
## 스펙: api-contract.md § 5.23

## 작업
1. `MemoryShareApi` — Retrofit 3개
2. `MemoryShareRepository` + ShareViewModel 로직
3. 메모리 상세에 "공유" 버튼 추가
4. 공유 다이얼로그: 링크 복사 + 만료일
5. 테스트 최소 3개

## 금지
- 기존 Memory 관련 코드 구조 변경 금지
- 커밋 1건당 파일 10개 이하
