#!/usr/bin/env python3
"""The no-yolo installer. Run it through ../install.sh.

Everything it adds is written to ~/.claude/.no-yolo-manifest.json, so a later run can switch modes
and --uninstall can remove exactly that and nothing else.
"""
import argparse
import copy
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import time
from pathlib import Path
from xml.sax.saxutils import escape

REPO = Path(__file__).resolve().parent.parent
HOME = Path.home()
CLAUDE = HOME / ".claude"
MANIFEST = CLAUDE / ".no-yolo-manifest.json"
BACKUPS = CLAUDE / ".no-yolo-backups"
SETTINGS = CLAUDE / "settings.json"
CODEX_RULES = HOME / ".codex/AGENTS.md"
AGENTS_DIR = HOME / "Library/LaunchAgents"
LABELS = ["local.no-yolo.ocr-update", "local.no-yolo.web-guidance-update",
          "local.no-yolo.codex-watchdog", "local.no-yolo.codex-review-cleanup"]
STAMP = time.strftime("%Y%m%d-%H%M%S")

COPY_DIRS = ["skills", "output-styles", "shared"]
HOOKS = ["require-pr.py", "ssh-delete-guard.py", "orca-waiting.py"]
SAFE_TOOLS = ["astryx-version.py", "ocr-review.py"]
FULL_TOOLS = ["orca-sweep.py", "session-tidy.py", "test_session_tidy.py", "reap-codex-orphans.sh",
              "update-ocr.py", "update-web-guidance.py"]
LEFT_OUT = {"__pycache__", ".DS_Store"}

# What older versions of this repo wrote into settings.json before it had a manifest.
OLD_HOOK = "/AI/no-yolo/"
OLD_ALLOW = ["Bash(gh pr:*)", "Bash(gh run:*)", "Bash(gh release:*)", "Bash(gh workflow run:*)",
             "Bash(git tag:*)", "Bash(git push:*)"]

SAFE_RULE = """

## Safe mode (this overrides every rule above and every skill)

This machine uses the no-yolo safe install. Never merge a pull request, create a tag, publish a
release or delete a branch unless the user asks for that specific action in this conversation. Open
the pull request, report its state, and stop there.
"""

problems = []


def say(message=""):
    print(message, flush=True)


def problem(message):
    problems.append(message)
    say(f"Needs attention: {message}")


def digest(data):
    return hashlib.sha256(data).hexdigest()


def file_digest(path):
    try:
        return digest(path.read_bytes())
    except OSError:
        return None


def load_manifest():
    if not MANIFEST.exists():
        return {"version": 1, "files": {}, "backups": {}, "settings": [], "previous": {},
                "launch_agents": {}, "plugins": [], "marketplaces": [], "skills": []}
    return json.loads(MANIFEST.read_text(encoding="utf-8"))


def write_atomic(path, data, mode=None):
    """Replace the file's contents in one step, writing through a symlink rather than over it."""
    target = Path(os.path.realpath(path))
    target.parent.mkdir(parents=True, exist_ok=True)
    temp = target.with_name(f".{target.name}.no-yolo-{os.getpid()}")
    temp.write_bytes(data)
    if mode is not None:
        os.chmod(temp, mode)
    elif target.exists():
        os.chmod(temp, target.stat().st_mode & 0o777)
    os.replace(temp, target)


def save_manifest(manifest):
    write_atomic(MANIFEST, (json.dumps(manifest, indent=2, sort_keys=True) + "\n").encode())


def back_up(path, name, manifest, installed_by_us=False):
    """Save a new copy before overwriting. Uninstall restores only the file from before install."""
    saved = BACKUPS / STAMP / name
    count = 1
    while saved.exists():
        saved = BACKUPS / f"{STAMP}.{count}" / name
        count += 1
    saved.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(path, saved)
    if not installed_by_us:
        manifest["backups"].setdefault(name, str(saved))


def restore(path, name, manifest):
    saved = manifest["backups"].pop(name, None)
    if saved and Path(saved).exists():
        path.parent.mkdir(parents=True, exist_ok=True)
        shutil.move(saved, path)
        say(f"Restored your earlier {name}")


