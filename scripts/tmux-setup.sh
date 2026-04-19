#!/bin/bash
# Aidy 관제 tmux 셋업
# 레이아웃: 왼쪽 architect | 오른쪽 server/ios/android 3등분
#
# 사용법: ./scripts/tmux-setup.sh

SESSION="aidy"
BASE="$HOME/Develop"

# 기존 세션 있으면 종료
tmux kill-session -t "$SESSION" 2>/dev/null

# 새 세션 (architect)
tmux new-session -d -s "$SESSION" -n control -c "$BASE/aidy-architect"

# 오른쪽 절반: server (상단)
tmux split-window -h -t "$SESSION:0.0" -c "$BASE/aidy-server" -p 50

# 오른쪽 중간: ios
tmux split-window -v -t "$SESSION:0.1" -c "$BASE/aidy-ios" -p 66

# 오른쪽 하단: android
tmux split-window -v -t "$SESSION:0.2" -c "$BASE/aidy-android" -p 50

# 마우스 활성화
tmux set-option -g mouse on

# architect 패널 포커스
tmux select-pane -t "$SESSION:0.0"

# 연결
tmux attach-session -t "$SESSION"
