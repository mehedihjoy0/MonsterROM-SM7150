#!/usr/bin/env python3
# Copyright (c) 2026 The UN1CA Project
# SPDX-License-Identifier: GPL-3.0-or-later

from __future__ import annotations

import sys
import unittest
from pathlib import Path
from unittest import mock


INTERNAL_DIR = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(INTERNAL_DIR))

import check_prebuilt_updates as audit  # noqa: E402


CURRENT = "S711BXXSFFZD2/S711BOXMFFZD2/S711BXXSFFZD2"
NEWER = "S711BXXSHGZG1/S711BOXMHGZG1/S711BXXSHGZG1"
OLDER = "S711BXXSEFZC1/S711BOXMEFZC1/S711BXXSEFZC1"


def make_source(*, current: str = CURRENT, auto_update: bool = True) -> audit.Source:
    return audit.Source(
        device="r11sxxx",
        module="Galaxy S23 FE (r11sxxx)",
        model="SM-S711B",
        csc="EUX",
        credential="358615311234564" if auto_update else None,
        auto_update=auto_update,
        compatibility_boundary="One UI 8.5",
        note="",
        current=current,
    )


def audit_one(source: audit.Source, latest: str) -> audit.Result:
    with mock.patch.object(audit, "fetch_latest", return_value=(latest, "16")):
        return audit.audit_sources([source], timeout=1, attempts=1)[0]


class BuildComparisonTests(unittest.TestCase):
    def test_newer_feed_is_scheduled(self) -> None:
        result = audit_one(make_source(), NEWER)
        self.assertEqual(result.status, "update")
        self.assertEqual(audit.matrix_for([result])["include"][0]["latest"], NEWER)

    def test_newer_feed_without_credential_is_blocked(self) -> None:
        result = audit_one(make_source(auto_update=False), NEWER)
        self.assertEqual(result.status, "blocked")
        self.assertEqual(audit.matrix_for([result]), {"include": []})

    def test_exact_triplet_is_current(self) -> None:
        result = audit_one(make_source(), CURRENT)
        self.assertEqual(result.status, "current")
        self.assertEqual(audit.matrix_for([result]), {"include": []})

    def test_older_feed_is_never_scheduled(self) -> None:
        result = audit_one(make_source(), OLDER)
        self.assertEqual(result.status, "ahead")
        self.assertEqual(audit.matrix_for([result]), {"include": []})

    def test_equal_build_key_with_different_triplet_requires_review(self) -> None:
        latest = "S711BXXSFFZD2/S711BODMFFZD2/S711BXXSFFZD1"
        result = audit_one(make_source(), latest)
        self.assertEqual(result.status, "review")
        self.assertEqual(audit.matrix_for([result]), {"include": []})

    def test_build_key_matches_repository_ordering(self) -> None:
        self.assertLess(audit.sec_build_key(CURRENT), audit.sec_build_key(NEWER))
        self.assertGreater(audit.sec_build_key(CURRENT), audit.sec_build_key(OLDER))


class CredentialValidationTests(unittest.TestCase):
    def test_downloader_credential_shapes(self) -> None:
        self.assertRegex("352404911234563", audit.IMEI_RE)
        self.assertRegex("12345678", audit.IMEI_RE)
        self.assertRegex("R52Y8065XJM", audit.SERIAL_RE)
        self.assertIsNone(audit.IMEI_RE.fullmatch("R52Y8065XJM"))
        self.assertIsNone(audit.SERIAL_RE.fullmatch("352404911234563"))
        self.assertIsNone(audit.IMEI_RE.fullmatch("1234567"))
        self.assertIsNone(audit.SERIAL_RE.fullmatch("A52Y8065XJM"))


if __name__ == "__main__":
    unittest.main()
