# WO-197: Server Data Export API (v5.8)

## 목표
사용자 전체 데이터를 JSON으로 내보내기 (GDPR data portability).

## 스펙 참조
`specs/api-contract.md` §5.48 Data Export (v5.8)

## 구현 범위
1. `DataExportController` — POST /api/account/export, GET /{exportId}, GET /{exportId}/download
2. `DataExportService` — 비동기 데이터 수집 + JSON 직렬화
3. `DataExport` Entity — exportId, userId, status(PROCESSING/COMPLETED/FAILED), filePath, requestedAt, completedAt, expiresAt
4. Flyway migration — data_exports 테이블
5. 단위 테스트

## 제약
- 커밋 1건당 파일 10개 이하
- 커밋 메시지: `[R2-server] feat: WO-197 Data Export API`
- 새 패키지 설치 금지
- 다운로드 파일 1시간 후 만료
- 동시 내보내기 1건 제한 (EXPORT_IN_PROGRESS)

## 완료 기준
- [x] 3개 엔드포인트 동작
- [x] 단위 테스트 통과
- [x] 빌드 성공

## 완료 보고
- 커밋: `[R2-server] feat: WO-197 Data Export API`
- 파일 9개: V50 migration, DataExport entity, repository, service, controller, DTOs, error codes, service test (6), controller test (6)
- 테스트: 1603 tests, 0 failures
