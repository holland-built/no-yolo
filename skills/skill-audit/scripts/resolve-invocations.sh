#!/usr/bin/env bash
# resolve-invocations.sh
#
# For every $HOME/.claude/skills/*/SKILL.md, emit CANDIDATE script/skill
# invocations found in the text, so a reading agent can judge them.
#
# This script emits candidates and evidence ONLY. It never prints a verdict
# ("has verifier" / "no verifier" / etc.) — that judgment belongs to whoever
# reads this output.
#
# Output: one pipe-delimited row per candidate, to stdout:
#   skill|lineno|kind|resolved
#
#   kind     - exactly one of: bash-script, skill-tool, unresolved
#   resolved - an absolute path, or the raw unresolved string prefixed
#              "UNRESOLVED: "
#
# Detected invocation forms:
#   1. bash-script — a .py/.sh file invoked via python3/python/bash/sh,
#      wrapped in backticks as a standalone reference, or run directly
#      (./script.sh).
#   2. skill-tool  — a "/skillname" reference, or a
#      "Skill tool, skill: "name"" reference.
#
# Path resolution precedence (highest first), resolved TEXTUALLY — this
# script never executes or evals a substitution:
#   1. $HOME-prefixed
#   2. literal ${CLAUDE_SKILL_DIR}-prefixed (= the containing skill's own dir)
#   3. tilde-prefixed
#   4. literal absolute (starts with /)
#   5. cwd-relative -> tested for existence against two candidates,
#      $HOME/.claude/<path> then <the referencing file's own dir>/<path>;
#      if exactly one exists it resolves (suffixed " (cwd-assumed)"),
#      otherwise it stays "unresolved" (an existence check is evidence,
#      never an invented path)
#
# Frontmatter (the opening/closing --- block) is never scanned — a skill's
# own trigger description quoting its slash command is not an invocation.
# A "/name" is only an invocation when preceded by an invocation verb
# (run/invoke/call/dispatch/fires/routes to); a bare "Skill tool, skill:
# "name"" mention always counts. Self-references (skill X's own name) and
# this resolver's own source file (recursing into its own pattern-doc
# comments) are never emitted/followed.
#
# A resolved bash-script that itself invokes another script is followed,
# to a max depth of 3, with cycle detection. Truncation at the depth limit
# emits an "unresolved" row rather than staying silent.
#
# POSIX-ish bash (tested against bash 3.2 / BSD grep). No deps beyond
# coreutils/grep/sed/awk. Always exits 0 on a clean run.

set -u

SKILLS_DIR="$HOME/.claude/skills"
MAX_DEPTH=3

# this script's own absolute path — recursing into it (e.g. when a skill's
# SKILL.md documents running it) would scan its own pattern-doc comments,
# which match its own detection regexes and are noise, not invocations.
SELF_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/$(basename "${BASH_SOURCE[0]}")"

# ---- literal tokens used both to detect prefixes and to strip them ----
BQ='`'
DQ='"'
SQ="'"
QCLASS="${BQ}${DQ}${SQ}"
TOK_HOME='$HOME'
TOK_CSD='${CLAUDE_SKILL_DIR}'
TOK_TILDE='~'

# ---- regexes (built as strings so quote/backtick chars never hit the
#      shell's own command-substitution parsing) ----
RE_INTERP="(^|[[:space:]${BQ}])(python3|python|bash|sh)[[:space:]]+[${QCLASS}]?([^${QCLASS}[:space:]]+\\.(py|sh))"
RE_BACKTICK="${BQ}([^${BQ}[:space:]]+\\.(py|sh))${BQ}"
RE_DOTSLASH="(\\./[A-Za-z0-9_./-]+\\.(py|sh))"
RE_SLASHCMD="(^|[[:space:]${BQ}${DQ}${SQ}(,])/([a-z][a-zA-Z0-9-]+)(\$|[^/])"
RE_SKILLNAME="skill:[[:space:]]*${DQ}([a-zA-Z0-9_-]+)${DQ}"

