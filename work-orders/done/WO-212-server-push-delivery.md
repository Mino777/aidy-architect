# WO-212: Server Push Notification Delivery (v7.0)

## 목표
기존 디바이스 토큰 등록(v1.1)을 활용해 실제 FCM 푸시 발송 파이프라인 구축.

## 스펙 참조
`specs/api-contract.md` §5.53 Push Notification Delivery (v7.0)

## 구현 범위
1. NotificationDeliveryService — FCM HTTP v1 API 호출 (spring-web RestClient)
2. NotificationEntity + NotificationRepository — 발송 이력 저장
3. NotificationController — send, history, read, test 엔드포인트 4개
4. 기존 NudgeService/ReminderService에서 NotificationDeliveryService 호출 연동
5. FCM 키는 `application.yml`에 `aidy.fcm.server-key` (환경변수 주입)
6. Controller + Service 테스트

## 제약
- 커밋 메시지: `[R2-server] feat: WO-212 Push Notification Delivery`
- 새 패키지 설치 금지 (spring-web의 RestClient 사용)
- testDebugUnitTest 대신 `./gradlew test` 통과 필수
- 커밋 1건당 파일 10개 이하
