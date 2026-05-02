# WO-208: iOS Favorite People UI (v6.1)

## 목표
People 탭에서 즐겨찾기 토글 + 즐겨찾기 필터 탭.

## 스펙 참조
`specs/api-contract.md` §5.51 Favorite People (v6.1)

## 구현 범위
1. APIClient에 favorite/unfavorite/getFavorites 추가
2. PeopleFeature에 즐겨찾기 토글 액션 + 필터 상태
3. PeopleView에 즐겨찾기 별 아이콘 + "즐겨찾기" 탭/필터
4. PersonDetailView에 즐겨찾기 토글 버튼

## 제약
- 커밋 메시지: `[R3-ios] feat: WO-208 Favorite People UI`
- tuist build 통과 필수 (xcodebuild test 금지)
- DerivedData 전체 삭제 금지 — build.db만 삭제 후 증분 빌드
- 새 패키지 설치 금지

## 완료 기준
- [ ] 즐겨찾기 토글 + 필터 동작
- [ ] tuist build 성공