def prune_empty(path, stop):
    parent = path.parent
    while parent != stop and stop in parent.parents:
        try:
            parent.rmdir()
        except OSError:
            return
        parent = parent.parent


# ---------- files ----------

def safe_claude_md(text):
    """Take the merge-without-asking rule out and add the safe-mode rule last."""
    text = re.sub(r"\*\*Merge and release are part of the job.*?\n\n", "", text, count=1, flags=re.S)
    return text.rstrip() + SAFE_RULE


def wanted_files(full):
    """Map each path under ~/.claude to (bytes, file mode)."""
    files = {}

    def add(source, name):
        files[name] = (source.read_bytes(), 0o755 if os.access(source, os.X_OK) else 0o644)

    rules = (REPO / "CLAUDE.md").read_text(encoding="utf-8")
    files["CLAUDE.md"] = ((rules if full else safe_claude_md(rules)).encode(), 0o644)
    add(REPO / "statusline.sh", "statusline.sh")
    files["statusline.sh"] = (files["statusline.sh"][0], 0o755)
    for folder in COPY_DIRS:
        for source in sorted((REPO / folder).rglob("*")):
            if source.is_file() and not LEFT_OUT & set(source.parts):
                add(source, source.relative_to(REPO).as_posix())
    for name in HOOKS:
        add(REPO / "hooks" / name, f"hooks/{name}")
    for name in SAFE_TOOLS + (FULL_TOOLS if full else []):
        add(REPO / "tools" / name, f"tools/{name}")
    files["shared/build-codex-agents.sh"] = (files["shared/build-codex-agents.sh"][0], 0o755)
    return files


def remove_recorded_file(name, manifest):
    path = CLAUDE / name
    recorded = manifest["files"].pop(name)
    if path.exists() and file_digest(path) != recorded:
        say(f"Kept {name}: you changed it after it was installed")
        manifest["backups"].pop(name, None)
        return
    if path.exists():
        path.unlink()
    restore(path, name, manifest)
    if not path.exists():
        prune_empty(path, CLAUDE)


def install_files(full, manifest):
    wanted = wanted_files(full)
    for name in sorted(set(manifest["files"]) - set(wanted)):
        remove_recorded_file(name, manifest)
    for name, (data, mode) in wanted.items():
        path = CLAUDE / name
        now = file_digest(path)
        recorded = manifest["files"].get(name)
        if now and now != digest(data) and now != recorded:
            back_up(path, name, manifest, installed_by_us=recorded is not None)
        if now != digest(data):
            write_atomic(path, data, mode)
        else:
            os.chmod(path, mode)
            if recorded is None:
                continue  # the user already had this exact file, so uninstall must leave it
        manifest["files"][name] = digest(data)
    say(f"Installed {len(wanted)} files into ~/.claude")


# ---------- settings ----------

def template_items(full):
    """Flatten the settings templates into items the merge can add, compare and remove."""
    sources = json.loads((REPO / "installer/sources.json").read_text(encoding="utf-8"))
    layers = [json.loads((REPO / "templates/settings.safe.json").read_text(encoding="utf-8"))]
    if full:
        layers.append(json.loads((REPO / "templates/settings.full.json").read_text(encoding="utf-8")))
    items = []
    for layer in layers:
        for key, value in layer.items():
            if key == "hooks":
                for event, blocks in value.items():
                    for block in blocks:
                        for hook in block["hooks"]:
                            items.append({"kind": "hook", "event": event,
                                          "matcher": block.get("matcher"), "hook": hook})
            elif key == "permissions":
                for field, entry in value.items():
                    if isinstance(entry, list):
                        items.extend({"kind": "list", "path": ["permissions", field], "value": v} for v in entry)
                    else:
                        items.append({"kind": "set", "path": ["permissions", field], "value": entry,
                                      "force": True})
            else:
                items.append({"kind": "set", "path": [key], "value": value})
    for plugin in sources["plugins"]:
        items.append({"kind": "set", "path": ["enabledPlugins", plugin], "value": True})
    for name, entry in sources["marketplaces"].items():
        if name != "claude-plugins-official":
            items.append({"kind": "set", "path": ["extraKnownMarketplaces", name],
                          "value": {"source": {"source": "github", "repo": entry["repo"], "ref": entry["ref"]}}})
    return items