# ---- textual (never eval'd) path resolution ----
# prints the resolved absolute path on stdout and returns 0, or returns 1
# (no candidate exists) with nothing printed. A path resolved via the
# cwd-relative existence check is printed with a trailing " (cwd-assumed)"
# marker baked into the string.
resolve_path() {
  local raw="$1" skill="$2" filedir="$3"
  case "$raw" in
    "$TOK_HOME"*)
      printf '%s' "$HOME${raw#"$TOK_HOME"}"
      return 0 ;;
    "$TOK_CSD"*)
      printf '%s' "$HOME/.claude/skills/$skill${raw#"$TOK_CSD"}"
      return 0 ;;
    "$TOK_TILDE"/*)
      printf '%s' "$HOME${raw#"$TOK_TILDE"}"
      return 0 ;;
    /*)
      printf '%s' "$raw"
      return 0 ;;
    *)
      # DEFECT 1: cwd-relative — test for existence before giving up.
      # An existence check is evidence, never an invented path: only a
      # candidate that is actually on disk resolves.
      local c1="$HOME/.claude/$raw" c2="$filedir/$raw"
      if [ -f "$c1" ]; then
        printf '%s (cwd-assumed)' "$c1"
        return 0
      elif [ -f "$c2" ]; then
        printf '%s (cwd-assumed)' "$c2"
        return 0
      fi
      return 1 ;;
  esac
}

is_script() {
  case "$1" in
    *.py|*.sh) return 0 ;;
    *) return 1 ;;
  esac
}

# DEFECT 2: a bare "/name" only counts as an invocation when an invocation
# verb sits just before it on the line (run/invoke/call/dispatch/fires/
# routes to) — a "/name" mentioned in prose otherwise is not an invocation.
is_invoked() {
  local prefix_lc
  prefix_lc=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')
  [[ "$prefix_lc" =~ (run|invoke|call|dispatch|fires|routes[[:space:]]to)[^a-z]{0,15}$ ]]
}

# DEFECT 5: a backtick-wrapped "`foo.py`" preceded by "e.g." is a
# documentation example, not a command to run.
is_doc_example() {
  local prefix_lc
  prefix_lc=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')
  [[ "$prefix_lc" =~ e\.g\.[^a-z]{0,5}$ ]]
}

emit() {
  printf '%s|%s|%s|%s\n' "$1" "$2" "$3" "$4"
}

# cycle detection: chain is a newline-delimited string of absolute paths
# already visited on the CURRENT recursion path
in_chain() {
  local path="$1" chain="$2"
  case "$chain" in
    *$'\n'"$path"$'\n'*) return 0 ;;
    *) return 1 ;;
  esac
}

handle_bs() {
  local skill="$1" lineno="$2" raw="$3" depth="$4" chain="$5" filedir="$6"
  local resolved path

  if resolved=$(resolve_path "$raw" "$skill" "$filedir"); then
    # strip the cosmetic " (cwd-assumed)" marker to get the real path for
    # filesystem checks / recursion (DEFECT 1)
    case "$resolved" in
      *" (cwd-assumed)") path="${resolved% (cwd-assumed)}" ;;
      *) path="$resolved" ;;
    esac
    if [ "$depth" -ge "$MAX_DEPTH" ]; then
      emit "$skill" "$lineno" "unresolved" "UNRESOLVED: $resolved (depth-limit reached)"
      return
    fi
    emit "$skill" "$lineno" "bash-script" "$resolved"
    # DEFECT 5: never recurse into this resolver's own source — its
    # pattern-doc comments match its own detection regexes and are noise.
    # $lineno here is the line, in the top-level skill's own SKILL.md, of
    # the ORIGINAL invocation that started this chain — pass it down as
    # the recursed file's origin_lineno so every row it produces (resolved
    # or depth-truncated) cites that same human-visible line, never a
    # local line number from inside the recursed-into script.
    if is_script "$path" && [ -f "$path" ] && [ "$path" != "$SELF_PATH" ] && ! in_chain "$path" "$chain"; then
      scan_file "$skill" "$path" "$((depth + 1))" "${chain}${path}"$'\n' "$lineno"
    fi
  else
    emit "$skill" "$lineno" "unresolved" "UNRESOLVED: $raw"
  fi
}

handle_st() {
  local skill="$1" lineno="$2" name="$3"
  # DEFECT 3: drop self-references — a skill's own SKILL.md mentioning
  # itself is not evidence of an invocation.
  [ "$name" = "$skill" ] && return
  local resolved="$HOME/.claude/skills/$name/SKILL.md"
  # DEFECT 6: a resolved skill-tool target must actually exist on disk.
  if [ -f "$resolved" ]; then
    emit "$skill" "$lineno" "skill-tool" "$resolved"
  else
    emit "$skill" "$lineno" "unresolved" "UNRESOLVED: /$name"
  fi
}

# scan_file skill file depth chain origin_lineno
#
# origin_lineno is the line number, in the top-level skill's own SKILL.md,
# where the invocation chain that led here originally began. At depth 1
# the file being scanned IS that SKILL.md, so each match's own local line
# number is already the origin. At depth > 1 (recursed into a resolved
# script) every match found is still evidence of that SAME original
# invocation — never a new one — so origin_lineno is used verbatim for
# every row emitted from this file, instead of this file's own local line
# counter (DEFECT: chain-derived/depth-truncated rows used to inherit the
# wrong counter and could even land inside frontmatter).
scan_file() {
  local skill="$1" file="$2" depth="$3" chain="$4" origin_lineno="$5"
  [ -f "$file" ] || return 0

  local filedir
  filedir="$(dirname "$file")"

  local lineno=0
  local in_fm=0
  local line rest raw seen full prefix emit_lineno

  while IFS= read -r line || [ -n "$line" ]; do
    lineno=$((lineno + 1))
    if [ "$depth" -eq 1 ]; then
      emit_lineno="$lineno"
    else
      emit_lineno="$origin_lineno"
    fi

    # DEFECT 2: skip YAML frontmatter entirely (opening --- to closing ---)
    # — a skill's own description quoting its trigger is not an invocation.
    if [ "$lineno" -eq 1 ] && [ "$line" = "---" ]; then
      in_fm=1
      continue
    fi
    if [ "$in_fm" -eq 1 ]; then
      [ "$line" = "---" ] && in_fm=0
      continue
    fi

    seen=$'\n'

    # ---- bash-script: interpreter form (python3/python/bash/sh <path>) ----
    rest="$line"
    while [[ "$rest" =~ $RE_INTERP ]]; do
      raw="${BASH_REMATCH[3]}"
      full="${BASH_REMATCH[0]}"
      rest="${rest#*"$full"}"
      case "$seen" in
        *$'\n'"$raw"$'\n'*) : ;;
        *)
          seen="${seen}${raw}"$'\n'
          handle_bs "$skill" "$emit_lineno" "$raw" "$depth" "$chain" "$filedir"
          ;;
      esac
    done

    # ---- bash-script: standalone backtick-wrapped `path.py` / `path.sh` ----
    rest="$line"
    while [[ "$rest" =~ $RE_BACKTICK ]]; do
      raw="${BASH_REMATCH[1]}"
      full="${BASH_REMATCH[0]}"
      prefix="${rest%%"$full"*}"
      rest="${rest#*"$full"}"
      # DEFECT 5: "(e.g. `foo.py`)" is a documentation example, not a command
      if is_doc_example "$prefix"; then
        continue
      fi
      case "$seen" in
        *$'\n'"$raw"$'\n'*) : ;;
        *)
          seen="${seen}${raw}"$'\n'
          handle_bs "$skill" "$emit_lineno" "$raw" "$depth" "$chain" "$filedir"
          ;;
      esac
    done

    # ---- bash-script: explicit direct-exec (./script.sh / ./script.py) ----
    rest="$line"
    while [[ "$rest" =~ $RE_DOTSLASH ]]; do
      raw="${BASH_REMATCH[1]}"
      full="${BASH_REMATCH[0]}"
      rest="${rest#*"$full"}"
      case "$seen" in
        *$'\n'"$raw"$'\n'*) : ;;
        *)
          seen="${seen}${raw}"$'\n'
          handle_bs "$skill" "$emit_lineno" "$raw" "$depth" "$chain" "$filedir"
          ;;
      esac
    done

    # ---- skill-tool: /slash-command form ----
    # DEFECT 2: only a real invocation — "/name" preceded by an invocation
    # verb (run/invoke/call/dispatch/fires/routes to) — not a bare mention.
    rest="$line"
    while [[ "$rest" =~ $RE_SLASHCMD ]]; do
      raw="${BASH_REMATCH[2]}"
      full="${BASH_REMATCH[0]}"
      prefix="${rest%%"$full"*}"
      rest="${rest#*"$full"}"
      if is_invoked "$prefix"; then
        handle_st "$skill" "$emit_lineno" "$raw"
      fi
    done

    # ---- skill-tool: Skill tool, skill: "name" form ----
    rest="$line"
    while [[ "$rest" =~ $RE_SKILLNAME ]]; do
      raw="${BASH_REMATCH[1]}"
      full="${BASH_REMATCH[0]}"
      rest="${rest#*"$full"}"
      handle_st "$skill" "$emit_lineno" "$raw"
    done

  done < "$file"
}

# ---- main ----
# DEFECT 4: dedupe identical skill|lineno|kind|resolved rows before
# printing (first-occurrence order kept; no bash-4 associative arrays).
{
  for md in "$SKILLS_DIR"/*/SKILL.md; do
    [ -f "$md" ] || continue
    skill_name=$(basename "$(dirname "$md")")
    scan_file "$skill_name" "$md" 1 $'\n' ""
  done
} | awk '!seen[$0]++'

exit 0
