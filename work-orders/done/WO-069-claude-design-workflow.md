# WO-069: Claude Design 워크플로 통합

**담당**: architect
**우선순위**: P2
**상태**: backlog

## 작업 내용

### 1. WO 템플릿에 목업 첨부 가이드 추가
- architect-cli.sh의 build_prompt()에 "목업 첨부 시 경로 포함" 안내 추가
- WO 템플릿에 `**목업**:` 필드 추가 (optional)

### 2. DESIGN.md 기반 Claude Design 시스템 세팅 가이드
- docs/guides/claude-design-setup.md 작성
- DESIGN.md + 코드베이스 → Claude Design 디자인 시스템 온보딩 절차

### 3. 핸드오프 번들 워크플로
- Claude Design → Export → 핸드오프 번들 → WO에 첨부
- 워커가 번들을 읽고 구현하는 절차 문서화

### 4. CLAUDE.md 업데이트 후보 (캐시 보존 원칙으로 메모리에만 기록)
- Claude Design 핸드오프 활용 가이드

## 완료 기준
- [ ] docs/guides/claude-design-setup.md 존재
- [ ] WO 템플릿에 목업 필드 추가
- [ ] 핸드오프 워크플로 문서화
