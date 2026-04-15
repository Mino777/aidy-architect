# ADR-001: 기술 스택 결정

**상태**: 확정
**날짜**: 2026-04-15

## 결정

| Layer | 기술 | 이유 |
|-------|------|------|
| Backend | Spring Boot 3.5 + Kotlin | Android와 언어 공유, 엔터프라이즈급 |
| iOS | Tuist + SPM + TCA + SwiftUI | 모듈화 + 단방향 아키텍처 |
| Android | Kotlin + Jetpack Compose + MVVM | 네이티브 최신 스택 |
| DB | PostgreSQL 17 | 범용성, Flyway 마이그레이션 |
| AI | Claude API (Haiku 4.5) | 비용 효율 + 품질 |
| 배포 | Railway (서버) + Neon (DB) | 무료 티어 시작 |

## 대안 검토

- React Native → 거부: 네이티브 각각 개발이 학습 목적에 맞음
- Supabase → 보류: v0.2에서 Auth로 부분 도입 가능
- Go backend → 거부: Kotlin 공유가 Android 학습에 유리
