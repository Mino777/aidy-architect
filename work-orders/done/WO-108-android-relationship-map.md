# WO-108: Relationship Map UI (v3.0) — Android

## 담당: android
## 스펙: api-contract.md § 5.21

## 작업
1. `RelationshipMapApi` — Retrofit 3개 엔드포인트
2. `RelationshipMapRepository` + `RelationshipMapViewModel`
3. `RelationshipMapScreen` (Compose)
   - Canvas로 그래프 렌더링 (노드 + 엣지)
   - healthScore 색상, strength 선 굵기
   - 노드 탭 → 인물 상세
4. Link 생성 다이얼로그
5. 테스트: ViewModel 최소 3개

## 금지
- 새 외부 패키지 추가 금지
- 커밋 1건당 파일 10개 이하
