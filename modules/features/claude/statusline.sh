#!/usr/bin/env bash
# Claude Code status line
# Layout: <dir> · <branch> · PR#<n> · <model> <effort> · ↑<in> ↓<out> · ch <pct>% · $<cost> (est) · ctx <pct>%/<size> · <pct>% (<time>) · <pct>% (<day/time>)

# pull every field we need in a single jq pass, emitted as shell assignments
eval "$(jq -r '
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

cdir="$HOME/.claude/.cache/statusline"
[ -d "$cdir" ] || mkdir -p "$cdir" 2>/dev/null

out=""
add() { # append a segment, separated only when one already precedes it
  [ -n "$out" ] && out+="$SEP"
  out+="$1"
}

lvlcol() { # pct -> severity color in COL
  if (($1 >= 80)); then
    COL=$RED
  elif (($1 >= 50)); then
    COL=$YEL
  else
    COL=$GRN
  fi
}

compact_tokens() { # n -> REPLY: 950, 6.4k, 1.2m
  local n=$1 suffix=""
  if ((n >= 1000000)); then
    n=${n}e-6 suffix=m
  elif ((n >= 1000)); then
    n=${n}e-3 suffix=k
  fi
  LC_ALL=C printf -v REPLY '%.1f' "$n"
  REPLY=${REPLY%.0}$suffix
}

# directory
if [ -z "$DIR" ] || [ "$DIR" = "$HOME" ]; then
  name="~"
