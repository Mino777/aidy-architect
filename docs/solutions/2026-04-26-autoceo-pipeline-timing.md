# autoceo 파이프라인 타이밍 최적화

## 증상
- watch-workers 20분 타임아웃이 클라 병렬 dispatch 시 부족 (iOS/Android 17분+)
- 서버 워커가 다수 WO를 1커밋에 묶어 리뷰 원자성 저하

## 해결 (before → after)
1. watch-workers 타임아웃: 1200초 → 1800초 (30분)
2. dispatch 프롬프트에 "1WO = 1커밋" 명시적 추가

## 근본 원인
- 클라이언트 워커는 TMA/TCA(iOS), Compose(Android) 구조상 서버보다 코드량 2배 → 시간 더 걸림
- 서버 워커는 효율 추구로 관련 WO를 묶어 커밋 (명시적 제약 없으면 자체 판단)

## 체크리스트 (재발 방지)
- [ ] architect-cli.sh의 watch-workers 기본 타임아웃 1800으로 변경
- [ ] dispatch 프롬프트 템플릿에 "각 WO별 1커밋" 규칙 추가
- [ ] 클라 병렬 dispatch 시 최소 25분 여유 확보
