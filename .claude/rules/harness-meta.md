---
description: 하네스 파일 수정 시 CLAUDE.md 250줄 제한 + settings.json deny 보존 확인
globs: .claude/**/*
---
# 하네스 메타 규칙

- CLAUDE.md는 250줄 이하 유지. 초과 시 Skills/Rules로 분리.
- settings.json의 deny 규칙 7개를 절대 삭제하지 않는다.
- hooks/*.sh 파일 수정 시 exit 2 (차단)과 exit 1 (경고만)을 구분한다.
- 보안 관련 hook은 반드시 exit 2를 사용한다.
