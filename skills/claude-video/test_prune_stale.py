import datetime
import os
import tempfile
import unittest
from unittest import mock

import prune_stale as ps

TODAY = datetime.date(2026, 10, 2)

PAGE = """---
title: "{title}"
type: source
source_type: video
date_ingested: {date}
raw_path: {raw}
url: https://example.com/{slug}
topics: [{topics}]
---

## Summary

Text.
"""


def make_vault(pages):
    """pages: list of (slug, date, topics, raw_exists, raw_path_value)."""
    root = os.path.join(tempfile.mkdtemp(), "Vault")
    for sub in ("wiki/sources", "raw/videos", "wiki/topics/ai"):
        os.makedirs(os.path.join(root, sub))
    for slug, date, topics, raw_exists, raw in pages:
        raw_value = raw if raw is not None else f"raw/videos/{slug}.md"
        with open(os.path.join(root, "wiki/sources", slug + ".md"), "w") as f:
            f.write(PAGE.format(title=slug, date=date, raw=raw_value, slug=slug, topics=", ".join(topics)))
        if raw_exists:
            with open(os.path.join(root, "raw/videos", slug + ".md"), "w") as f:
                f.write("transcript of " + slug)
    with open(os.path.join(root, "log.md"), "w") as f:
        f.write("# Log\n\n## [2026-09-09] prune | Removed 9 stale video transcripts\n- Deleted earlier.\n")
    return root


OLD = "2026-07-01"
NEW = "2026-09-25"


class Find(unittest.TestCase):
    def test_only_old_tool_only_videos_with_a_raw_file_are_candidates(self):
        root = make_vault([
            ("vid-old-tool", OLD, ["tool-claude-code"], True, None),
            ("vid-old-pattern", OLD, ["pattern-claude-md"], True, None),
            ("vid-old-mixed", OLD, ["tool-mcp", "pattern-rag"], True, None),
            ("vid-new-tool", NEW, ["tool-mcp"], True, None),
            ("vid-old-pruned", OLD, ["tool-mcp"], False, "null  # transcript pruned earlier"),
            ("vid-old-missing-file", OLD, ["tool-mcp"], False, None),
            ("vid-old-no-topics", OLD, [], True, None),
        ])
        found, skipped = ps.candidates(root, TODAY)
        self.assertEqual([c["slug"] for c in found], ["vid-old-tool"])
        self.assertEqual(skipped, [])

    def test_the_day_limit_is_adjustable(self):
        root = make_vault([("vid-a", "2026-09-20", ["tool-mcp"], True, None)])
        self.assertEqual(ps.candidates(root, TODAY, days=30)[0], [])
        self.assertEqual([c["slug"] for c in ps.candidates(root, TODAY, days=7)[0]], ["vid-a"])

    def test_a_raw_file_that_another_page_mentions_is_skipped_and_reported(self):
        root = make_vault([("vid-old-tool", OLD, ["tool-mcp"], True, None)])
        with open(os.path.join(root, "wiki/topics/ai/tool-mcp.md"), "w") as f:
            f.write("See raw/videos/vid-old-tool.md for the evidence.")
        found, skipped = ps.candidates(root, TODAY)
        self.assertEqual(found, [])
        self.assertEqual(skipped[0]["slug"], "vid-old-tool")
        self.assertIn("tool-mcp.md", skipped[0]["why"])


