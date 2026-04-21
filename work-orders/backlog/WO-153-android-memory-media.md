# WO-153: Memory Media Attachments UI (v4.5)

**담당**: android
**우선순위**: P2
**상태**: backlog

## 구현 요구사항

### 1. API 클라이언트
- MemoryMediaApi: upload (multipart), list, delete
- MemoryMedia 모델 (§5.36 스키마)

### 2. ViewModel
- 기존 MemoryDetailViewModel에 미디어 관리 추가
- 업로드 상태: Idle / Uploading(progress) / Done / Error

### 3. UI (Jetpack Compose, DESIGN.md 준수)
- 메모리 상세 하단: 이미지 썸네일 Row (최대 3장)
- "+" 버튼: 이미지 추가 (ActivityResultContracts.PickVisualMedia)
- 롱프레스 → 삭제 확인 AlertDialog
- 업로드 중: CircularProgressIndicator 오버레이

## 완료 기준
- [ ] 빌드 PASS + 테스트 숫자 보고
- [ ] 이미지 선택 → 업로드 → 썸네일 표시
- [ ] 3장 제한 UI 처리
