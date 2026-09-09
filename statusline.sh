#!/bin/bash
# Claude Code status line.
#   model │ effort │ ctx 21% │ 5h 23% │ 3h20m │ output style │ branch
# Fails silent: a broken status line must never interrupt a session.

in=$(cat 2>/dev/null) || exit 0
[ -n "$in" ] || exit 0
command -v jq >/dev/null 2>&1 || exit 0
printf '%s' "$in" | jq -e . >/dev/null 2>&1 || exit 0

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

# "Opus 5 (1M context)" reads as "Opus 5". Window size is not news every turn.
model=${model%% (*}; model=${model%% [*}

# Green under half, amber under 80, red past it.
ramp() { if [ "$1" -ge 80 ]; then printf '%s' "$RED"
       elif [ "$1" -ge 50 ]; then printf '%s' "$YEL"
       else printf '%s' "$GRN"; fi; }

parts=()
[ -n "$model" ]  && parts+=("${CYN}${model}${OFF}")
[ -n "$effort" ] && parts+=("${DIM}${effort}${OFF}")

# This session's context.
if [ -n "$pct" ]; then
  p=${pct%.*}; case "$p" in ''|*[!0-9]*) p= ;; esac
  [ -n "$p" ] && parts+=("$(ramp "$p")ctx ${p}%${OFF}")
fi

# How much of the five-hour budget is gone.
if [ -n "$lim" ]; then
  l=${lim%.*}; case "$l" in ''|*[!0-9]*) l= ;; esac
  [ -n "$l" ] && parts+=("$(ramp "$l")5h ${l}%${OFF}")
fi

# Time until that budget resets. Dim, red inside the last half hour.
if [ -n "$reset" ]; then
  case "$reset" in ''|*[!0-9]*) reset= ;; esac
  if [ -n "$reset" ]; then
    secs=$(( reset - $(date +%s) ))
    if [ "$secs" -gt 0 ]; then
      [ "$secs" -le 1800 ] && c=$RED || c=$DIM
      parts+=("${c}$(printf '%dh%02dm' $(( secs/3600 )) $(( (secs%3600)/60 )))${OFF}")
    fi
  fi
fi

# The output style, when it isn't the default.
case "$style" in ""|default|Default) ;; *) parts+=("${DIM}${style}${OFF}") ;; esac

# Branch, with a dot when the tree is dirty.
if [ -n "$dir" ] && [ -d "$dir" ]; then
  br=$(git -C "$dir" branch --show-current 2>/dev/null)
  if [ -n "$br" ]; then
    git -C "$dir" diff --quiet --ignore-submodules HEAD 2>/dev/null || br="${br}●"
    parts+=("${DIM}${br}${OFF}")
  fi
fi

out=""
for p in "${parts[@]}"; do
  [ -n "$out" ] && out="$out ${DIM}│${OFF} "
  out="$out$p"
done
printf '%s' "$out"
