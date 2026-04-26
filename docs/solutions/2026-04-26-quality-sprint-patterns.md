# 3프로젝트 동시 품질 스프린트 패턴

## 증상
175개 WO 완료 후 기능만 쌓이고 품질 부채 누적. Repository 테스트 7%, force unwrap 250+, ProGuard 규칙 없음 등.

## 해결 (before → after)
1. Explore subagent 3개 병렬로 Server/iOS/Android 동시 점검 (haiku 모델)
2. 이슈를 P1/P2 분류 → 워커당 3WO씩 총 9WO 일괄 발행
3. 3워커 동시 디스패치 → 병렬 실행 → ~1시간 완료

## 근본 원인
- 기능 스프린트(autoceo)가 품질 게이트 없이 반복 → 부채 누적
- 리팩터링/품질 WO가 백로그에 우선순위 밀림

## 체크리스트 (재발 방지)
- [ ] 10 WO 단위마다 품질 점검 스프린트 1회 삽입
- [ ] autoceo 5라운드마다 품질 체크 자동 트리거 검토
- [ ] 새 Repository/Service 추가 시 테스트 파일 동시 생성 (WO 완료기준에 포함)
- [ ] iOS 새 Feature 모듈 추가 시 Interface 의존성만 허용 (TMA 규칙 Gate-1 자동 검증)
- [ ] Android 새 ViewModel 추가 시 UiState data class 패턴 필수
