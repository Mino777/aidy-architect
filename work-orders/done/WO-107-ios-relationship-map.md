# WO-107: Relationship Map UI (v3.0) — iOS

## 담당: ios
## 스펙: api-contract.md § 5.21

## 작업
1. `RelationshipMapClient` — API 3개 엔드포인트
2. `RelationshipMapFeature` (TCA Reducer)
   - State: nodes, edges, selectedNode, isLoading
   - Action: fetchMap, createLink, deleteLink, selectNode
3. `RelationshipMapView` — 그래프 시각화
   - 노드: 인물 이름 + healthScore 색상 (빨강~초록)
   - 엣지: strength에 따른 선 굵기
   - 노드 탭 → 인물 상세로 이동
   - 간단한 원형 배치 (ForceGraph 라이브러리 금지 — 커스텀 Canvas/Path)
4. Link 생성 시트: 두 인물 선택 + 관계 설명 입력
5. 테스트: Reducer 최소 3개

## 금지
- 새 외부 패키지 추가 금지
- 커밋 1건당 파일 10개 이하