class Apply(unittest.TestCase):
    def setUp(self):
        self.root = make_vault([("vid-a", OLD, ["tool-mcp"], True, None), ("vid-b", OLD, ["tool-claude-code"], True, None),
                                ("vid-keep", OLD, ["pattern-rag"], True, None)])

    def read(self, rel):
        with open(os.path.join(self.root, rel)) as f:
            return f.read()

    def test_a_dry_run_changes_nothing(self):
        before = self.read("log.md")
        ps.run(self.root, TODAY, apply=False)
        self.assertTrue(os.path.exists(os.path.join(self.root, "raw/videos/vid-a.md")))
        self.assertEqual(self.read("log.md"), before)

    def test_apply_backs_up_deletes_nulls_the_path_and_logs(self):
        out = ps.run(self.root, TODAY, apply=True)
        for slug in ("vid-a", "vid-b"):
            self.assertFalse(os.path.exists(os.path.join(self.root, f"raw/videos/{slug}.md")))
            self.assertIn("raw_path: null  # transcript pruned 2026-10-02", self.read(f"wiki/sources/{slug}.md"))
            backup = os.path.join(os.path.dirname(self.root), "backups", "vault-prune-2026-10-02", f"{slug}.md")
            self.assertEqual(open(backup).read(), "transcript of " + slug)
        self.assertTrue(os.path.exists(os.path.join(self.root, "raw/videos/vid-keep.md")))
        log = self.read("log.md")
        self.assertIn("## [2026-10-02] prune | Removed 2 stale video transcripts", log)
        self.assertIn("vid-a", log)
        self.assertIn("Kept all wiki/sources pages", log)
        self.assertIn("Pruned 2", out)

    def test_the_page_keeps_everything_but_the_raw_path(self):
        before = self.read("wiki/sources/vid-a.md")
        ps.run(self.root, TODAY, apply=True)
        after = self.read("wiki/sources/vid-a.md")
        self.assertEqual([l for l in after.splitlines() if not l.startswith("raw_path")],
                         [l for l in before.splitlines() if not l.startswith("raw_path")])

    def test_a_second_run_finds_nothing_and_writes_nothing(self):
        ps.run(self.root, TODAY, apply=True)
        log = self.read("log.md")
        out = ps.run(self.root, TODAY, apply=True)
        self.assertEqual(self.read("log.md"), log)
        self.assertIn("Nothing to prune", out)

    def test_an_existing_log_without_a_final_newline_still_gets_a_clean_entry(self):
        with open(os.path.join(self.root, "log.md"), "w") as f:
            f.write("# Log\n- last line, no newline")
        ps.run(self.root, TODAY, apply=True)
        self.assertIn("- last line, no newline\n\n## [2026-10-02] prune", self.read("log.md"))


