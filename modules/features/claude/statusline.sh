#!/usr/bin/env bash
# Claude Code status line
# Layout: <dir> · <branch> · PR#<n> · <model> <effort> · ↑<in> ↓<out> · ch <pct>% · $<cost> (est) · ctx <pct>%/<size> · <pct>% (<time>) · <pct>% (<day/time>)
# Reads the session JSON on stdin. The PR lookup hits the network, so it is
# cached per repo+branch and refreshed in the background to keep this fast.
# Inside the neovim float the dir and branch are dropped

input=$(cat)

# pull every field we need in a single jq pass, emitted as shell assignments
eval "$(printf '%s' "$input" | jq -r '
  @sh "MODEL=\(.model.display_name // "?" | sub(" \\([^)]*context\\)$"; ""))",
  @sh "EFFORT=\(.effort.level // "")",
  @sh "DIR=\(.workspace.current_dir // .cwd // "")",
  @sh "CTX=\((.context_window.used_percentage // -1) | floor)",
  @sh "CTX_PCT=\((.context_window.used_percentage // -1) * 10 | round / 10)",
  @sh "CTX_SIZE=\(.context_window.context_window_size // -1)",
  @sh "COST=\(.cost.total_cost_usd // -1)",
  @sh "CACHE_HIT=\((.prompt_cache.hit_ratio // -1) * 100 | round)",
  @sh "TRANSCRIPT=\(.transcript_path // "")",
  @sh "SESSION=\(.session_id // "")",
  @sh "FIVE=\((.rate_limits.five_hour.used_percentage // -1) | floor)",
  @sh "WEEK=\((.rate_limits.seven_day.used_percentage // -1) | floor)",
  @sh "RESET=\((.rate_limits.five_hour.resets_at // -1) | floor)",
  @sh "WEEK_RESET=\((.rate_limits.seven_day.resets_at // -1) | floor)"
')"

# colors
RST=$'\033[0m'
DIM=$'\033[2m'
BLD=$'\033[1m'
CYAN=$'\033[36m'
BLUE=$'\033[34m'
MAG=$'\033[35m'
GRN=$'\033[32m'
YEL=$'\033[33m'
RED=$'\033[31m'

SEP=" ${DIM}·${RST} "

out=""
add() { # append a segment, separated only when one already precedes it
  [ -n "$out" ] && out+="$SEP"
  out+="$1"
}

lvlcol() { # pct -> severity color
  local p=$1
  if ((p >= 80)); then
    printf '%s' "$RED"
  elif ((p >= 50)); then
    printf '%s' "$YEL"
  else
    printf '%s' "$GRN"
  fi
}

compact_tokens() {
  LC_ALL=C awk -v n="$1" 'BEGIN {
    if (n >= 1000000) { n /= 1000000; suffix = "m" }
    else if (n >= 1000) { n /= 1000; suffix = "k" }
    s = sprintf("%.1f", n); sub(/\.0$/, "", s)
    printf "%s%s", s, suffix
  }'
}

# directory, skipped in the nvim float
if [ -z "$CLAUDE_NVIM_FLOAT" ]; then
  if [ "$DIR" = "$HOME" ]; then
    name="~"
  else
    name=$(basename "$DIR")
  fi
  [ -z "$name" ] && name="~"
  add "${BLD}${CYAN}${name}${RST}"
fi

# git branch + PR. the branch is still resolved in the float because the PR
# lookup keys off it, but only the PR is printed there
branch=$(git -C "$DIR" branch --show-current 2>/dev/null)
[ -z "$branch" ] && branch=$(git -C "$DIR" rev-parse --short HEAD 2>/dev/null)
if [ -n "$branch" ]; then
  [ -z "$CLAUDE_NVIM_FLOAT" ] && add "${MAG}${branch}${RST}"

  root=$(git -C "$DIR" rev-parse --show-toplevel 2>/dev/null)
  cdir="$HOME/.claude/.cache/statusline"
  mkdir -p "$cdir" 2>/dev/null
  key=$(printf '%s' "${root}:${branch}" | md5 2>/dev/null || printf '%s' "${root}:${branch}" | md5sum 2>/dev/null | cut -d' ' -f1)
  cf="$cdir/pr-$key"

  now=$(date +%s)
  fresh=0
  if [ -f "$cf" ]; then
    mtime=$(stat -f %m "$cf" 2>/dev/null || stat -c %Y "$cf" 2>/dev/null || echo 0)
    ((now - mtime < 60)) && fresh=1
  fi
  if ((fresh == 0)); then
    # refresh in the background, detached, so the status line never blocks on gh
    (cd "$root" 2>/dev/null && gh pr list --head "$branch" --state open \
      --json number --jq '.[0].number // empty' >"$cf.tmp" 2>/dev/null &&
      mv "$cf.tmp" "$cf" 2>/dev/null) >/dev/null 2>&1 &
    disown 2>/dev/null
  fi

  pr=""
  [ -f "$cf" ] && pr=$(cat "$cf" 2>/dev/null)
  [ -n "$pr" ] && add "${GRN}PR#${pr}${RST}"
