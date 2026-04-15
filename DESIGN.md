# Design System — Aidy

## Product Context
- **What this is:** AI 관계 메모리 비서. 대화에서 사람/관계 맥락을 자동 추출하고 기억하는 앱.
- **Who it's for:** 한국 직장인 20-30대. 매일 수십 명과 소통하며 관계 맥락을 기억해야 하는 사람.
- **Space/industry:** AI 개인 비서, 관계 관리 (CRM이 아닌 개인용)
- **Project type:** 네이티브 모바일 앱 (iOS SwiftUI + Android Jetpack Compose)

## Aesthetic Direction
- **Direction:** Organic/Natural
- **Decoration level:** Intentional (미묘한 텍스처, 부드러운 그림자)
- **Mood:** 따뜻하고 자연스러운 느낌. "나를 아는 친구의 노트"처럼. CRM의 차가움이 아니라 인간적 따뜻함.
- **Reference:** 한국 디자인의 감정적 따뜻함 + 글로벌 미니멀리즘의 깔끔한 계층

## Typography
- **Body/UI:** Pretendard — 한국어 최적화, 깔끔한 고딕체. 자간/행간이 한글에 맞춤.
- **System:** SF Pro (iOS) / Material (Android) — 플랫폼 네이티브 일관성
- **Data/Tables:** Pretendard (tabular-nums)
- **Loading:** Pretendard는 CDN (cdn.jsdelivr.net) 또는 앱 번들 내장
- **Scale:**
  - Caption: 12px / Regular
  - Body: 15px / Regular
  - Headline: 17px / Semibold
  - Title: 22px / Bold
  - Large Title: 28px / Bold

## Color
- **Approach:** Restrained (1 액센트 + 뉴트럴)
- **Background:** #FAFAF7 (따뜻한 화이트 — 차가운 #FFFFFF와 차별화)
- **Surface:** #FFFFFF (카드, 바텀시트)
- **Text Primary:** #1A1A1A
- **Text Muted:** #8E8E93
- **Accent:** #2D7D46 (딥 그린 — 성장/기억의 상징. AI 앱의 보라/파란 패턴을 깨는 의도적 선택)
- **Accent Light:** #E8F5E9 (액센트 배경용)
- **Avatar Colors:** #5B8A72, #4A7AB5, #8B6DAF, #C4754B, #B5544D (이니셜 기반 결정적 배정)
- **Semantic:**
  - Success: #2D7D46 (액센트와 동일)
  - Warning: #F5A623
  - Error: #D32F2F
  - Info: #4A7AB5
- **Dark Mode:** 배경 #1C1C1E, 서피스 #2C2C2E, 텍스트 반전, 액센트 밝기 +15%

## Spacing
- **Base unit:** 8px
- **Density:** Comfortable
- **Scale:** 2xs(2) xs(4) sm(8) md(16) lg(24) xl(32) 2xl(48) 3xl(64)

## Layout
- **Approach:** Grid-disciplined (플랫폼 네이티브 그리드 준수)
- **iOS:** Safe area + 16px 양쪽 패딩
- **Android:** 16dp 양쪽 패딩, Material 3 가이드
- **Border radius:** sm(8) md(12) lg(16) full(9999) — 부드럽지만 과하지 않게
- **Tab bar:** Chat / People / Settings (3탭)

## Motion
- **Approach:** Minimal-functional
- **Spring animation:** 바텀시트, 카드 등장에 spring(response: 0.35, dampingFraction: 0.8)
- **Fade:** 항목 삭제 시 fadeOut(0.25s)
- **Duration:** micro(100ms) short(200ms) medium(350ms)
- **원칙:** 모션은 이해를 돕는 것만. 장식용 모션 금지.

## Component Patterns

### 인물 카드 (피플 목록)
- 리스트 행 패턴 (카드 아님 — 연락처 앱 스타일)
- 왼쪽: 이니셜 아바타 (40px, 원형, Avatar Colors에서 결정적 배정)
- 가운데: 이름 (Headline) + relationship (Caption, Muted)
- 아래: 최근 기억 snippet (Body, 1줄 말줄임) + 날짜 (Caption, Muted)
- 오른쪽: 셰브론 (>)

### 기억 확인 카드 (채팅 후)
- 바텀시트 (채팅 흐름 방해 최소)
- spring 애니메이션으로 올라옴
- 타이틀: "이 대화에서 기억된 것"
- 인물 아바타 + 이름 + 추출된 trait
- 피드백 버튼: ✓맞아 / ✗틀려 (터치 타겟 44px 이상)

### 피드백 "틀려"
- 확인 다이얼로그: "이 기억을 삭제할까요?" (오탭 방지)
- 삭제 시 fadeOut 애니메이션

### 빈 화면 (첫 사용)
- 따뜻한 일러스트 (기계적이지 않은 스타일)
- "대화에서 사람을 언급하면 Aidy가 기억합니다"
- 예시 문구: "오늘 김 팀장님이 스타벅스 좋아한다고 했어"
- CTA: "채팅 시작하기" (Accent 배경)

## Accessibility
- **터치 타겟:** 최소 44px (iOS) / 48dp (Android)
- **VoiceOver/TalkBack:** 모든 인터랙티브 요소에 접근성 레이블
- **다크 모드:** 시스템 설정 연동 필수
- **Dynamic Type (iOS):** 큰 텍스트 모드 지원, 레이아웃 깨짐 방지
- **컬러 대비:** WCAG AA (텍스트 4.5:1, 큰 텍스트 3:1)

## Decisions Log
| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-04-16 | 디자인 시스템 생성 | /design-consultation — Organic/Natural 방향, 딥 그린 액센트 |
| 2026-04-16 | 피플 목록 = 리스트 행 | /plan-design-review — 연락처 패턴, 카드보다 밀도 높음 |
| 2026-04-16 | 확인 카드 = 바텀시트 | /plan-design-review — 채팅 흐름 방해 최소 |
| 2026-04-16 | "틀려" = 확인 다이얼로그 | /plan-design-review — 오탭으로 인한 기억 삭제 방지 |
