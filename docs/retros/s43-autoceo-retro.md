# autoceo-s43 회고 — v8.4~v9.3 피처 웨이브 + 테스트 갭 해소

**일시**: 2026-05-08
**라운드**: 10 (실효 9 — R10=Compound)
**워커**: server + ios + android (3-way)

## 이번에 한 것
- 신규 피처 8개 3-way 구현 (v8.4~v8.7, v9.0~v9.3)
- 테스트 갭 해소: server PersonEmotionController + iOS 14 Feature 테스트
- flaky test 수정 (ChatController SSE stream 경합)
- 총 커밋 17건, WO 13개 완료
- 테스트 증가: server 1979→2034 (+55), android 1297→1830 (+533)

## 피처 목록
| 버전 | 피처 | 설명 |
|------|------|------|
| v8.4 | AI Conversation Insights | 대화 후 AI 자동 분석 인사이트 |
| v8.5 | Relationship Journal Prompts | 매일 AI 성찰 프롬프트 + 저널 |
| v8.6 | Contact Activity Summary | 인물별 활동 종합 요약 |
| v8.7 | Smart Auto-Grouping | AI 자동 인물 그룹핑 |
| v9.0 | Relationship Digest Preview | 주간 다이제스트 프리뷰 |
| v9.1 | AI Memory Questions | AI 능동적 메모리 질문 |
| v9.2 | People Notes | 인물별 자유형 메모 |
| v9.3 | Contact Streak Tracking | 연속 연락 추적 |

## 잘된 것
- 2-wave 구조 (R2~R6: v8.4~8.7, R7~R9: v9.0~9.3)로 깔끔하게 분할
- 서버 선행 → 클라 후행 패턴 안정적 (API 완성 후 클라 dispatch)
- 파이프라이닝 효과적: 서버 작업 중 Gate-1 축약 검증 동시 수행
- Android 테스트 +533건 — ViewModel 테스트 충실

## 아쉬운 것 (다음 사이클 입력)
- **tmux 멀티라인 dispatch 실패**: R2에서 서버에 멀티라인 프롬프트 전송 시 "Press up to edit queued messages" 상태에 빠짐. 3번 재시도 후 단일 라인으로 전환. → 처음부터 단일 라인 dispatch 사용해야 했음
- **폴링 과다**: 워커 대기 중 sleep+check 루프에 빠짐. 유저가 interrupt. → watch-workers 백그라운드 + 파이프라이닝만 하고 Claude는 능동 폴링 금지
- **iOS 빌드 시간 과소평가**: tuist build 5~7분 소요를 2~3분으로 추정. 대기 시간 판단 실패
- **커밋당 파일 제한 초과**: iOS/Android 일부 커밋이 14~15파일 (규칙: 10개 이하). 피처 2개를 한 커밋에 묶은 것이 원인

## 다음에 적용할 것
1. **dispatch는 항상 단일 라인** — 멀티라인은 tmux에서 큐잉 문제 발생
2. **폴링 금지 원칙 강화** — sleep+check 대신 워커 알림 대기만. 대기 중엔 Gate-1/스펙 작업만
3. **iOS 빌드 시간 7분 기준** — tuist build 대기 판단 시 5~7분 할당
4. **클라 피처 2개 이상 WO는 피처별 커밋 강제** — WO에 "피처당 커밋 분리" 명시

## 프로세스 개선 (이번 스프린트)
| 재료 | 개선 | 파일 |
|------|------|------|
| tmux 멀티라인 실패 | dispatch는 단일 라인 원칙 | 피드백 메모리 |
| 폴링 과다로 유저 interrupt | 능동 폴링 금지, 워커 알림 대기만 | 피드백 메모리 |
| flaky SSE test | Thread.sleep(100)으로 async 경합 방지 | docs/solutions/ |

## Compound Assets
- api-contract.md v8.4~v9.3 (8개 피처 스펙)
- Gate-2 리뷰: gates/reviews/gate2-s43.md
- WO-233~245 (13개 WO 템플릿)
- 서버 Controller 8개 + Service 8개 + Entity 8개 + Migration 4개
- iOS Client 8개 + Feature 8개 + View 12개
- Android ViewModel 8개 + Screen 8개 + Repository 8개 + Test 8개

## For AI Agents
다음 세션에서 이 회고를 입력으로 받을 때:
- dispatch는 **반드시 단일 라인**으로 전송 (tmux 멀티라인 큐잉 버그)
- 워커 대기 시 **sleep+check 금지** — 워커 tmux 알림만 신뢰
- iOS tuist build는 **최소 5분, 보통 7분** 소요 (대기 계획에 반영)
- 클라이언트 WO에서 피처 2개 이상 → **피처별 커밋 분리 규칙** 명시
- Android ViewModel 테스트가 매우 충실 — 이 패턴 유지
