#!/usr/bin/env python3
"""Stop leaked Codex plugin brokers that no review is using.

The Codex plugin starts one detached `app-server-broker.mjs serve` per workspace.
Each one runs `codex app-server`, which keeps every MCP server it ever started.
Brokers are only stopped by the SessionEnd hook, so a killed tab leaks one forever.
Killing an idle broker is safe: the plugin starts a new one on the next review.

A broker counts as busy when either:
- a node process running `codex-companion.mjs` or `stop-review-gate-hook.mjs` works
  in a related folder (its own folder or its --cwd/-C option): the same folder, one
  inside the other, or the same git root. The plugin keys its broker by git root
  (lib/state.mjs) but starts it with the caller's own folder for reviews.
- a client is connected to the broker's socket. An idle broker has one named unix
  socket (the listener); each accepted client adds another with the same name. Its
  pipes to its own `codex app-server` show as unnamed `->0x...` sockets.

Processes are identified by pid, start time and command, so a reused pid is never
signalled.

Usage: python3 -I codex-broker-reaper.py [--dry-run] [--match PREFIX]
"""
import argparse
import os
import re
import signal
import subprocess
import sys
import time
from datetime import datetime

HOME = os.path.expanduser("~")
DEFAULT_MATCH = os.path.join(HOME, ".claude/plugins/cache/openai-codex/codex/")
# A node process running one of these scripts. Shells that only mention the name do not count.
REVIEW_PATTERN = re.compile(r"^(\S*/)?node\s.*/(codex-companion|stop-review-gate-hook)\.mjs(\s|$)")
# The folder option of a review: text after --cwd / --cwd= / -C up to the next " --" or the end.
REVIEW_CWD = re.compile(r"\s(?:--cwd[=\s]|-C\s)(.+?)(?=\s--|$)")
LOG_FILE = os.path.join(HOME, ".claude/state/codex-broker-reaper.log")
LOG_KEEP = 500
GRACE_SECONDS = 5


def broker_pattern(match):
    return re.compile(r"^(\S*/)?node\s+" + re.escape(match)
                      + r"[^ ]*scripts/app-server-broker\.mjs\s+serve\b")


def read_processes():
    """Return {pid: (ppid, pgid, rss_kb, start, command)} for every process."""
    out = subprocess.run(
        ["/bin/ps", "-axo", "pid=,ppid=,pgid=,rss=,lstart=,command="],
        capture_output=True, text=True, check=True,
    ).stdout
    procs = {}
    for line in out.splitlines():
        parts = line.split(None, 9)  # 4 numbers, 5 lstart tokens, command
        if len(parts) < 10:
            continue
        try:
            procs[int(parts[0])] = (int(parts[1]), int(parts[2]), int(parts[3]),
                                    " ".join(parts[4:9]), parts[9])
        except ValueError:
            continue
    return procs


def same(pid, a, b):
    """True when pid is the same process (start time and command) in both snapshots."""
    return pid in a and pid in b and a[pid][3:] == b[pid][3:]


def lsof_fields(args):
    return subprocess.run(["/usr/sbin/lsof", "-a"] + args + ["-Fn"],
                          capture_output=True, text=True).stdout.splitlines()


def working_folders(pids):
    """Return {pid: cwd} using lsof, which keeps spaces in paths intact."""
    if not pids:
        return {}
    folders, current = {}, None
    for line in lsof_fields(["-p", ",".join(str(p) for p in pids), "-d", "cwd"]):
        if line.startswith("p"):
            current = int(line[1:])
        elif line.startswith("n") and current is not None:
            folders[current] = os.path.realpath(line[1:])
    return folders


def has_client(broker):
    """True when more than the listening socket is open under the broker's socket name."""
    named = [line for line in lsof_fields(["-p", str(broker), "-U"])
             if line.startswith("n") and not line.startswith("n->")]
    return len(named) > 1


_git_roots = {}


def git_root(folder):
    if folder not in _git_roots:
        root = folder
        try:
            r = subprocess.run(
                ["/usr/bin/git", "-C", folder, "rev-parse", "--show-toplevel"],
                capture_output=True, text=True, timeout=10,
            )
            if r.returncode == 0 and r.stdout.strip():
                root = os.path.realpath(r.stdout.strip())
        except (OSError, subprocess.SubprocessError):
            pass
        _git_roots[folder] = root
    return _git_roots[folder]


def inside(child, parent):
    return child == parent or child.startswith(parent.rstrip("/") + "/")


def find_brokers(procs, match):
    pattern = broker_pattern(match)
    return [pid for pid, p in procs.items() if pattern.match(p[4])]


def review_folders(procs):
    """Folders of running reviews. None means one could not be read: treat all as busy."""
    pids = [pid for pid, p in procs.items() if REVIEW_PATTERN.match(p[4])]
    cwds = working_folders(pids)
    folders = []
    for pid in pids:
        cwd = cwds.get(pid)
        if cwd is None:
            if pid in read_processes():
                return None
            continue  # exited meanwhile
        folders.append(cwd)
        option = REVIEW_CWD.search(procs[pid][4])
        if option:
            value = option.group(1).strip().strip("'\"")
            folders.append(os.path.realpath(os.path.join(cwd, value)))
    return folders