class Guards(unittest.TestCase):
    """Each of these is a way a deletion script could remove something it should not."""

    def one(self, raw=None, page_extra=None):
        root = make_vault([("vid-a", OLD, ["tool-mcp"], True, raw)])
        return root

    def test_a_raw_path_outside_raw_videos_is_never_a_candidate(self):
        outside = os.path.join(tempfile.mkdtemp(), "precious.md")
        open(outside, "w").write("do not delete")
        for bad in ("../../outside.md", outside, "raw/articles/vid-a.md", "raw/videos/other-name.md"):
            root = self.one(raw=bad)
            found, skipped = ps.candidates(root, TODAY)
            self.assertEqual(found, [], bad)
            self.assertEqual(len(skipped), 1, bad)
            self.assertIn("raw_path", skipped[0]["why"])
        self.assertTrue(os.path.exists(outside))

    def test_a_symlinked_raw_file_is_skipped(self):
        root = self.one()
        target = os.path.join(tempfile.mkdtemp(), "elsewhere.md")
        open(target, "w").write("elsewhere")
        raw = os.path.join(root, "raw/videos/vid-a.md")
        os.remove(raw)
        os.symlink(target, raw)
        found, skipped = ps.candidates(root, TODAY)
        self.assertEqual(found, [])
        self.assertIn("symlink", skipped[0]["why"])

    def test_a_page_that_is_not_a_video_source_is_never_a_candidate(self):
        root = self.one()
        page = os.path.join(root, "wiki/sources/vid-a.md")
        text = open(page).read().replace("source_type: video", "source_type: article")
        open(page, "w").write(text)
        self.assertEqual(ps.candidates(root, TODAY), ([], []))

    def test_a_link_to_the_raw_file_without_the_extension_also_blocks_it(self):
        root = self.one()
        with open(os.path.join(root, "wiki/topics/ai/tool-mcp.md"), "w") as f:
            f.write("Evidence: [[raw/videos/vid-a]]")
        found, skipped = ps.candidates(root, TODAY)
        self.assertEqual(found, [])
        self.assertIn("tool-mcp.md", skipped[0]["why"])

    def test_a_backup_that_would_overwrite_different_content_stops_everything(self):
        root = make_vault([("vid-a", OLD, ["tool-mcp"], True, None), ("vid-b", OLD, ["tool-mcp"], True, None)])
        backup = os.path.join(os.path.dirname(root), "backups", "vault-prune-2026-10-02")
        os.makedirs(backup)
        open(os.path.join(backup, "vid-b.md"), "w").write("someone else's file")
        page_a = os.path.join(root, "wiki/sources/vid-a.md")
        before = open(page_a).read()
        with self.assertRaises(OSError):
            ps.run(root, TODAY, apply=True)
        self.assertEqual(open(page_a).read(), before)  # nothing was changed
        for slug in ("vid-a", "vid-b"):
            self.assertTrue(os.path.exists(os.path.join(root, f"raw/videos/{slug}.md")))
        self.assertEqual(open(os.path.join(backup, "vid-b.md")).read(), "someone else's file")

    def test_a_backup_is_checked_byte_for_byte(self):
        root = make_vault([("vid-a", OLD, ["tool-mcp"], True, None)])
        real_copy = ps.shutil.copy2

        def lying_copy(src, dst):
            real_copy(src, dst)
            with open(dst, "w") as f:
                f.write("X" * len("transcript of vid-a"))  # same size, different bytes

        with mock.patch.object(ps.shutil, "copy2", lying_copy):
            with self.assertRaises(OSError):
                ps.run(root, TODAY, apply=True)
        self.assertTrue(os.path.exists(os.path.join(root, "raw/videos/vid-a.md")))

    def test_if_the_delete_fails_the_page_goes_back_to_how_it_was(self):
        root = make_vault([("vid-a", OLD, ["tool-mcp"], True, None)])
        page = os.path.join(root, "wiki/sources/vid-a.md")
        before = open(page).read()
        with mock.patch.object(ps.os, "remove", side_effect=PermissionError):
            with self.assertRaises(PermissionError):
                ps.run(root, TODAY, apply=True)
        self.assertEqual(open(page).read(), before)
        self.assertTrue(os.path.exists(os.path.join(root, "raw/videos/vid-a.md")))

    def test_a_symlinked_raw_videos_folder_stops_everything(self):
        root = make_vault([("vid-a", OLD, ["tool-mcp"], True, None)])
        elsewhere = tempfile.mkdtemp()
        os.rename(os.path.join(root, "raw/videos/vid-a.md"), os.path.join(elsewhere, "vid-a.md"))
        os.rmdir(os.path.join(root, "raw/videos"))
        os.symlink(elsewhere, os.path.join(root, "raw/videos"))
        found, skipped = ps.candidates(root, TODAY)
        self.assertEqual(found, [])
        self.assertIn("symlink", skipped[0]["why"])
        ps.run(root, TODAY, apply=True)
        self.assertTrue(os.path.exists(os.path.join(elsewhere, "vid-a.md")))

    def test_a_backup_that_is_a_symlink_stops_everything(self):
        root = make_vault([("vid-a", OLD, ["tool-mcp"], True, None)])
        backup = os.path.join(os.path.dirname(root), "backups", "vault-prune-2026-10-02")
        os.makedirs(backup)
        os.symlink(os.path.join(root, "raw/videos/vid-a.md"), os.path.join(backup, "vid-a.md"))
        with self.assertRaises(OSError):
            ps.run(root, TODAY, apply=True)
        self.assertTrue(os.path.exists(os.path.join(root, "raw/videos/vid-a.md")))

    def test_a_failure_part_way_still_logs_what_was_already_deleted(self):
        root = make_vault([("vid-a", OLD, ["tool-mcp"], True, None), ("vid-b", OLD, ["tool-mcp"], True, None)])
        real_remove = ps.os.remove
        calls = []

        def flaky(path):
            calls.append(path)
            if len(calls) == 2:
                raise PermissionError
            real_remove(path)

        with mock.patch.object(ps.os, "remove", flaky):
            with self.assertRaises(PermissionError):
                ps.run(root, TODAY, apply=True)
        log = open(os.path.join(root, "log.md")).read()
        self.assertIn("Removed 1 stale video transcripts", log)
        self.assertIn("vid-a", log.split("prune | Removed 1")[1])
        self.assertTrue(os.path.exists(os.path.join(root, "raw/videos/vid-b.md")))
        self.assertIn("raw_path: raw/videos/vid-b.md", open(os.path.join(root, "wiki/sources/vid-b.md")).read())

    def test_the_log_is_only_ever_appended_to(self):
        root = make_vault([("vid-a", OLD, ["tool-mcp"], True, None)])
        log = os.path.join(root, "log.md")
        before = open(log).read()
        ps.run(root, TODAY, apply=True)
        self.assertTrue(open(log).read().startswith(before))

    def test_more_than_the_limit_is_not_pruned_automatically(self):
        root = make_vault([(f"vid-{i}", OLD, ["tool-mcp"], True, None) for i in range(ps.MAX_PER_RUN + 1)])
        out = ps.run(root, TODAY, apply=True)
        self.assertIn("none were pruned", out)
        self.assertEqual(len(os.listdir(os.path.join(root, "raw/videos"))), ps.MAX_PER_RUN + 1)
        out = ps.run(root, TODAY, apply=True, limit=ps.MAX_PER_RUN + 1)
        self.assertIn("Pruned", out)


if __name__ == "__main__":
    unittest.main()
