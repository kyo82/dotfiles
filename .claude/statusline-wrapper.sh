#!/usr/bin/env bash
# statusline-wrapper.sh
# Claude Code statusLine 래퍼: claude-dashboard 출력을 그대로 전달한다

DASHBOARD_SCRIPT="$HOME/.claude/plugins/claude-dashboard/dist/index.js"

# stdin을 변수에 저장
input=$(cat)

# 대시보드 출력 (stdin을 파이프로 전달)
dashboard_output=$(echo "$input" | node "$DASHBOARD_SCRIPT" 2>/dev/null)

if [ -n "$dashboard_output" ]; then
  printf "%s\n" "$dashboard_output"
fi