else
  name=${DIR##*/}
  name=${name:-/}
fi
add "${BLD}${CYAN}${name}${RST}"

# git branch + PR
root="" branch=""
{
  read -r root
  read -r branch
} < <(git -C "$DIR" rev-parse --show-toplevel --abbrev-ref HEAD 2>/dev/null)
if [ "$branch" = HEAD ]; then # detached or unborn
  branch=$(git -C "$DIR" branch --show-current 2>/dev/null)
  [ -z "$branch" ] && branch=$(git -C "$DIR" rev-parse --short HEAD 2>/dev/null)
fi
if [ -n "$root" ] && [ -n "$branch" ]; then
  add "${MAG}${branch}${RST}"

  key="${root}:${branch}"
  cf="$cdir/pr-${key//\//_}"
  printf -v now '%(%s)T' -1
  ts=0 pr=""
  [ -f "$cf" ] && read -r ts pr <"$cf"
  [[ $ts =~ ^[0-9]+$ ]] || ts=0
  if ((now - ts >= 60)); then
    # stamp before the lookup so a failed or slow gh waits out the window instead of respawning
    printf '%s %s\n' "$now" "$pr" >"$cf"
    (cd "$root" && p=$(gh pr list --head "$branch" --state open \
      --json number --jq '.[0].number // empty') &&
      printf '%s %s\n' "$now" "$p" >"$cf") >/dev/null 2>&1 &
    disown 2>/dev/null
  fi
  [ -n "$pr" ] && add "${GRN}PR#${pr}${RST}"
fi

# model + effort
seg="${BLUE}${MODEL}${RST}"
[ -n "$EFFORT" ] && seg+=" ${DIM}${EFFORT}${RST}"
add "$seg"

# Session token totals from the main transcript. The cache line holds the consumed byte offset,
# the totals, and the last 64 response ids with their usage: repeated content blocks share a
# message id and the last usage wins, so a response seen again is swapped out, not added twice.
# ponytail: an id repeated more than 64 responses later double counts; widen the window if it does.
scan() { # offset in out recent -> next cache line, or RESET when the file no longer matches
  tail -c "+$1" "$TRANSCRIPT" 2>/dev/null | jq -Rrs --arg session "$SESSION" \
    --argjson off "$1" --argjson st "{\"i\":$2,\"o\":$3,\"recent\":$4}" '
    if $off > 0 and (startswith("\n") | not) then "RESET" else
      (if $off > 0 then .[1:] else . end) as $body |
      ($body | split("\n")) as $lines |
      reduce ($lines[:-1][] | fromjson? |
        select(.type == "assistant" and .isSidechain != true) |
        select($session == "" or .sessionId == $session) |
        .message | select(.id != null and .usage != null)) as $m
        ($st;
          ($m.usage | [(.input_tokens // 0) + (.cache_creation_input_tokens // 0) + (.cache_read_input_tokens // 0),
            .output_tokens // 0]) as $u |
          (.recent | map(.[0]) | index($m.id)) as $k |
          if $k then .i -= .recent[$k][1] | .o -= .recent[$k][2] | .recent[$k] = [$m.id] + $u
          else .recent = (.recent + [[$m.id] + $u])[-64:] end |
          .i += $u[0] | .o += $u[1]) |
      "\($off + ($body | utf8bytelength) - ($lines[-1] | utf8bytelength)) \(.i) \(.o) \(.recent | tojson)"
    end'
}

if [ -r "$TRANSCRIPT" ]; then
  tf="$cdir/tok-${SESSION}${TRANSCRIPT//\//_}"
  off=0 ti=0 to=0 recent='[]'
  [ -f "$tf" ] && read -r off ti to recent <"$tf"
  # unchanged transcript: no jq at all. ponytail: an append racing the cache write shows on the next append
  if [ "$TRANSCRIPT" -nt "$tf" ]; then
    st=$(scan "$off" "$ti" "$to" "$recent")
    [ "$st" = RESET ] && st=$(scan 0 0 0 '[]')
    if [ -n "$st" ]; then
      read -r off ti to recent <<<"$st"
      printf '%s\n' "$st" >"$tf.$$" && mv -f "$tf.$$" "$tf"
    fi
  fi
  if [ "$recent" != '[]' ]; then
    compact_tokens "$ti"
    seg="${DIM}↑${RST}${REPLY} "
    compact_tokens "$to"
    add "$seg${DIM}↓${RST}${REPLY}"
  fi
fi

if [ "$CACHE_HIT" -ge 0 ] 2>/dev/null; then
  add "${DIM}ch${RST} ${CACHE_HIT}%"
fi

if [ "$COST" != -1 ]; then
  LC_ALL=C printf -v usd '%.3f' "$COST"
  add "\$$usd ${DIM}(est)${RST}"
fi

# context window usage
if [ "$CTX" -ge 0 ] 2>/dev/null; then
  lvlcol "$CTX"
  seg="${DIM}ctx${RST} ${COL}${CTX_PCT}%${RST}"
  if [ "$CTX_SIZE" -gt 0 ] 2>/dev/null; then
    compact_tokens "$CTX_SIZE"
    seg+="${DIM}/${REPLY}${RST}"
  fi
  add "$seg"
fi

# 5-hour rolling usage, with shorthand reset clock time in parens
if [ "$FIVE" -ge 0 ] 2>/dev/null; then
  lvlcol "$FIVE"
  seg="${COL}${FIVE}%${RST}"
  if [ "$RESET" -gt 0 ] 2>/dev/null; then
    ((RESET > 100000000000)) && RESET=$((RESET / 1000)) # ms -> s safety
    printf -v rt '%(%-I:%M%p)T' "$RESET"
    rt=${rt,,}
    seg+=" ${DIM}(${rt%m})${RST}" # 3:45PM -> 3:45p
  fi
  add "$seg"
fi

if [ "$WEEK" -ge 0 ] 2>/dev/null; then
  lvlcol "$WEEK"
  seg="${COL}${WEEK}%${RST}"
  if [ "$WEEK_RESET" -gt 0 ] 2>/dev/null; then
    ((WEEK_RESET > 100000000000)) && WEEK_RESET=$((WEEK_RESET / 1000))
    printf -v rt '%(%a %-I:%M%p)T' "$WEEK_RESET"
    rt=${rt/AM/a}
    seg+=" ${DIM}(${rt/PM/p})${RST}"
  fi
  add "$seg"
fi

printf '%s' "$out"
