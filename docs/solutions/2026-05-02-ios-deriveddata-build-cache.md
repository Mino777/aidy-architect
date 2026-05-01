# iOS DerivedData 반복 클리어로 빌드 30분 소요

## 증상
iOS 워커가 tuist build 실패 시 DerivedData를 통째로 삭제하고 재빌드. 한 WO에서 3회 반복하여 30분 소요.

## 해결 (before → after)
- Before: 빌드 실패 → `rm -rf DerivedData` → 풀 리빌드 (5~7분)
- After: 빌드 실패 → `rm -rf DerivedData/*/Build/Intermediates.noindex/XCBuildData/build.db` → 증분 리빌드 (1~2분)

## 근본 원인
tuist build가 XCBuildData/build.db 락 충돌로 실패할 때, build.db만 삭제하면 증분 빌드가 가능하다. 전체 DerivedData 삭제는 모든 빌드 캐시를 날리므로 풀 리빌드 강제.

## 체크리스트 (재발 방지)
- [ ] iOS WO에 "DerivedData 전체 삭제 금지, build.db만 삭제" 명시
- [ ] 워커 CLAUDE.md에 빌드 캐시 관리 지침 추가
