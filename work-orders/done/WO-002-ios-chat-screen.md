# WO-002: iOS 채팅 화면 + 서버 연동

**담당**: ios
**우선순위**: P0-긴급
**상태**: done
**의존**: WO-001 완료 후 (서버 API 필요)

## 목표
Aidy iOS 앱에서 채팅 탭이 동작하여, 서버와 통신하고 AI 비서와 대화할 수 있게 한다.

## 스펙 참조
- `specs/api-contract.md` § 2. Chat
- `specs/conventions.md` § iOS

## 구현 요구사항
1. `tuist generate` 로 Xcode 프로젝트 생성 (Xcode 설치 전제)
2. ChatFeature (TCA Reducer) — sendTapped → API 호출 → 응답 표시
3. ChatView — 채팅 버블 UI, 입력 필드, 전송 버튼
4. APIClient — `POST /api/chat`, `GET /api/chat/history` 구현
5. Error handling — 네트워크 오류 시 사용자 친화적 메시지
6. 로딩 상태 표시 (isLoading)

## 테스트 요구사항
- [ ] ChatFeature TestStore 테스트 (mock API)
- [ ] 메시지 전송 → 로딩 → 응답 표시 플로우
- [ ] 에러 발생 시 에러 메시지 표시

## 검증 기준
- [ ] `tuist build` 통과
- [ ] `tuist test` 통과
- [ ] 시뮬레이터에서 채팅 동작 확인 (서버 연동)
- [ ] API response 파싱이 api-contract.md와 일치

## 워커 세션 시작 명령
```
이 세션의 역할: aidy-ios iOS 워커
프로젝트: ~/Develop/aidy-ios

시작 전 반드시 읽기:
1. ~/Develop/aidy-ios/CLAUDE.md
2. ~/Develop/aidy-architect/specs/api-contract.md
3. ~/Develop/aidy-architect/specs/conventions.md
4. 이 work-order (WO-002)

작업 완료 후:
- git commit + push
- 이 파일의 "완료 보고" 섹션 작성
```

## 완료 보고
- PR:
- 소요 시간:
- 특이사항:
