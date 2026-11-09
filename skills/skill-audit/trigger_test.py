#!/usr/bin/env python3
"""Check which skill Claude loads first for each prompt.

Each prompt runs 3 times through `claude -p` inside a fresh copy of a small fake web app.
A prompt passes when at least 2 of 3 runs load one of the skills listed as acceptable.

Runs are kept from changing anything: Bash is blocked and permission mode is "default", so
every file write asks for approval nobody gives. Bash is blocked because an earlier version
let a run copy a real project page into the test folder.

Usage:
  python3 trigger_test.py [queries.json] [--only 3,7,9]

queries.json is a list of {"q": "<prompt>", "ok": ["skill", ...]}.
"""
import json
import os
import select
import shutil
import subprocess
import sys
import tempfile
import time
from concurrent.futures import ThreadPoolExecutor

HERE = os.path.dirname(os.path.abspath(__file__))
FIXTURE = os.path.join(HERE, "trigger-fixture")
MODEL = os.environ.get("TRIGGER_MODEL", "claude-opus-5-5")
MAX_TOOLS = 6      # give up after this many non-skill tool calls
TIMEOUT = 180      # seconds per run


class LimitHit(Exception):
    pass


def first_skill(prompt):
    """Return the first skill loaded, or 'none:<tools used>'."""
    work = tempfile.mkdtemp(prefix="trigger-")
    shutil.copytree(FIXTURE, work, dirs_exist_ok=True)
    # a git repo, like a real project; without one, Claude treats the folder differently
    subprocess.run(["git", "init", "-q"], cwd=work, check=False)
    env = {k: v for k, v in os.environ.items() if k != "CLAUDECODE"}
    cmd = ["claude", "-p", prompt, "--model", MODEL,
           "--output-format", "stream-json", "--verbose", "--include-partial-messages",
           "--permission-mode", "default",
           "--disallowedTools", "Bash", "Agent", "Workflow", "Artifact"]
    p = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, cwd=work, env=env)
    seen, tool, args, buf, t0 = [], None, "", "", time.time()
    try:
        while time.time() - t0 < TIMEOUT:
            ready, _, _ = select.select([p.stdout], [], [], 1)
            if not ready:
                if p.poll() is not None:
                    break
                continue
            chunk = os.read(p.stdout.fileno(), 8192)
            if not chunk:
                break
            buf += chunk.decode("utf-8", "replace")
            while "\n" in buf:
                line, buf = buf.split("\n", 1)
                try:
                    e = json.loads(line)
                except json.JSONDecodeError:
                    continue
                # a usage limit or API error arrives as an error result; the run proves nothing
                if e.get("type") == "result" and e.get("is_error"):
                    raise LimitHit(str(e.get("result"))[:200])
                if e.get("type") != "stream_event":
                    continue
                se = e["event"]
                kind = se.get("type")
                if kind == "content_block_start" and se.get("content_block", {}).get("type") == "tool_use":
                    tool, args = se["content_block"]["name"], ""
                elif kind == "content_block_delta" and tool and se["delta"].get("type") == "input_json_delta":
                    args += se["delta"].get("partial_json", "")
                elif kind == "content_block_stop" and tool:
                    if tool == "Skill":
                        try:
                            return json.loads(args).get("skill", "?").split(":")[-1]
                        except json.JSONDecodeError:
                            return "?"
                    seen.append(tool)
                    tool = None
                    if len(seen) >= MAX_TOOLS:
                        return "none:" + "/".join(seen)
    finally:
        if p.poll() is None:
            p.kill()
            p.wait()
        shutil.rmtree(work, ignore_errors=True)
    return "none:" + ("/".join(seen) or "text")


def main():
    argv = sys.argv[1:]
    only = None
    if "--only" in argv:
        i = argv.index("--only")
        only = {int(x) for x in argv[i + 1].split(",")}
        del argv[i:i + 2]
    path = argv[0] if argv else os.path.join(HERE, "trigger_queries.json")
    queries = json.load(open(path))
    picked = [(i, q) for i, q in enumerate(queries) if only is None or i in only]
    jobs = [(i, q) for i, q in picked for _ in range(3)]
    got = {i: [] for i, _ in picked}
    try:
        with ThreadPoolExecutor(6) as ex:
            for (i, _), r in zip(jobs, ex.map(lambda j: first_skill(j[1]["q"]), jobs)):
                got[i].append(r)
    except LimitHit as err:
        print(f"Stopped: usage limit reached ({err}). Results so far are not valid.")
        sys.exit(2)
    passed = 0
    for i, q in picked:
        ok = sum(g in q["ok"] for g in got[i]) >= 2
        passed += ok
        print(f"{'PASS' if ok else 'FAIL'}  #{i:<2} {[g[:16] for g in got[i]]}  want {q['ok']}  | {q['q'][:60]}")
    print(f"\n{passed}/{len(picked)} passed")


if __name__ == "__main__":
    main()
