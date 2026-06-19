#!/usr/bin/env python3
"""Report Groq Whisper quota: remaining audio seconds today.

Groq free tier: 7,200 audio-seconds/day for whisper-large-v3.
Tracks usage in ~/.config/watch/quota_log.json (date-keyed).

Usage:
  python3 groq_quota.py                     # show today's remaining
  python3 groq_quota.py --log <seconds>     # log usage after a transcription
"""
from __future__ import annotations

import json
import os
import sys
from datetime import date, datetime, timezone
from pathlib import Path

DAILY_LIMIT_SECONDS = 7200  # Groq free tier whisper-large-v3
QUOTA_LOG = Path.home() / ".config" / "watch" / "quota_log.json"
AVG_VIDEO_SECONDS = 600  # 10 min — used for "how many more videos" estimate


def _load_log() -> dict:
    if QUOTA_LOG.exists():
        try:
            return json.loads(QUOTA_LOG.read_text())
        except (json.JSONDecodeError, OSError):
            pass
    return {}


def _save_log(data: dict) -> None:
    QUOTA_LOG.parent.mkdir(parents=True, exist_ok=True)
    QUOTA_LOG.write_text(json.dumps(data, indent=2))


def today_key() -> str:
    return date.today().isoformat()


def log_usage(seconds: float) -> None:
    data = _load_log()
    key = today_key()
    data[key] = round(data.get(key, 0) + seconds, 1)
    _save_log(data)


def get_remaining() -> tuple[float, float]:
    """Return (used_today, remaining_today) in seconds."""
    data = _load_log()
    used = data.get(today_key(), 0.0)
    remaining = max(0.0, DAILY_LIMIT_SECONDS - used)
    return used, remaining


def report(avg_video_len: float = AVG_VIDEO_SECONDS) -> str:
    used, remaining = get_remaining()
    videos_remaining = int(remaining // avg_video_len)
    pct_used = (used / DAILY_LIMIT_SECONDS) * 100

    lines = [
        f"Groq Whisper quota (today {today_key()}):",
        f"  Used:      {used:.0f}s / {DAILY_LIMIT_SECONDS}s  ({pct_used:.1f}%)",
        f"  Remaining: {remaining:.0f}s",
        f"  ~{videos_remaining} more {int(avg_video_len//60)}-min videos today",
        f"  Resets: midnight UTC ({_reset_in()})",
    ]
    return "\n".join(lines)


def _reset_in() -> str:
    now = datetime.now(timezone.utc)
    midnight = datetime(now.year, now.month, now.day, tzinfo=timezone.utc)
    from datetime import timedelta
    next_midnight = midnight + timedelta(days=1)
    delta = next_midnight - now
    h, rem = divmod(int(delta.total_seconds()), 3600)
    m = rem // 60
    return f"{h}h {m}m"


if __name__ == "__main__":
    if "--log" in sys.argv:
        idx = sys.argv.index("--log")
        try:
            secs = float(sys.argv[idx + 1])
        except (IndexError, ValueError):
            print("usage: groq_quota.py --log <seconds>", file=sys.stderr)
            sys.exit(1)
        log_usage(secs)
        print(report())
    else:
        print(report())