def item_id(item):
    if item["kind"] == "hook":
        return json.dumps(["hook", item["event"], item["hook"]["command"]])
    if item["kind"] == "list":
        return json.dumps(["list", item["path"], item["value"]])
    return json.dumps(["set", item["path"]])


def lookup(settings, path):
    node = settings
    for key in path:
        if not isinstance(node, dict) or key not in node:
            return None, False
        node = node[key]
    return node, True


def place(settings, path, value):
    node = settings
    for key in path[:-1]:
        node = node.setdefault(key, {})
    node[path[-1]] = value


def drop_key(settings, path):
    parents = []
    node = settings
    for key in path[:-1]:
        parents.append((node, key))
        node = node[key]
    node.pop(path[-1], None)
    for parent, key in reversed(parents):
        if parent[key] == {}:
            del parent[key]


def has_hook(settings, event, command):
    return any(hook.get("command") == command
               for block in settings.get("hooks", {}).get(event, [])
               for hook in block.get("hooks", []))


def add_hook(settings, item):
    blocks = settings.setdefault("hooks", {}).setdefault(item["event"], [])
    block = {"hooks": [copy.deepcopy(item["hook"])]}
    if item.get("matcher"):
        block = {"matcher": item["matcher"], **block}
    blocks.append(block)


def remove_hooks(settings, wanted):
    """Remove hook commands for which wanted(event, command) is true, and any block left empty."""
    hooks = settings.get("hooks", {})
    for event in list(hooks):
        kept = []
        for block in hooks[event]:
            block["hooks"] = [h for h in block.get("hooks", []) if not wanted(event, h.get("command", ""))]
            if block["hooks"]:
                kept.append(block)
        if kept:
            hooks[event] = kept
        else:
            del hooks[event]
    if "hooks" in settings and not settings["hooks"]:
        del settings["hooks"]


def remove_item(settings, item, previous):
    if item["kind"] == "hook":
        remove_hooks(settings, lambda event, command: event == item["event"] and command == item["hook"]["command"])
    elif item["kind"] == "list":
        values, found = lookup(settings, item["path"])
        if found and item["value"] in values:
            values.remove(item["value"])
            if not values:
                drop_key(settings, item["path"])
    else:
        value, found = lookup(settings, item["path"])
        if found and value == item["value"]:
            key = ".".join(item["path"])
            if key in previous:
                place(settings, item["path"], previous.pop(key))
            else:
                drop_key(settings, item["path"])


def clear_old_install(settings, full):
    """Move a settings file from before the manifest onto the new paths."""
    commands = [h.get("command", "") for blocks in settings.get("hooks", {}).values()
                for block in blocks for h in block.get("hooks", [])]
    if not any(OLD_HOOK in command for command in commands):
        return
    remove_hooks(settings, lambda _event, command: OLD_HOOK in command)
    permissions = settings.get("permissions")
    if not full and isinstance(permissions, dict):
        allow = [v for v in permissions.get("allow", []) if v not in OLD_ALLOW]
        if allow:
            permissions["allow"] = allow
        else:
            permissions.pop("allow", None)
        if permissions.get("defaultMode") == "auto":
            del permissions["defaultMode"]
    say("Moved settings from an older no-yolo install to the new paths")


def check_settings_readable():
    """Stop before anything changes if the user's settings file cannot be merged."""
    if not SETTINGS.exists():
        return {}
    try:
        settings = json.loads(SETTINGS.read_bytes() or b"{}")
    except ValueError:
        sys.exit(f"{SETTINGS} is not valid JSON, so nothing was changed. Fix it, then run this again.")
    if not isinstance(settings, dict):
        sys.exit(f"{SETTINGS} does not hold a settings object, so nothing was changed.")
    return settings


