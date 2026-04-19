# Claude Design 시스템 온보딩 가이드

## 1. DESIGN.md 기반 디자인 시스템 세팅

Aidy의 디자인 시스템은 `DESIGN.md`에 정의되어 있다. Claude Design에서 새 프로젝트 시작 시:

### 디자인 토큰 입력
- **Aesthetic**: Organic/Natural
- **Primary Color**: Deep Green `#2D7D46`
- **Background**: Warm White `#FAFAF7`
- **Surface**: `#FFFFFF`
- **Typography**: Pretendard (한국어) + SF Pro (iOS) / Material (Android)
- **Corner Radius**: 12px (카드), 8px (버튼/입력)
- **Spacing**: 4px 배수 (8, 12, 16, 20, 24)

### 컴포넌트 참조
기존 코드베이스의 UI 패턴을 참조:
- iOS: `Projects/App/Sources/Feature/` 디렉토리
- Android: `app/src/main/java/com/mino/aidy/ui/` 디렉토리

## 2. 핸드오프 번들 워크플로

### 디자인 → 개발 핸드오프 프로세스
```
1. Claude Design에서 목업 생성
2. Export → 핸드오프 번들 (이미지 + 스펙)
3. 번들을 프로젝트에 저장: docs/mockups/<feature-name>/
4. WO에 목업 경로 첨부
5. 워커가 목업을 참조하여 구현
```

### WO 목업 첨부 예시
```markdown
**목업**: docs/mockups/weekly-summary/
- overview.png — 전체 화면 레이아웃
- components.png — 개별 컴포넌트 상세
- states.png — 로딩/에러/빈 상태
```

## 3. 디자인 리뷰 체크리스트

워커 구현 후 디자인 리뷰 시 확인:
- [ ] DESIGN.md 색상 팔레트 준수
- [ ] 타이포그래피 스케일 일치
- [ ] 코너 라디우스 12px/8px
- [ ] 스페이싱 4px 배수
- [ ] 다크모드 대응 (semantic colors 사용)
- [ ] 접근성 (contrast ratio 4.5:1 이상)
