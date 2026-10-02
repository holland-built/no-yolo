import json
import os
import tempfile
import unittest

import rank_entries as re_
from rank_entries import JevFailed

ENTRIES = [
    {"date": "2026-09-20", "title": "Adds a new hook event", "text": "UserPromptSubmit can now add context."},
    {"date": "2026-09-21", "title": "Fixes a typo in the docs", "text": "Corrected a spelling mistake."},
    {"date": "2026-09-22", "title": "Changes how models are named", "text": "Aliases now point at new versions."},
]


def fake(scores):
    """A fake post: scores maps a title word to (score, confidence)."""
    def post(state, questions, check, timeout=0):
        title = state["entry"]["title"]
        for word, (score, conf) in scores.items():
            if word in title:
                return {"rate": {"type": "score", "score": score, "confidence": conf}}
        return {"rate": {"type": "score", "score": 0.0, "confidence": 0.9}}
    return post


class Rank(unittest.TestCase):
    def test_low_scores_are_noise_and_high_ones_are_read(self):
        rows = re_.rank(ENTRIES, "a topic", "a reader", post=fake({"hook": (2.6, 0.9), "typo": (0.1, 0.95), "named": (1.4, 0.8)}))
        verdict = {r["title"]: r["read"] for r in rows}
        self.assertEqual(verdict, {"Adds a new hook event": True, "Fixes a typo in the docs": False,
                                   "Changes how models are named": True})

    def test_an_unsure_answer_is_read_even_when_the_score_is_low(self):
        rows = re_.rank(ENTRIES, "t", "r", post=fake({"typo": (0.2, 0.1)}))
        self.assertTrue([r for r in rows if "typo" in r["title"]][0]["read"])

    def test_an_entry_that_could_not_be_rated_is_read_and_flagged(self):
        def post(state, questions, check, timeout=0):
            if "typo" in state["entry"]["title"]:
                raise JevFailed("HTTP 500")
            return {"rate": {"type": "score", "score": 0.0, "confidence": 0.9}}

        rows = re_.rank(ENTRIES, "t", "r", post=post)
        typo = [r for r in rows if "typo" in r["title"]][0]
        self.assertTrue(typo["read"])
        self.assertIsNone(typo["score"])

    def test_the_report_lists_the_highest_first_and_counts_the_noise(self):
        rows = re_.rank(ENTRIES, "t", "r", post=fake({"hook": (2.6, 0.9), "named": (1.4, 0.8)}))
        text = re_.report(rows)
        self.assertLess(text.index("Adds a new hook event"), text.index("Changes how models are named"))
        self.assertIn("1 of 3 left out", text)

    def test_long_entries_are_cut_before_sending(self):
        seen = []

        def post(state, questions, check, timeout=0):
            seen.append(state["entry"]["text"])
            return {"rate": {"type": "score", "score": 0.0, "confidence": 0.9}}

        re_.rank([{"date": "d", "title": "t", "text": "word " * 2000}], "t", "r", post=post)
        self.assertLessEqual(len(seen[0]), re_.MAX_CHARS)

    def test_the_default_reader_is_generic_when_no_profile_file_exists(self):
        self.assertIn("developer", re_.load_profile("/nonexistent/profile.txt"))

    def test_a_profile_file_replaces_the_default(self):
        with tempfile.NamedTemporaryFile("w", delete=False) as f:
            f.write("Someone who runs Home Assistant.")
        self.assertEqual(re_.load_profile(f.name), "Someone who runs Home Assistant.")
        os.unlink(f.name)

    def test_a_watch_word_keeps_a_low_scoring_entry(self):
        entries = [{"date": "d", "title": "Minor tidy-up", "text": "Renames the settings.json key skillOverrides."}]
        rows = re_.rank(entries, "t", "r", post=fake({}), watch=["skilloverrides"])
        self.assertTrue(rows[0]["read"])
        self.assertIn("watch", rows[0]["why"])

    def test_watch_words_match_case_blind_in_title_or_text(self):
        entries = [{"date": "d", "title": "BREAKING: x", "text": "y"}, {"date": "d", "title": "z", "text": "a Deprecated flag"}]
        rows = re_.rank(entries, "t", "r", post=fake({}), watch=["breaking", "deprecat"])
        self.assertEqual([r["read"] for r in rows], [True, True])

    def test_left_out_entries_show_a_number_and_their_first_line(self):
        rows = re_.rank(ENTRIES, "t", "r", post=fake({"hook": (2.6, 0.9)}), watch=[])
        text = re_.report(rows)
        self.assertIn("#2", text)
        self.assertIn("Corrected a spelling mistake", text)

    def test_default_watch_words_exist_without_a_file(self):
        self.assertIn("breaking", re_.load_watch("/nonexistent/watch.txt"))

    def test_a_watch_file_adds_to_the_defaults(self):
        with tempfile.NamedTemporaryFile("w", delete=False) as f:
            f.write("# my tools\nUserPromptSubmit\n\n")
        words = re_.load_watch(f.name)
        os.unlink(f.name)
        self.assertIn("userpromptsubmit", words)
        self.assertIn("breaking", words)

    def test_a_score_outside_the_scale_is_refused(self):
        with self.assertRaises(ValueError):
            re_.check_score({"score": 9, "confidence": 0.5})


if __name__ == "__main__":
    unittest.main()
