# WO-206: Server Favorite People API (v6.1)

## 목표
인물 즐겨찾기 토글 + 즐겨찾기 목록 조회.

## 스펙 참조
`specs/api-contract.md` §5.51 Favorite People (v6.1)

## 구현 범위
1. Person 엔티티에 `favorited: Boolean`, `favoritedAt: Instant?` 필드 추가
2. Flyway migration — persons 테이블에 favorited/favoritedAt 컬럼 추가
3. `PersonController`에 POST /{personId}/favorite, GET /favorites, DELETE /{personId}/favorite 추가
4. `PersonService`에 즐겨찾기 토글/목록/해제 로직
5. 단위 테스트

## 제약
- 커밋 메시지: `[R2-server] feat: WO-206 Favorite People API`
- 커밋 1건당 파일 10개 이하
- 새 패키지 설치 금지

## 완료 기준
- [ ] 3개 엔드포인트 동작
- [ ] 단위 테스트 통과
- [ ] 빌드 성공
