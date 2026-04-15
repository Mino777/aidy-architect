# Outside Voice로 스코프 리셰이핑

## 증상
CEO 리뷰에서 SCOPE EXPANSION 모드로 7개 확장안을 전부 수락함. 유저가 모든 확장에 "A) 추가"를 선택하면 검토 프로세스가 게이트 역할을 못 함.

## 해결 (before → after)
- before: 7개 확장 전부 V1 스코프에 포함
- after: Phase 1 (Core 3개: 확인카드, 피드백, 아바타) + Phase 2 (Delight 4개: 그룹, 브리핑, 타임라인, 감쇠알림) 분리

## 근본 원인
Outside Voice (독립 AI 서브에이전트)가 "7개 전부 수용 = 게이트가 작동 안 한 것"이라고 지적. 유저가 이 피드백을 받아들여 Phase 분리에 동의.

핵심: 리뷰어(Claude main)와 유저가 모두 동의한 스코프를 독립 AI가 도전하면, 리뷰어도 유저도 인지 못한 블라인드 스팟을 잡을 수 있다.

## 체크리스트 (재발 방지)
- [ ] SCOPE EXPANSION에서 5개 이상 확장이 전부 수락되면 자동으로 Phase 분리 제안
- [ ] Outside Voice를 CEO/Eng 리뷰에서 항상 실행 (스킵하지 않기)
- [ ] Phase 1 성공 기준을 명확히 정의한 후에만 Phase 2 착수
