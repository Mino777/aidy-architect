# WO-210: Android Favorite People UI (v6.1)

## 목표
People 탭에서 즐겨찾기 토글 + 즐겨찾기 필터.

## 스펙 참조
`specs/api-contract.md` §5.51 Favorite People (v6.1)

## 구현 범위
1. AidyApiService에 favorite/unfavorite/getFavorites 추가
2. PeopleRepository에 즐겨찾기 로직
3. PeopleViewModel에 즐겨찾기 상태 + 필터
4. PeopleScreen에 즐겨찾기 별 아이콘 + 필터 탭
5. ViewModel 테스트

## 제약
- 커밋 메시지: `[R3-android] feat: WO-210 Favorite People UI`
- testDebugUnitTest 통과 필수
- 새 패키지 설치 금지

## 완료 기준
- [ ] 즐겨찾기 토글 + 필터 동작
- [ ] testDebugUnitTest 빌드 성공
