#!/bin/bash

# Claude Code Status Line
# 세션 컨텍스트 + 주간 사용량 프로그레스 바

input=$(cat)

# ANSI 색상 코드
RESET="\033[0m"
BOLD="\033[1m"
DIM="\033[2m"
CYAN="\033[96m"
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
MAGENTA="\033[35m"

# 주간 한도 설정
WEEKLY_LIMIT=100

# 주간 사용량 캐시 (5분마다 갱신)
CACHE_FILE="/tmp/claude-weekly-cost-cache"
CACHE_TTL=300

get_weekly_cost() {
    local now=$(date +%s)
    local cached_time=0
    local cached_cost="0"

    if [ -f "$CACHE_FILE" ]; then
        cached_time=$(head -1 "$CACHE_FILE" 2>/dev/null || echo "0")
        cached_cost=$(tail -1 "$CACHE_FILE" 2>/dev/null || echo "0")
    fi

    local age=$((now - cached_time))

    if [ "$age" -gt "$CACHE_TTL" ]; then
        local weekly_json=$(npx ccusage weekly --json 2>/dev/null)
        if [ -n "$weekly_json" ]; then
            cached_cost=$(echo "$weekly_json" | jq -r '.weekly[-1].totalCost // 0')
            echo "$now" > "$CACHE_FILE"
            echo "$cached_cost" >> "$CACHE_FILE"
        fi
    fi

    echo "$cached_cost"
}

WEEKLY_COST=$(get_weekly_cost)

# JSON 파싱
MODEL_ID=$(echo "$input" | jq -r '.model.id // "unknown"')
MODEL_NAME=$(echo "$input" | jq -r '.model.display_name // "Unknown"')
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
LINES_ADDED=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
LINES_REMOVED=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')
CONTEXT_SIZE=$(echo "$input" | jq -r '.context_window.context_window_size // 200000')
USAGE=$(echo "$input" | jq '.context_window.current_usage // null')

# 모델명 처리
if [[ "$MODEL_NAME" =~ [0-9] ]]; then
    MODEL_DISPLAY="$MODEL_NAME"
else
    VERSION=""
    if [[ "$MODEL_ID" =~ claude-([a-z]+)-([0-9]+)-([0-9]+) ]]; then
        VERSION="${BASH_REMATCH[2]}.${BASH_REMATCH[3]}"
    elif [[ "$MODEL_ID" =~ claude-([a-z]+)-([0-9]+) ]]; then
        VERSION="${BASH_REMATCH[2]}"
    fi
    if [ -n "$VERSION" ]; then
        MODEL_DISPLAY="$MODEL_NAME $VERSION"
    else
        MODEL_DISPLAY="$MODEL_NAME"
    fi
fi

# 프로그레스 바 생성 함수
make_bar() {
    local percent=$1
    local width=$2
    local filled=$((percent * width / 100))
    [ "$filled" -gt "$width" ] && filled=$width
    [ "$filled" -lt 0 ] && filled=0
    local empty=$((width - filled))

    local bar=""
    for ((i=0; i<filled; i++)); do bar+="█"; done
    for ((i=0; i<empty; i++)); do bar+="░"; done
    echo "$bar"
}

# 색상 선택 함수
get_color() {
    local percent=$1
    if [ "$percent" -le 60 ]; then
        echo "$GREEN"
    elif [ "$percent" -le 80 ]; then
        echo "$YELLOW"
    else
        echo "$RED"
    fi
}

# 세션 컨텍스트 사용률
SESSION_PERCENT=0
if [ "$USAGE" != "null" ]; then
    INPUT_TOKENS=$(echo "$USAGE" | jq '.input_tokens // 0')
    CACHE_CREATE=$(echo "$USAGE" | jq '.cache_creation_input_tokens // 0')
    CACHE_READ=$(echo "$USAGE" | jq '.cache_read_input_tokens // 0')
    CURRENT_TOKENS=$((INPUT_TOKENS + CACHE_CREATE + CACHE_READ))
    if [ "$CONTEXT_SIZE" -gt 0 ]; then
        SESSION_PERCENT=$((CURRENT_TOKENS * 100 / CONTEXT_SIZE))
    fi
fi

# 주간 사용률
WEEKLY_PERCENT=$(echo "$WEEKLY_COST $WEEKLY_LIMIT" | awk '{printf "%.0f", ($1 / $2) * 100}')
[ "$WEEKLY_PERCENT" -gt 100 ] && WEEKLY_PERCENT=100

# 프로그레스 바 생성 (각 10칸)
BAR_WIDTH=10
SESSION_BAR=$(make_bar $SESSION_PERCENT $BAR_WIDTH)
WEEKLY_BAR=$(make_bar $WEEKLY_PERCENT $BAR_WIDTH)

SESSION_COLOR=$(get_color $SESSION_PERCENT)
WEEKLY_COLOR=$(get_color $WEEKLY_PERCENT)

# 비용 포맷
COST_FMT=$(printf "%.2f" "$COST")

# 출력: [모델] S:바 % W:바 % | $세션비용 | +라인/-라인
printf "${BOLD}${CYAN}[%s]${RESET} ${DIM}S:${RESET}${SESSION_COLOR}%s${RESET} %2d%% ${DIM}W:${RESET}${WEEKLY_COLOR}%s${RESET} %2d%% ${DIM}|${RESET} ${MAGENTA}\$%s${RESET} ${DIM}|${RESET} ${GREEN}+%d${RESET}${DIM}/${RESET}${RED}-%d${RESET}" \
    "$MODEL_DISPLAY" \
    "$SESSION_BAR" \
    "$SESSION_PERCENT" \
    "$WEEKLY_BAR" \
    "$WEEKLY_PERCENT" \
    "$COST_FMT" \
    "$LINES_ADDED" \
    "$LINES_REMOVED"
