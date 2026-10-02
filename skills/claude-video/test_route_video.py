import os
import tempfile
import unittest

import route_video as rv

SOURCE = """---
title: A video about hooks
type: source
topics: [tool-claude-code]
---

## Summary

Explains how hooks add context.

## Key Claims

- Hooks run before every prompt.
- They can add text.

## Evidence

Long verbatim material that must not be sent.
"""

TOPIC = """---
title: Claude Code Hooks
type: topic
source_count: 3
---

## Overview

How hooks work in Claude Code. They run at set points.

More detail follows here.

## Key Ideas
- x
"""


def make_vault():
    root = tempfile.mkdtemp()
    for domain, name, text in (("ai", "tool-claude-code", TOPIC), ("ai", "pattern-rag", TOPIC.replace("Claude Code Hooks", "RAG patterns")),
                               ("ha", "sun-position", TOPIC.replace("Claude Code Hooks", "Sun position"))):
        os.makedirs(os.path.join(root, "wiki", "topics", domain), exist_ok=True)
        with open(os.path.join(root, "wiki", "topics", domain, name + ".md"), "w") as f:
            f.write(text)
    os.makedirs(os.path.join(root, "wiki", "sources"), exist_ok=True)
    page = os.path.join(root, "wiki", "sources", "vid-hooks.md")
    with open(page, "w") as f:
        f.write(SOURCE)
    return root, page


class Parse(unittest.TestCase):
    def test_the_source_page_gives_title_summary_and_claims_only(self):
        _, page = make_vault()
        src = rv.read_source(page)
        self.assertEqual(src["title"], "A video about hooks")
        self.assertIn("add context", src["summary"])
        self.assertIn("run before every prompt", src["key_claims"])
        self.assertNotIn("verbatim", str(src))
        self.assertEqual(src["tagged"], ["tool-claude-code"])

    def test_the_vault_root_comes_from_the_page_path(self):
        root, page = make_vault()
        self.assertEqual(rv.vault_root(page), root)

    def test_topics_have_an_id_a_title_and_the_first_overview_paragraph(self):
        root, _ = make_vault()
        topics = {t["id"]: t for t in rv.load_topics(root)}
        self.assertEqual(sorted(topics), ["ai/pattern-rag", "ai/tool-claude-code", "ha/sun-position"])
        self.assertEqual(topics["ai/tool-claude-code"]["title"], "Claude Code Hooks")
        self.assertIn("They run at set points", topics["ai/tool-claude-code"]["overview"])
        self.assertNotIn("More detail", topics["ai/tool-claude-code"]["overview"])


class Route(unittest.TestCase):
    def setUp(self):
        self.root, self.page = make_vault()
        self.src = rv.read_source(self.page)
        self.topics = rv.load_topics(self.root)

    def post_with(self, scores, domain=("ai", 0.9), promo=0.1):
        def post(state, questions, check, timeout=0):
            self.assertNotIn("verbatim", str(state))
            answers = {"domain": {"type": "choice", "choice": domain[0], "confidence": domain[1]},
                       "promo": {"type": "noul", "noul": promo}}
            for i, t in enumerate(self.topics):
                answers[f"t{i}"] = {"type": "noul", "noul": scores.get(t["id"], 0.02)}
            return answers
        return post

    def test_topics_above_the_line_are_opened_and_the_rest_counted(self):
        result = rv.route(self.src, self.topics, post=self.post_with({"ai/tool-claude-code": 0.9, "ai/pattern-rag": 0.3}))
        self.assertEqual([t["id"] for t in result["open"]], ["ai/tool-claude-code"])
        self.assertEqual([t["id"] for t in result["maybe"]], ["ai/pattern-rag"])
        self.assertEqual(result["other"], 1)

    def test_the_report_names_domain_promo_and_topics(self):
        result = rv.route(self.src, self.topics, post=self.post_with({"ai/tool-claude-code": 0.9}, promo=0.8))
        text = rv.report(result, self.src)
        self.assertIn("ai", text)
        self.assertIn("tool-claude-code", text)
        self.assertIn("promotional", text.lower())

    def test_a_tagged_topic_that_jev_missed_is_called_out(self):
        result = rv.route(self.src, self.topics, post=self.post_with({}))
        self.assertIn("already tagged", rv.report(result, self.src).lower())

    def test_nothing_matching_is_said_plainly(self):
        result = rv.route(self.src, self.topics, post=self.post_with({}))
        self.assertIn("No topic page", rv.report(result, self.src))

    def test_a_wrongly_shaped_answer_fails_cleanly(self):
        def post(state, questions, check, timeout=0):
            answers = self.post_with({})(state, questions, check)
            answers["t0"] = {"type": "choice", "choice": "ai", "confidence": 0.9}  # a Choice where a Noul belongs
            return answers

        with self.assertRaises(rv.JevFailed):
            rv.route(self.src, self.topics, post=post)

    def test_long_pages_are_sent_in_full_up_to_the_limit(self):
        long_summary = "word " * 500
        src = {"title": "t", "summary": long_summary, "key_claims": "", "tagged": []}
        seen = []

        def post(state, questions, check, timeout=0):
            seen.append(state["source"]["summary"])
            return self.post_with({})(state, questions, check)

        rv.route(src, self.topics, post=post)
        self.assertEqual(seen[0], long_summary)

    def test_one_request_carries_every_question(self):
        calls = []

        def post(state, questions, check, timeout=0):
            calls.append(len(questions))
            return self.post_with({})(state, questions, check)
        rv.route(self.src, self.topics, post=post)
        self.assertEqual(calls, [len(self.topics) + 2])


if __name__ == "__main__":
    unittest.main()
