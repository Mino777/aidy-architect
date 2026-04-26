# WO-183: Android Compose 상태 관리 최적화

**담당**: android
**우선순위**: P2
**상태**: done

## 배경
mutableStateOf 431개 사용. ViewModel 내 과도한 개별 상태 변수 → 불필요한 recomposition 위험 + 상태 관리 복잡도 증가.

## 구현 요구사항

### 1. 상태 통합 패턴 적용
- ViewModel당 개별 `mutableStateOf` → `data class UiState` 통합
- 기존 패턴:
```kotlin
// Before
var items by mutableStateOf<List<Item>>(emptyList())
var isLoading by mutableStateOf(false)
var error by mutableStateOf<String?>(null)

// After
data class XxxUiState(
    val items: List<Item> = emptyList(),
    val isLoading: Boolean = false,
    val error: String? = null
)
var uiState by mutableStateOf(XxxUiState())
```

### 2. 적용 범위
- 3개 이상 mutableStateOf를 가진 ViewModel 우선 리팩터링
- 주요 대상: Chat, Memory, People, Settings 관련 ViewModel

### 3. derivedStateOf 활용
- 파생 상태는 `derivedStateOf`로 전환 (불필요한 recomposition 방지)

## 빌드 검증
- `./gradlew testDebugUnitTest` 통과 필수

## 완료 기준
- [ ] 주요 ViewModel UiState 통합 (최소 10개)
- [ ] mutableStateOf 431 → 200개 이하
- [ ] `./gradlew testDebugUnitTest` 통과
- [ ] 변경 전후 개수 보고