def merge_settings(full, manifest):
    before_text = SETTINGS.read_bytes() if SETTINGS.exists() else None
    settings = check_settings_readable()
    original = copy.deepcopy(settings)
    clear_old_install(settings, full)

    items = template_items(full)
    wanted = {item_id(item) for item in items}
    previous = manifest["previous"]
    owned = {item_id(item): item for item in manifest["settings"]}
    for key, item in list(owned.items()):
        if key not in wanted:
            remove_item(settings, item, previous)
            del owned[key]

    for item in items:
        key = item_id(item)
        if item["kind"] == "hook":
            if not has_hook(settings, item["event"], item["hook"]["command"]):
                add_hook(settings, item)
                owned[key] = item
        elif item["kind"] == "list":
            values, found = lookup(settings, item["path"])
            if not found:
                values = []
                place(settings, item["path"], values)
            if item["value"] not in values:
                values.append(item["value"])
                owned[key] = item
        else:
            value, found = lookup(settings, item["path"])
            if not found:
                place(settings, item["path"], copy.deepcopy(item["value"]))
                owned[key] = item
            elif item.get("force") and value != item["value"]:
                previous[".".join(item["path"])] = value
                place(settings, item["path"], copy.deepcopy(item["value"]))
                owned[key] = item

    manifest["settings"] = list(owned.values())
    if settings == original and before_text is not None:
        say("Settings already up to date")
        return
    if before_text is not None:
        saved = SETTINGS.with_name(f"settings.json.backup-{STAMP}")
        count = 1
        while saved.exists():
            saved = SETTINGS.with_name(f"settings.json.backup-{STAMP}.{count}")
            count += 1
        saved.write_bytes(before_text)
        say(f"Backed up your settings to {saved}")
    write_atomic(SETTINGS, (json.dumps(settings, indent=2) + "\n").encode())
    say("Merged settings. Your other settings were kept.")


# ---------- helpers on the system ----------

def run(*args, env=None):
    try:
        done = subprocess.run(args, capture_output=True, text=True, timeout=600, env=env)
        return done.returncode, (done.stdout or "") + (done.stderr or "")
    except (OSError, subprocess.TimeoutExpired) as error:
        return 1, str(error)


def install_program(name, apt_name):
    if shutil.which(name):
        return
    for manager, command in (("brew", ["brew", "install", name]),
                             ("apk", ["apk", "add", name]),
                             ("apt-get", ["apt-get", "install", "-y", apt_name])):
        if shutil.which(manager):
            code, _ = run(*command)
            if code != 0 or not shutil.which(name):
                problem(f"could not install {name}. Try: sudo {' '.join(command)}")
            return
    problem(f"could not install {name}: no brew, apk or apt-get here")


def set_secret_guard(manifest):
    hooks_path = str(REPO / "hooks")
    os.chmod(REPO / "hooks/pre-commit", 0o755)
    _, current = run("git", "config", "--global", "--get", "core.hooksPath")
    current = current.strip()
    if current and current != hooks_path:
        problem(f"the secret guard is OFF because git already uses hooks from {current}")
        return
    if not current:
        code, output = run("git", "config", "--global", "core.hooksPath", hooks_path)
        if code != 0:
            problem(f"could not switch on the secret guard: {output.strip()[:160]}")
            return
    manifest["git_hooks_path"] = hooks_path
    if shutil.which("gitleaks"):
        say("Secret guard is ON: every repo here refuses a commit holding a secret")
    else:
        problem("the secret guard is NOT protecting you because gitleaks is missing")


def build_codex_rules(manifest):
    if not shutil.which("codex"):
        return
    before = CODEX_RULES.read_bytes() if CODEX_RULES.exists() else None
    if before is not None and digest(before) != manifest.get("codex_rules"):
        back_up(CODEX_RULES, "codex-AGENTS.md", manifest, installed_by_us="codex_rules" in manifest)
    code, output = run(str(CLAUDE / "shared/build-codex-agents.sh"))
    if code != 0:
        problem(f"could not build the Codex rules: {output.strip()[:160]}")
        return
    manifest["codex_rules"] = file_digest(CODEX_RULES)
    say("Codex now follows the same shared rules")


