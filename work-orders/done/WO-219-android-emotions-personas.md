# WO-219: Android Memory Emotions + AI Personas (v7.2~v7.3)

## 목표
메모리 감정 필터/트렌드 UI + AI 페르소나 설정 화면.

## 스펙 참조
- `specs/api-contract.md` §5.55 Memory Emotions (v7.2)
- `specs/api-contract.md` §5.56 AI Chat Personas (v7.3)

## 구현 범위

### Memory Emotions
1. MemoryApiService에 emotion 필터 + trend + personEmotions 추가
2. EmotionTrendViewModel
3. EmotionTrendScreen (Compose) — 월별 감정 분포 차트
4. MemoryListScreen에 감정 필터 칩 추가
5. MemoryDetailScreen에 감정 배지 + 수정 기능

### AI Personas
6. PersonaApiService — personas, set default, set per-person, delete
7. PersonaRepository
8. PersonaSettingsViewModel
9. PersonaSettingsScreen (Compose) — 페르소나 선택 UI
10. PersonDetailScreen에 "AI 스타일" 설정 추가
11. ChatScreen에 현재 페르소나 표시

## 제약
- 커밋 메시지: `[R8-android] feat: WO-219 Emotions + Personas`
- testDebugUnitTest 통과 필수
- 커밋 1건당 파일 10개 이하
