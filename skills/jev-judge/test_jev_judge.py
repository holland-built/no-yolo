import http.client
import http.server
import os
import threading
import unittest
from unittest import mock

import jev_judge
from jev_judge import judge, report

DATA = {"criteria": ["c0", "c1"],
        "a": {"name": "Claude", "claims": {"c0": ["a0"], "c1": ["a1"]}},
        "b": {"name": "Codex", "claims": {"c0": ["b0"], "c1": ["b1"]}}}


def fake(forward, swapped):
    """Fake ask. Each question key is asked twice: first call gets `forward`, second `swapped`."""
    seen = {}

    def ask(state, questions):
        (key,) = questions
        n = seen[key] = seen.get(key, 0) + 1
        return {key: (forward if n == 1 else swapped)[key]}
    return ask


def ans(choice, conf=0.9):
    return {"type": "choice", "choice": choice, "confidence": conf}


def serve(responder):
    """Local server on a free port. Logs the headers of every request, then calls responder(handler)."""
    log = []

    class Handler(http.server.BaseHTTPRequestHandler):
        def handle_any(self):
            log.append(dict(self.headers))
            self.rfile.read(int(self.headers.get("Content-Length", 0)))
            responder(self)
        do_POST = do_GET = handle_any

        def log_message(self, *args):
            pass

    server = http.server.HTTPServer(("127.0.0.1", 0), Handler)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    return server, log


def reply(code, body=b"", location=None):
    def respond(h):
        h.send_response(code)
        if location:
            h.send_header("Location", location)
        h.send_header("Content-Length", str(len(body)))
        h.end_headers()
        h.wfile.write(body)
    return respond


class Judge(unittest.TestCase):
    def test_consistent_picks_count(self):
        # forward X=a so "X" means Claude; swapped X=b so "Y" means Claude
        rows = judge(DATA, fake({"c0": ans("X"), "c1": ans("Y")},
                                {"c0": ans("Y"), "c1": ans("X")}))
        self.assertEqual([r[1] for r in rows], ["a", "b"])

    def test_position_bias_goes_to_user(self):
        # Jev says "X" in both orders: it follows the label, not the claims
        rows = judge(DATA, fake({"c0": ans("X"), "c1": ans("X")},
                                {"c0": ans("X"), "c1": ans("X")}))
        self.assertEqual([r[1] for r in rows], ["ask", "ask"])
        self.assertIn("ask the user", report(DATA, rows))

    def test_low_confidence_goes_to_user(self):
        rows = judge(DATA, fake({"c0": ans("X", 0.4), "c1": ans("X")},
                                {"c0": ans("Y", 0.9), "c1": ans("Y")}))
        self.assertEqual(rows[0][1], "ask")
        self.assertEqual(rows[1][1], "a")

    def test_tie_goes_to_user(self):
        rows = judge(DATA, fake({"c0": ans("X"), "c1": ans("Y")},
                                {"c0": ans("Y"), "c1": ans("X")}))
        self.assertIn("ask the user", report(DATA, rows))

    def test_each_question_sees_only_its_own_claims(self):
        asked = []

        def spy(state, questions):
            asked.append((list(questions), state))
            return {k: ans("neither") for k in questions}

        judge(DATA, spy)
        self.assertEqual(asked[0], (["c0"], {"X": ["a0"], "Y": ["b0"]}))
        self.assertEqual(asked[1], (["c0"], {"X": ["b0"], "Y": ["a0"]}))
        self.assertEqual(asked[2], (["c1"], {"X": ["a1"], "Y": ["b1"]}))

    def test_no_evidence_goes_to_user_and_jev_is_not_asked(self):
        # c1 has no claims on either side. Jev would answer it confidently anyway.
        data = {"criteria": ["c0", "c1"],
                "a": {"name": "Claude", "claims": {"c0": ["a0"]}},
                "b": {"name": "Codex", "claims": {"c0": ["b0"], "c1": []}}}
        seen = []

        def spy(state, questions):
            seen.append(list(questions))
            return {"c0": ans("X" if state["X"] == ["a0"] else "Y")}

        rows = judge(data, spy)
        self.assertEqual([r[1] for r in rows], ["a", "no evidence"])
        self.assertEqual(seen, [["c0"], ["c0"]])
        self.assertIn("no claims from either side", report(data, rows))
        self.assertIn("ask the user", report(data, rows))

    def test_no_evidence_anywhere_makes_no_call(self):
        data = {"criteria": ["c0"], "a": {"name": "Claude", "claims": {}},
                "b": {"name": "Codex", "claims": {}}}

        def never(state, questions):
            raise AssertionError("Jev should not be asked")

        self.assertEqual(judge(data, never)[0][1], "no evidence")

    def test_claims_for_unknown_criterion_are_rejected(self):
        # a typo in the criterion text would otherwise hide the evidence
        data = {"criteria": ["c0"], "a": {"name": "Claude", "claims": {"c-typo": ["a0"]}},
                "b": {"name": "Codex", "claims": {}}}
        with self.assertRaises(ValueError):
            judge(data, lambda state, questions: {})


class Ask(unittest.TestCase):
    """Real HTTP against a local server. The key must never leave, or be printed."""

    def call(self, server, key="secret-key"):
        url = f"http://127.0.0.1:{server.server_port}/"
        with mock.patch.object(jev_judge, "URL", url), \
                mock.patch.dict(os.environ, {"TYPESAFE_API_KEY": key}):
            return jev_judge.ask({"X": ["a"], "Y": ["b"]}, {"c0": {}})

    def test_redirect_does_not_carry_the_key_elsewhere(self):
        other, other_log = serve(reply(200))
        first, first_log = serve(reply(302, location=f"http://127.0.0.1:{other.server_port}/"))
        try:
            self.call(first)
        except Exception:
            pass
        self.assertIn("Authorization", first_log[0])
        self.assertEqual(other_log, [])

    def test_http_error_gives_a_clean_message(self):
        server, _ = serve(reply(500))
        with self.assertRaises(jev_judge.JevFailed) as cm:
            self.call(server)
        self.assertIn("500", str(cm.exception))
        self.assertNotIn("secret-key", str(cm.exception))

    def test_dropped_connection_gives_a_clean_message(self):
        dropped = mock.patch.object(jev_judge.OPENER, "open",
                                    side_effect=http.client.RemoteDisconnected("closed"))
        with dropped, mock.patch.dict(os.environ, {"TYPESAFE_API_KEY": "secret-key"}):
            with self.assertRaises(jev_judge.JevFailed):
                jev_judge.ask({}, {"c0": {}})

    def test_unreadable_answer_gives_a_clean_message(self):
        server, _ = serve(reply(200, b"{}"))
        with self.assertRaises(jev_judge.JevFailed):
            self.call(server)

    def test_key_with_a_line_break_is_refused_and_not_printed(self):
        with self.assertRaises(jev_judge.JevFailed) as cm:
            with mock.patch.dict(os.environ, {"TYPESAFE_API_KEY": "abc\ndef"}):
                jev_judge.ask({}, {})
        self.assertNotIn("abc", str(cm.exception))


if __name__ == "__main__":
    unittest.main()