def install_plugins(manifest):
    sources = json.loads((REPO / "installer/sources.json").read_text(encoding="utf-8"))
    if not shutil.which("claude"):
        say("Claude Code was not found, so plugins will be offered when you first start it")
        return
    _, known = run("claude", "plugin", "marketplace", "list")
    for name, entry in sources["marketplaces"].items():
        if re.search(rf"(?<![\w-]){re.escape(name)}(?![\w-])", known):
            continue
        # Claude Code refuses a ref on its reserved official marketplace, so that entry has none.
        source = f"{entry['repo']}#{entry['ref']}" if "ref" in entry else entry["repo"]
        code, output = run("claude", "plugin", "marketplace", "add", source)
        if code == 0:
            manifest["marketplaces"].append(name)
        else:
            problem(f"could not add plugin source {name}: {output.strip()[:160]}")
    _, installed = run("claude", "plugin", "list")
    for plugin in sources["plugins"]:
        if plugin in installed:
            continue
        code, output = run("claude", "plugin", "install", plugin)
        if code == 0:
            manifest["plugins"].append(plugin)
        else:
            problem(f"could not install plugin {plugin}: {output.strip()[:160]}")
    say("Plugins checked")


def install_skills(manifest):
    sources = json.loads((REPO / "installer/sources.json").read_text(encoding="utf-8"))
    if not shutil.which("npx"):
        problem("Node.js is missing, so the skills from other projects were not installed")
        return
    env = {**os.environ, "DISABLE_TELEMETRY": "1"}
    for skill in sources["skills"]:
        name = skill["name"]
        if (CLAUDE / "skills" / name).exists() or (HOME / ".agents/skills" / name).exists():
            continue
        code, output = run("npx", "-y", sources["skills_cli"], "add", f"{skill['repo']}@{skill['ref']}",
                           "--skill", name, "-g", "-y", env=env)
        if code == 0:
            manifest["skills"].append(name)
        else:
            problem(f"could not install skill {name}: {output.strip()[:160]}")
    say("Skills from other projects checked")


def agent_path():
    folders = []
    for tool in ("node", "npm", "ocr", "git", "python3"):
        found = shutil.which(tool)
        if found:
            folders.append(str(Path(found).parent))
    folders += ["/opt/homebrew/bin", "/usr/local/bin", "/usr/bin", "/bin", "/usr/sbin", "/sbin"]
    return ":".join(dict.fromkeys(folders))


def stop_agent(label):
    run("launchctl", "bootout", f"gui/{os.getuid()}/{label}")


def remove_launch_agents(manifest):
    for label, recorded in list(manifest["launch_agents"].items()):
        path = AGENTS_DIR / f"{label}.plist"
        stop_agent(label)
        if file_digest(path) == recorded:
            path.unlink()
        elif path.exists():
            say(f"Kept {path.name}: you changed it after it was installed")
        del manifest["launch_agents"][label]


def install_launch_agents(manifest):
    if sys.platform != "darwin":
        say("macOS only: scheduled helpers were not set up on this system.")
        return
    python = shutil.which("python3") or sys.executable
    AGENTS_DIR.mkdir(parents=True, exist_ok=True)
    for label in LABELS:
        text = (REPO / "templates" / f"{label}.plist").read_text(encoding="utf-8")
        text = (text.replace("__PYTHON__", escape(python)).replace("__HOME__", escape(str(HOME)))
                .replace("__PATH__", escape(agent_path())))
        path = AGENTS_DIR / f"{label}.plist"
        if path.exists() and label not in manifest["launch_agents"]:
            problem(f"left {path.name} alone because this installer did not create it")
            continue
        write_atomic(path, text.encode(), 0o644)
        manifest["launch_agents"][label] = digest(text.encode())
        stop_agent(label)
        code, output = run("launchctl", "bootstrap", f"gui/{os.getuid()}", str(path))
        if code != 0:
            problem(f"could not start {label}: {output.strip()[:160]}")
    say("Scheduled helpers are set up")


