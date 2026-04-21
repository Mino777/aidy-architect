# WO-150: Memory Media Attachments UI (v4.5)

**담당**: ios
**우선순위**: P2
**상태**: backlog

## 구현 요구사항

### 1. API 클라이언트
- MemoryMediaAPI: upload (multipart), list, delete
- MemoryMedia 모델 (§5.36 스키마)

### 2. Feature (TCA)
- 기존 MemoryDetailFeature에 미디어 섹션 추가
- 이미지 피커 (PHPickerViewController)
- 업로드 진행률 표시
- 이미지 풀스크린 뷰어

### 3. UI (DESIGN.md 준수)
- 메모리 상세 하단: 이미지 썸네일 그리드 (최대 3장)
- "+" 버튼: 이미지 추가 (3장 미만일 때)
- 롱프레스 → 삭제 확인 다이얼로그
- 업로드 중: 프로그레스 오버레이

## 완료 기준
- [ ] 빌드 PASS + 테스트 숫자 보고
- [ ] 이미지 선택 → 업로드 → 썸네일 표시
- [ ] 3장 제한 UI 처리
