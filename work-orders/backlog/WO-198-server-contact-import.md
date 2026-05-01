# WO-198: Server Contact Import API (v5.9)

## 목표
전화번호부 연락처를 People로 일괄 등록.

## 스펙 참조
`specs/api-contract.md` §5.49 Contact Import (v5.9)

## 구현 범위
1. `ContactImportController` — POST /api/people/import, GET /api/people/import/preview
2. `ContactImportService` — 중복 판정 (name/phone/email 일치), 일괄 생성
3. ContactImportRequest/Response DTO
4. 단위 테스트

## 제약
- 커밋 1건당 파일 10개 이하
- 커밋 메시지: `[R2-server] feat: WO-198 Contact Import API`
- 한 번에 최대 100명
- 기존 PersonService 재사용 (새 Service 최소화)

## 완료 기준
- [ ] POST import + GET preview 동작
- [ ] 중복 판정 정확 (name, phone, email)
- [ ] 단위 테스트 통과
- [ ] 빌드 성공
