#!/usr/bin/env bash
# Holds back destructive shell commands so a person confirms them first.
# Wired in settings.json as a PreToolUse hook on Bash.
# Exit 0 lets the command through. Exit 2 returns the message to Claude as a refusal.
set -uo pipefail

if ! command -v jq >/dev/null 2>&1; then
  echo "safety-net could not run: jq is not installed, so no command can be inspected." >&2
  echo "Install jq, or unwire this hook deliberately. A guard that cannot read its input" >&2
  echo "and exits quietly is worse than no guard, because it looks like protection." >&2
  exit 2
fi

raw="$(cat)"
cmd="$(printf '%s' "$raw" | jq -r '.tool_input.command // ""' 2>/dev/null)" || {
  echo "safety-net could not run: the hook input was not readable JSON." >&2
  exit 2
}
[ -z "$cmd" ] && exit 0

block() {
  echo "BLOCKED by safety-net: $1" >&2
  echo "Bring this to the owner with what it would remove, and wait." >&2
  exit 2
}

# EVERY non-option operand of an rm, one per line, whatever order the flags arrived in:
# -rf, -fr, -r -f, -Rf, --recursive --force. Tokenised, so `--` and quotes cannot hide one.
# awk rather than sed: BSD sed on macOS has no \b, which made an earlier version of this
# guard pass everything through while looking correct.
#
# It returns every operand and not the first, because `rm -rf /tmp /etc` put a harmless
# path in front of a protected one and the guard read only as far as /tmp. Found by a
# cross-model review of this file on 2026-08-21, after the single-target version had
# already passed its own tests.
rm_scan() {
  printf '%s' "$1" | tr -d "\"'" | awk '
    BEGIN { seen=0 }
    {
      for (i=1; i<=NF; i++) {
        if (!seen) { if ($i=="rm") seen=1; continue }
        if ($i == "--") continue
        if (substr($i,1,1) == "-") continue
        print $i
      }
    }
  '
}

# True when the segment is a recursive-force rm at all, target or not.
rm_is_force() {
  printf '%s' "$1" | tr -d "\"'" | awk '
    BEGIN { seen=0; rec=0; frc=0 }
    {
      for (i=1; i<=NF; i++) {
        if (!seen) { if ($i=="rm") seen=1; continue }
        if ($i == "--recursive") { rec=1; continue }
        if ($i == "--force")     { frc=1; continue }
        if (substr($i,1,1) == "-") {
          if ($i ~ /[rR]/) rec=1
          if ($i ~ /f/)    frc=1
        }
      }
    }
    END { exit (seen && rec && frc) ? 0 : 1 }
  '
}

# Every segment is checked, not just the first. `rm -rf /tmp && rm -rf /etc` hid its second
# half behind its harmless first half until this split was added.
segments="$(printf '%s' "$cmd" | tr ';&|()\n' '\n')"

while IFS= read -r seg; do
  [ -z "$seg" ] && continue
  case "$seg" in *rm*) ;; *) continue ;; esac

  targets="$(rm_scan "$seg")"
  printf '%s' "$seg" | grep -Eq '(^|[[:space:]])rm([[:space:]]|$)' || continue

  # A recursive-force rm with every flag stripped and no path left is `rm -rf /` or worse.
  if [ -z "$targets" ] && rm_is_force "$seg"; then
    block "a recursive delete with no bounded target"
  fi

  while IFS= read -r t; do
    [ -z "$t" ] && continue

    # Peel every trailing glob and slash until the target stops shrinking, keeping "/"
    # itself, which is the whole point. `rm -rf /*` empties the disk exactly as `rm -rf /`
    # does, and so do `/*/`, `/**` and `/*/*`; each reached the case below as its own
    # literal string and matched no pattern there. One peel handled only the first of them.
    while [ "$t" != "/" ]; do
      case "$t" in
        */|*\*) t="${t%/}"; t="${t%\*}" ;;
        *) break ;;
      esac
      [ -z "$t" ] && t="/" && break
    done

    # SC2088 fires on "~/.claude" below. The tilde is meant to stay unexpanded: $t holds the
    # command's own text, so an unexpanded ~ is exactly what a person typing `rm -rf ~/.claude`
    # produces, and this case has to match that text literally.
    # shellcheck disable=SC2088
    case "$t" in
      "") : ;;
      "/"|"~"|'$HOME'|"$HOME"|'${HOME}')
          block "a recursive delete of the root or home directory" ;;
      "$HOME/.claude"|"~/.claude"|".claude"|"$HOME/.claude-new"|'$HOME/.claude')
          block "a delete of the Claude configuration directory" ;;
      /bin|/etc|/usr|/var|/opt|/sbin|/System|/Library|/Applications|/Users)
          block "a recursive delete of a system directory ($t)" ;;
    esac
  done <<TARGETS
$targets
TARGETS
done <<EOF
$segments
EOF

case "$cmd" in
  *"git push"*"--force"*|*"git push"*" -f "*)
      block "a force push, which rewrites what others have pulled" ;;
  *"git reset --hard"*)
      block "a hard reset, which discards uncommitted work with no undo" ;;
  *"git clean -"*[fdx]*)
      block "git clean, which deletes untracked files permanently" ;;
  *"DROP TABLE"*|*"DROP DATABASE"*|*"TRUNCATE "*)
      block "a destructive database statement" ;;
  *"chmod -R 777"*)
      block "a recursive world-writable permission change" ;;
  *" > /dev/sd"*|*"mkfs"*|*"dd if="*"of=/dev/"*)
      block "a raw write to a block device" ;;
esac

exit 0
