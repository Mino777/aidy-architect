# WO-218: iOS Memory Emotions + AI Personas (v7.2~v7.3)

## 목표
메모리 감정 필터/트렌드 UI + AI 페르소나 설정 화면.

## 스펙 참조
- `specs/api-contract.md` §5.55 Memory Emotions (v7.2)
- `specs/api-contract.md` §5.56 AI Chat Personas (v7.3)

## 구현 범위

### Memory Emotions
1. MemoryClient에 emotion 필터 + trend + personEmotions API 추가
2. EmotionTrendFeature (TCA) — 감정 트렌드 차트
3. EmotionTrendView (SwiftUI) — 월별 감정 분포 차트
4. MemoryListView에 감정 필터 칩 추가
5. MemoryDetailView에 감정 배지 + 수정 기능

### AI Personas
6. PersonaClient — personas, set default, set per-person, delete
7. PersonaSettingsFeature (TCA)
8. PersonaSettingsView (SwiftUI) — 페르소나 선택 UI
9. PersonDetailView에 "AI 스타일" 설정 추가
10. ChatView에 현재 페르소나 표시

## 제약
- 커밋 메시지: `[R7-ios] feat: WO-218 Emotions + Personas`
- tuist build 통과 필수 (xcodebuild test 금지)
- 커밋 1건당 파일 10개 이하
