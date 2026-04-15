# /ingest → WO → Gate 풀 사이클 파이프라인

## 증상
외부 지식(ai-study wiki)을 Aidy에 적용하는 과정이 비체계적. 어떤 패턴을 적용하고, 어떤 것을 보류할지 기준이 없었음.

## 해결 (before → after)

**Before**: 위키를 읽고 "이거 좋아 보인다" → 즉흥 적용 → 추적 불가

**After**: 5-Phase 파이프라인
```
/ingest (12 패턴 발견)
  → 교차 검증 (검증 11건, 미검증 1건)
  → 즉시 적용 4건 (.claudeignore, CLAUDE.md, compound-principles, CHANGELOG)
  → WO 발행 2건 (WO-004, WO-005)
  → ADR 작성 1건 (ADR-004)
  → /dispatch WO-004 → 워커 구현 6분
  → /gate-1 CONDITIONAL → 스펙 수정 → /gate-2 PASS
  → /compound 박제
```

## 근본 원인
/ingest 커맨드가 Phase 1-5로 구조화되어 있어서:
- 교차 검증(최소 2소스)으로 날조 방지
- 4 카테고리 분류로 적용 대상 명확
- 즉시/다음WO/ADR 3단 분류로 우선순위 자동 결정

## 체크리스트 (재발 방지)
- [ ] /ingest 실행 시 항상 교차 검증 포함 (단일 소스 적용 금지)
- [ ] 즉시 적용 항목은 CHANGELOG에 기록
- [ ] 다음 WO 항목은 BACKLOG에 등록
- [ ] ADR 필요한 결정은 즉시 작성 (미루면 맥락 유실)
