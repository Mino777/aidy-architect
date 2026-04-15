# WO-003: Android 채팅 화면 + 서버 연동

**담당**: android
**우선순위**: P0-긴급
**상태**: backlog
**의존**: WO-001 완료 후 (서버 API 필요)

## 목표
Aidy Android 앱에서 채팅 탭이 동작하여, 서버와 통신하고 AI 비서와 대화할 수 있게 한다.

## 스펙 참조
- `specs/api-contract.md` § 2. Chat
- `specs/conventions.md` § Android

## 구현 요구사항
1. Android Studio에서 프로젝트 빌드 확인
2. ChatViewModel — 메시지 전송 → API 호출 → 응답 표시
3. ChatScreen (Compose) — 채팅 버블 UI, 입력 필드, 전송 버튼
4. AidyApiService — `POST /api/chat`, `GET /api/chat/history` Retrofit 구현
5. Error handling — 네트워크 오류 시 사용자 친화적 메시지
6. 로딩 상태 표시

## 테스트 요구사항
- [ ] ChatViewModel 단위 테스트 (mock API)
- [ ] 메시지 전송 플로우 테스트

## 검증 기준
- [ ] `./gradlew build` 통과
- [ ] `./gradlew test` 통과
- [ ] 에뮬레이터에서 채팅 동작 확인 (서버 연동)
- [ ] API response 파싱이 api-contract.md와 일치

## 워커 세션 시작 명령
```
이 세션의 역할: aidy-android Android 워커
프로젝트: ~/Develop/aidy-android

시작 전 반드시 읽기:
1. ~/Develop/aidy-android/CLAUDE.md
2. ~/Develop/aidy-architect/specs/api-contract.md
3. ~/Develop/aidy-architect/specs/conventions.md
4. 이 work-order (WO-003)

작업 완료 후:
- git commit + push
- 이 파일의 "완료 보고" 섹션 작성
```

## 완료 보고
- PR:
- 소요 시간:
- 특이사항:
