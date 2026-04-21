# WO-147: Memory Media Attachments API (v4.5)

**담당**: server
**우선순위**: P2
**상태**: in-progress

## 구현 요구사항

### 1. Entity + Repository
- `MemoryMedia` 엔티티: id, memoryId, filename, thumbnailFilename, mimeType, size, createdAt
- 파일 저장: 로컬 디스크 `uploads/media/` (추후 S3 전환 가능하도록 인터페이스 분리)

### 2. Service
- `uploadMedia(memoryId, file)` — 파일 저장 + 썸네일 생성 + DB 기록
  - 허용: image/jpeg, image/png, image/webp
  - 최대 5MB, 메모리당 3개
  - 썸네일: 200x200 리사이즈 (java.awt.image 또는 thumbnailator)
- `getMediaList(memoryId)` — 미디어 목록
- `deleteMedia(mediaId)` — 파일 + DB 삭제
- `serveFile(filename)` — 바이너리 서빙 + 캐시 헤더

### 3. Controller (4 endpoints)
- `POST /api/memories/{memoryId}/media` — multipart/form-data, §5.36
- `GET /api/memories/{memoryId}/media` — §5.36
- `DELETE /api/memories/media/{mediaId}` — §5.36
- `GET /api/media/{filename}` — 이미지 직접 서빙

### 4. 기존 API 확장
- MemoryResponse에 `mediaCount` (정수) 필드 추가
- MemoryDetailResponse에 `media` 배열 추가

## 완료 기준
- [ ] 빌드 PASS + 테스트 숫자 보고
- [ ] multipart 업로드 동작 확인
- [ ] 에러: INVALID_MEDIA_TYPE, MEDIA_LIMIT_EXCEEDED, MEDIA_TOO_LARGE, MEDIA_NOT_FOUND
- [ ] 기존 Memory API에 mediaCount 필드 추가됨
