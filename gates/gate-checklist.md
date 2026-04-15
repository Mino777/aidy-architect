# 검증 게이트 체크리스트

## Gate 1: 스펙 준수 (워커 PR 직후)

설계자가 워커의 구현을 검증. 하나라도 실패 시 PR 반려.

### API 준수
- [ ] 엔드포인트 URL이 api-contract.md와 정확히 일치
- [ ] HTTP method 일치 (GET/POST/PUT/DELETE)
- [ ] Request body 스키마 일치 (필드명, 타입)
- [ ] Response body 스키마 일치 (필드명, 타입)
- [ ] Error code가 스펙 Error Codes 표와 일치
- [ ] HTTP status code 일치

### 컨벤션 준수
- [ ] conventions.md 네이밍 규칙 준수
- [ ] Git 브랜치명: `feature/wo-{번호}-{desc}`
- [ ] 커밋 메시지 한글

### 보안
- [ ] 환경변수에 default 값 없음 (ai-study security sprint 교훈)
- [ ] 에러 메시지에 내부 정보 노출 없음
- [ ] API 키가 코드에 하드코딩 없음

## Gate 2: 통합 검증 (머지 직전)

Gate 1 통과 후, 다른 워커 프로젝트와의 호환성 검증.

### 빌드 & 테스트
- [ ] 빌드 통과
- [ ] 테스트 전체 통과
- [ ] 다른 워커의 최신 main과 충돌 없음

### 통합 테스트
- [ ] 서버 기동 + 클라이언트 연동 동작 확인
- [ ] Request/Response가 양쪽에서 동일하게 파싱

### 문서
- [ ] CLAUDE.md 변경사항 반영
- [ ] Work order 완료 보고 작성

## 판정

| 결과 | 조건 |
|------|------|
| **PASS** | 모든 체크 통과 |
| **CONDITIONAL** | 사소한 이슈 1-2건, 다음 WO에서 수정 |
| **FAIL** | 스펙 불일치 또는 빌드/테스트 실패 → 재작업 |
