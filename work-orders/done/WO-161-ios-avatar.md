# WO-161: User Avatar UI (iOS)

**담당**: ios
**우선순위**: P4
**상태**: done
**스펙**: api-contract.md §5.37

## 구현 요구사항

### 1. Avatar API Client
- AvatarClient: upload/get/delete/serve
- TCA Dependency 등록

### 2. 프로필 화면 확장
- 설정/프로필 영역에 아바타 표시 (원형, 120px)
- 아바타 없으면 이니셜 표시 (기존 패턴)
- 탭하면 PhotosPicker로 이미지 선택
- 삭제 옵션 (long press 또는 편집 버튼)

### 3. 아바타 표시 통합
- 채팅 화면: 유저 메시지 옆에 작은 아바타 (32px)
- 로그인 응답의 avatarUrl 활용 (AuthFeature state에 추가)

### 4. 테스트
- AvatarFeatureTests: upload/delete/display

## 완료 기준
- [ ] 프로필에 아바타 업로드/표시/삭제
- [ ] 채팅에 아바타 표시
- [ ] 빌드 PASS