def review_running(broker_folder, reviews):
    if reviews is None:
        return True
    for folder in reviews:
        if inside(folder, broker_folder) or inside(broker_folder, folder):
            return True
        if git_root(folder) == git_root(broker_folder):
            return True
    return False


def descendants(roots, procs):
    """Every process under any of roots, deepest first."""
    children = {}
    for pid, p in procs.items():
        children.setdefault(p[0], []).append(pid)
    order, stack = [], [(r, 0) for r in roots]
    seen = set(roots)
    while stack:
        pid, depth = stack.pop()
        for child in children.get(pid, []):
            if child not in seen:
                seen.add(child)
                order.append((depth + 1, child))
                stack.append((child, depth + 1))
    return [pid for _, pid in sorted(order, reverse=True)]


def send(pid, sig):
    try:
        os.kill(pid, sig)
    except ProcessLookupError:
        pass


def stop_broker(broker, snap):
    """Stop the broker's tree and process group. Returns (stopped {pid: proc}, killed count)."""
    tracked = {p: snap[p] for p in descendants([broker], snap) + [broker]}
    group_ok = snap[broker][1] == broker  # the broker leads its own process group

    def survivors():
        now = read_processes()
        alive = {p: now[p] for p in tracked if same(p, tracked, now)}
        # late children of anything we track, and members of the broker's group
        for p in descendants(list(alive), now):
            alive.setdefault(p, now[p])
        if group_ok:
            for p, proc in now.items():
                if proc[1] == broker:
                    alive.setdefault(p, proc)
        return now, alive

    now = read_processes()
    for pid in tracked:
        if pid != broker and same(pid, tracked, now):
            send(pid, signal.SIGTERM)
    now = read_processes()
    if group_ok and same(broker, tracked, now):
        try:
            os.killpg(broker, signal.SIGTERM)
        except ProcessLookupError:
            pass
    elif same(broker, tracked, now):
        send(broker, signal.SIGTERM)

    deadline = time.time() + GRACE_SECONDS
    while True:
        now, alive = survivors()
        tracked.update(alive)
        if not alive or time.time() >= deadline:
            break
        time.sleep(0.25)
    for pid in alive:
        if same(pid, alive, read_processes()):
            send(pid, signal.SIGKILL)
    return tracked, len(alive)


def write_log(line):
    os.makedirs(os.path.dirname(LOG_FILE), exist_ok=True)
    try:
        with open(LOG_FILE, encoding="utf-8") as f:
            lines = f.read().splitlines()
    except FileNotFoundError:
        lines = []
    lines = (lines + [line])[-LOG_KEEP:]
    tmp = LOG_FILE + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")
    os.replace(tmp, LOG_FILE)


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--dry-run", action="store_true", help="print what would stop, kill nothing")
    parser.add_argument("--match", default=DEFAULT_MATCH,
                        help="path prefix of app-server-broker.mjs (for tests only)")
    args = parser.parse_args()

    procs = read_processes()
    brokers = find_brokers(procs, args.match)
    broker_dirs = working_folders(brokers)
    reviews = review_folders(procs)

    stopped, skipped, busy, unreadable = [], [], [], []
    stopped_count, rss_kb, killed = 0, 0, 0
    for broker in sorted(brokers):
        folder = broker_dirs.get(broker)
        label = f"{broker} {folder}"
        if folder is None:
            unreadable.append(broker)
            continue
        if review_running(folder, reviews):
            skipped.append(label)
            continue
        snap = read_processes()  # fresh view right before acting
        if not same(broker, procs, snap):
            continue
        if args.dry_run:
            tree = descendants([broker], snap) + [broker]
            print(f"would stop broker {broker} ({folder}): {len(tree)} processes, "
                  f"{sum(snap[p][2] for p in tree) / 1024:.0f} MB"
                  f"{' (client connected: would skip)' if has_client(broker) else ''}")
            for pid in tree:
                print(f"  {pid} {snap[pid][4][:160]}")
            stopped.append(label)
            stopped_count += len(tree)
            rss_kb += sum(snap[p][2] for p in tree)
            continue
        if review_running(folder, review_folders(snap)):  # a review may have just started
            skipped.append(label)
            continue
        if has_client(broker):  # a review is talking to it right now
            busy.append(label)
            continue
        done, k = stop_broker(broker, snap)
        stopped_count += len(done)
        rss_kb += sum(p[2] for p in done.values())
        killed += k
        stopped.append(label)

    line = (f"{datetime.now().isoformat(timespec='seconds')}"
            f"{' DRY-RUN' if args.dry_run else ''}"
            f" stopped={len(stopped)} [{'; '.join(stopped)}]"
            f" skipped_review={len(skipped)} [{'; '.join(skipped)}]"
            f" skipped_busy={len(busy)} [{'; '.join(busy)}]"
            f" processes={stopped_count} killed_after_term={killed}"
            f" freed_mb={rss_kb / 1024:.0f}")
    if reviews is None:
        line += " note=a review folder was unreadable, all brokers kept"
    if unreadable:
        line += f" unreadable_brokers={unreadable}"
    print(line)
    if not args.dry_run:
        write_log(line)
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as exc:  # launchd discards stderr, so crashes go to the capped log
        write_log(f"{datetime.now().isoformat(timespec='seconds')} ERROR {type(exc).__name__}: {exc}")
        sys.exit(1)