# ---------- the three commands ----------

def install(full):
    CLAUDE.mkdir(parents=True, exist_ok=True)
    manifest = load_manifest()
    check_settings_readable()
    install_files(full, manifest)
    save_manifest(manifest)
    build_codex_rules(manifest)
    install_program("gitleaks", "gitleaks")
    install_program("exiftool", "libimage-exiftool-perl")
    set_secret_guard(manifest)
    install_plugins(manifest)
    install_skills(manifest)
    # Last, because the plugin commands above write their own entries to this file.
    merge_settings(full, manifest)
    save_manifest(manifest)
    if full:
        install_launch_agents(manifest)
    else:
        remove_launch_agents(manifest)
    manifest["mode"] = "full" if full else "safe"
    save_manifest(manifest)
    say()
    say(f"Installed in {'full' if full else 'safe'} mode.")
    if problems:
        say(f"{len(problems)} item(s) need attention (listed above). Run this again after fixing them.")
        return 1
    say("Next: restart Claude Code, then type /fix.")
    return 0


def uninstall():
    if not MANIFEST.exists():
        say("No no-yolo install was recorded here, so nothing was removed.")
        return 0
    manifest = load_manifest()
    remove_launch_agents(manifest)
    if manifest["plugins"] or manifest["marketplaces"]:
        if shutil.which("claude"):
            for plugin in manifest["plugins"]:
                run("claude", "plugin", "uninstall", plugin)
            for name in manifest["marketplaces"]:
                run("claude", "plugin", "marketplace", "remove", name)
        else:
            problem("Claude Code was not found, so recorded plugins were left installed")
    if manifest["skills"]:
        sources = json.loads((REPO / "installer/sources.json").read_text(encoding="utf-8"))
        if shutil.which("npx"):
            env = {**os.environ, "DISABLE_TELEMETRY": "1"}
            for name in manifest["skills"]:
                run("npx", "-y", sources["skills_cli"], "remove", name, "--global", "-y", env=env)
        else:
            problem("Node.js is missing, so recorded skills were left installed")
    if SETTINGS.exists():
        settings = json.loads(SETTINGS.read_text(encoding="utf-8"))
        for item in manifest["settings"]:
            remove_item(settings, item, manifest["previous"])
        saved = SETTINGS.with_name(f"settings.json.backup-{STAMP}")
        shutil.copy2(SETTINGS, saved)
        write_atomic(SETTINGS, (json.dumps(settings, indent=2) + "\n").encode())
    for name in list(manifest["files"]):
        remove_recorded_file(name, manifest)
    if manifest.get("codex_rules") and CODEX_RULES.exists():
        if file_digest(CODEX_RULES) == manifest["codex_rules"]:
            CODEX_RULES.unlink()
            restore(CODEX_RULES, "codex-AGENTS.md", manifest)
        else:
            say("Kept ~/.codex/AGENTS.md: it changed after it was installed")
    recorded_hooks = manifest.get("git_hooks_path")
    if recorded_hooks:
        _, current = run("git", "config", "--global", "--get", "core.hooksPath")
        if current.strip() == recorded_hooks:
            run("git", "config", "--global", "--unset", "core.hooksPath")
    MANIFEST.unlink()
    say("Removed what no-yolo installed. Anything else in ~/.claude was left alone.")
    if BACKUPS.exists():
        say(f"Any copies not restored are in {BACKUPS}")
    return 1 if problems else 0


def main():
    parser = argparse.ArgumentParser(prog="install.sh", description="Install no-yolo for Claude Code.")
    group = parser.add_mutually_exclusive_group()
    group.add_argument("--full", action="store_true", help="also allow merging and releasing, and add upkeep jobs")
    group.add_argument("--uninstall", action="store_true", help="remove only what this installer recorded")
    args = parser.parse_args()
    return uninstall() if args.uninstall else install(args.full)


if __name__ == "__main__":
    sys.exit(main())
