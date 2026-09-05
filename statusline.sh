#!/bin/bash
# Status line: how full this session is, how much of the five-hour budget is gone,
# and how long until that budget resets.
# Fails silent: a broken status line must never stop the session.

in=$(cat 2>/dev/null) || exit 0
command -v jq >/dev/null 2>&1 || exit 0

g() { printf '%s' "$in" | jq -r "$1 // empty" 2>/dev/null; }

DIM=$'\033[2m'; OFF=$'\033[0m'
GRN=$'\033[32m'; YEL=$'\033[33m'; RED=$'\033[31m'; CYN=$'\033[36m'

model=$(g '.model.display_name')
effort=$(g '.effort.level')
pct=$(g '.context_window.used_percentage')
lim=$(g '.rate_limits.five_hour.used_percentage')
reset=$(g '.rate_limits.five_hour.resets_at')
style=$(g '.output_style.name')
dir=$(g '.workspace.current_dir')

# "Opus 5 (1M context)" reads as "Opus 5". The size is not news every turn.
model=${model%% (*}; model=${model%% [*}

# Green under half, amber under 80, red past it.
ramp() { if [ "$1" -ge 80 ]; then printf '%s' "$RED"
       elif [ "$1" -ge 50 ]; then printf '%s' "$YEL"
       else printf '%s' "$GRN"; fi; }

parts=()
[ -n "$model" ] && parts+=("${CYN}${model}${OFF}")
[ -n "$effort" ] && parts+=("${DIM}${effort}${OFF}")

# This session's context.
if [ -n "$pct" ]; then
  p=${pct%.*}; p=${p:-0}
  parts+=("$(ramp "$p")ctx ${p}%${OFF}")
fi

# How much of the five-hour budget is gone.
if [ -n "$lim" ]; then
  l=${lim%.*}; l=${l:-0}
  parts+=("$(ramp "$l")5h ${l}%${OFF}")
fi

# Time until that budget resets.
if [ -n "$reset" ]; then
  secs=$(( reset - $(date +%s) ))
  if [ "$secs" -gt 0 ]; then
    [ "$secs" -le 1800 ] && c=$RED || c=$DIM
    parts+=("${c}$(printf '%dh%02dm' $(( secs/3600 )) $(( (secs%3600)/60 )))${OFF}")
  fi
fi

# Which output style is talking. Default is not worth a slot.
case "$style" in ""|default|Default) ;; *) parts+=("${DIM}${style}${OFF}") ;; esac

# Branch, with a dot when the tree is dirty.
if [ -n "$dir" ] && [ -d "$dir" ]; then
  br=$(git -C "$dir" branch --show-current 2>/dev/null)
  if [ -n "$br" ]; then
    git -C "$dir" diff --quiet --ignore-submodules HEAD 2>/dev/null || br="${br}●"
    parts+=("${DIM}${br}${OFF}")
  fi
fi

# The finish line. Armed and unmet is the state worth seeing.
FL="$HOME/.claude/.finish-line"
if [ -f "$FL" ] && ! grep -q '^DONE:' "$FL" 2>/dev/null; then
  parts+=("${RED}finish line open${OFF}")
fi

out=""
for p in "${parts[@]}"; do
  [ -n "$out" ] && out="$out ${DIM}│${OFF} "
  out="$out$p"
done
printf '%s' "$out"
