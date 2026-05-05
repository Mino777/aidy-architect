# Service 시그니처 변경 시 테스트 대량 실패

## 증상
ChatService에 personaPrompt 파라미터 추가 후 기존 테스트 55건 일괄 실패.
mock 객체의 메서드 시그니처 불일치 + cascading failure.

## 해결 (before → after)
- Before: WO에 "ChatService 수정" 만 명시 → 워커가 구현 후 테스트 실행 시 대량 실패 발견 → 30분+ 디버깅
- After: 기존 테스트 파일을 하나씩 읽어서 mock 파라미터 추가, BDDMockito matcher 수정

## 근본 원인
핵심 Service의 메서드 시그니처 변경은 해당 Service를 mock하는 모든 테스트에 영향.
WO에 이 파급 범위를 명시하지 않아 워커가 사전 대비 없이 구현.

## 체크리스트 (재발 방지)
- [ ] WO에 "영향받는 테스트 클래스" 목록 사전 분석 포함
- [ ] 핵심 Service 시그니처 변경은 1단계: 기존 테스트 수정 커밋, 2단계: 신규 기능 커밋으로 분리 지시
- [ ] 파라미터 추가 시 기본값 활용 (Kotlin default parameter) → 기존 호출 코드 변경 최소화