fi

# model + effort
seg="${BLUE}${MODEL}${RST}"
[ -n "$EFFORT" ] && seg+=" ${DIM}${EFFORT}${RST}"
add "$seg"

# ponytail: scan the main transcript each refresh; add incremental caching if large sessions lag.
# Repeated content blocks share a message ID; keep the last usage for each response.
if [ -r "$TRANSCRIPT" ]; then
  totals=$(jq -Rrn --arg session "$SESSION" '
    reduce (inputs | fromjson? |
      select(.type == "assistant" and .isSidechain != true) |
      select($session == "" or .sessionId == $session) |
      .message | select(.id != null and .usage != null)) as $m
      ({}; .[$m.id] = $m.usage) |
    if length == 0 then empty else
      reduce .[] as $u ({i: 0, o: 0};
        .i += (($u.input_tokens // 0) + ($u.cache_creation_input_tokens // 0) + ($u.cache_read_input_tokens // 0)) |
        .o += ($u.output_tokens // 0)) |
      "\(.i) \(.o)"
    end
  ' <"$TRANSCRIPT" 2>/dev/null)
  if [ -n "$totals" ]; then
    read -r token_in token_out <<<"$totals"
    add "${DIM}↑${RST}$(compact_tokens "$token_in") ${DIM}↓${RST}$(compact_tokens "$token_out")"
  fi
fi

if [ "$CACHE_HIT" -ge 0 ] 2>/dev/null; then
  add "${DIM}ch${RST} ${CACHE_HIT}%"
fi

if [ "$COST" != -1 ]; then
  add "\$$(LC_ALL=C printf '%.3f' "$COST") ${DIM}(est)${RST}"
fi

# context window usage
if [ "$CTX" -ge 0 ] 2>/dev/null; then
  seg="${DIM}ctx${RST} $(lvlcol "$CTX")${CTX_PCT}%${RST}"
  if [ "$CTX_SIZE" -gt 0 ] 2>/dev/null; then
    seg+="${DIM}/$(compact_tokens "$CTX_SIZE")${RST}"
  fi
  add "$seg"
fi

# 5-hour rolling usage, with shorthand reset clock time in parens
if [ "$FIVE" -ge 0 ] 2>/dev/null; then
  seg="$(lvlcol "$FIVE")${FIVE}%${RST}"
  if [ "$RESET" -gt 0 ] 2>/dev/null; then
    ((RESET > 100000000000)) && RESET=$((RESET / 1000)) # ms -> s safety
    rt=$(date -r "$RESET" '+%-I:%M%p' 2>/dev/null || date -d "@$RESET" '+%-I:%M%p' 2>/dev/null)
    if [ -n "$rt" ]; then
      rt=$(printf '%s' "$rt" | tr 'APM' 'apm')
      rt=${rt%m} # 3:45PM -> 3:45p
      seg+=" ${DIM}(${rt})${RST}"
    fi
  fi
  add "$seg"
fi

if [ "$WEEK" -ge 0 ] 2>/dev/null; then
  seg="$(lvlcol "$WEEK")${WEEK}%${RST}"
  if [ "$WEEK_RESET" -gt 0 ] 2>/dev/null; then
    ((WEEK_RESET > 100000000000)) && WEEK_RESET=$((WEEK_RESET / 1000))
    rt=$(date -r "$WEEK_RESET" '+%a %-I:%M%p' 2>/dev/null || date -d "@$WEEK_RESET" '+%a %-I:%M%p' 2>/dev/null)
    if [ -n "$rt" ]; then
      rt=${rt/AM/a}
      rt=${rt/PM/p}
      seg+=" ${DIM}(${rt})${RST}"
    fi
  fi
  add "$seg"
fi

printf '%s' "$out"
