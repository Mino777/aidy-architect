# Aidy 네이밍 & 코딩 컨벤션

> 모든 워커가 따르는 통일 규칙. 설계자만 수정.

## API 네이밍

- URL: kebab-case (`/api/chat/history`)
- JSON 필드: camelCase (`memoriesExtracted`)
- Error code: UPPER_SNAKE (`EMPTY_MESSAGE`)

## 백엔드 (Kotlin)

- 패키지: `com.mino.aidy.{layer}.{feature}`
- Entity: PascalCase 단수형 (`ChatMessage`, `Memory`)
- Repository: `{Entity}Repository`
- Service: `{Feature}Service`
- Controller: `{Feature}Controller`
- DTO: `{Action}{Feature}Request/Response`

## iOS (Swift + TCA)

- Feature: `{Name}Feature` (Reducer) + `{Name}View`
- State: Feature 내부 `@ObservableState struct State`
- Action: Feature 내부 `enum Action`
- Model: 단수형 (`ChatMessage`, `MemoryItem`)
- DependencyClient: `{Name}Client` (e.g., `APIClient`)

## Android (Kotlin + Compose)

- Package: `com.mino.aidy.{layer}.{feature}`
- Screen: `{Name}Screen` (Composable)
- ViewModel: `{Name}ViewModel`
- Model: 단수형 (`ChatMessage`, `MemoryItem`)
- API: `AidyApiService` (Retrofit interface)

## Git

- 브랜치: `feature/{wo-number}-{short-desc}` (e.g., `feature/wo-001-chat-api`)
- 커밋: 한글 (ai-study 컨벤션 계승)
- PR 제목: `[WO-001] 채팅 API 구현`

## Memory Categories

**7개 고정 enum** — 추가/변경은 설계자 ADR 필요:
schedule, finance, work, health, preference, people, general
