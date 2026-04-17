# Server 워커 요청
**시각**: 진행 중 (WO-012)
**유형**: 블로커 (결제/빌링 문제)
**내용**:
WO-012 워크플로 업그레이드 커밋 후 push 했으나, 두 워크플로(Test, Auto Merge) 모두 **GitHub Actions 빌링 문제로 실행 자체가 차단**됨.

에러 메시지 (양쪽 동일):
> The job was not started because recent account payments have failed or your spending limit needs to be increased. Please check the 'Billing & plans' section in your settings

관련 run:
- Test: https://github.com/Mino777/aidy-server/actions/runs/24519493344
- Auto Merge: https://github.com/Mino777/aidy-server/actions/runs/24519493328

빌링 문제라 job 이 시작조차 안 됨(3초 내 FAIL). Node.js 24 호환 여부와는 무관 — 코드는 그대로 병합된 시점에 동일한 이유로 계속 실패할 것.

**현재상태**:
- 브랜치 `wo-012-actions-node24` 에 커밋 `e5e4a6d` push 완료
- 변경 내역: 8개 액션 버전 bump (checkout v4→v6, setup-java v4→v5, github-script v7→v8, cache v4→v5, upload-artifact v4→v7)
- WO 검증 기준 "각 워크플로 1회 이상 green run" 을 **빌링 이슈로 확인 불가**
- Gate 2 에서 green run URL 을 제시해야 하는데 막힘

**요청**:
1. GitHub 계정의 Billing & plans 섹션에서 결제 문제 해결 후 재실행 권한 주기
2. 또는 — workflow 실행 검증을 생략하고 코드 수정만으로 Gate 1 PASS 처리 가능한지 결정
3. 해결되면 `wo-012-actions-node24` 브랜치에서 workflow 재실행 트리거 (빈 커밋 push 또는 GitHub UI 재실행)

**참고**: 코드 변경 자체는 액션 각 release note 검증 완료. 모든 target 버전이 `runs.using: node24` 사용 확인 (action.yml 직접 조회). 빌링만 풀리면 green run 가능할 가능성이 높음.
