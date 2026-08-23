#!/usr/bin/env python3
# Copyright (c) 2026 The UN1CA Project
# SPDX-License-Identifier: GPL-3.0-or-later

"""Audit every Samsung prebuilt source and build a GitHub Actions matrix."""

from __future__ import annotations

import argparse
import json
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET
from dataclasses import dataclass
from pathlib import Path
from typing import Any


FOTA_URL = "https://fota-cloud-dn.ospserver.net/firmware/{csc}/{model}/version.xml"
BUILD_RE = re.compile(r"^[A-Z0-9]+/[A-Z0-9]+/[A-Z0-9]+$")
CSC_RE = re.compile(r"^[A-Z0-9]{3}$")
DEVICE_RE = re.compile(r"^[a-z0-9]+$")
IMEI_RE = re.compile(r"^[0-9]{8,15}$")
MODEL_RE = re.compile(r"^SM-[A-Z0-9]+$")
SERIAL_RE = re.compile(r"^R[A-Z0-9]{10}$")


class AuditError(RuntimeError):
    """Raised for a manifest, repository, or Samsung feed error."""


@dataclass(frozen=True)
class Source:
    device: str
    module: str
    model: str
    csc: str
    credential: str | None
    auto_update: bool
    compatibility_boundary: str
    note: str
    current: str

    @property
    def firmware(self) -> str:
        if not self.credential:
            raise AuditError(f"{self.device}: no FUS credential is configured")
        return f"{self.model}/{self.csc}/{self.credential}"


@dataclass(frozen=True)
class Result:
    source: Source
    latest: str
    android_version: str
    status: str
    error: str = ""


def _required_string(entry: dict[str, Any], field: str, device: str) -> str:
    value = entry.get(field)
    if not isinstance(value, str) or not value.strip():
        raise AuditError(f"{device}: {field!r} must be a non-empty string")
    return value.strip()


def _read_current(prebuilts_dir: Path, device: str) -> str:
    current_path = prebuilts_dir / device / ".current"
    try:
        current = current_path.read_text(encoding="utf-8").strip()
    except OSError as error:
        raise AuditError(f"{device}: cannot read {current_path}: {error}") from error
    if not BUILD_RE.fullmatch(current):
        raise AuditError(f"{device}: invalid firmware string in {current_path}: {current!r}")
    return current


def load_sources(manifest_path: Path, repo_root: Path) -> list[Source]:
    try:
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise AuditError(f"cannot read {manifest_path}: {error}") from error

    if not isinstance(manifest, dict) or manifest.get("schema") != 1:
        raise AuditError(f"{manifest_path}: unsupported or missing schema (expected 1)")
    entries = manifest.get("sources")
    if not isinstance(entries, list) or not entries:
        raise AuditError(f"{manifest_path}: 'sources' must be a non-empty list")

    prebuilts_dir = repo_root / "prebuilts" / "samsung"
    if not prebuilts_dir.is_dir():
        raise AuditError(f"prebuilt root not found: {prebuilts_dir}")

    sources: list[Source] = []
    seen: set[str] = set()
    for position, raw_entry in enumerate(entries, start=1):
        if not isinstance(raw_entry, dict):
            raise AuditError(f"source #{position}: expected an object")

        device = _required_string(raw_entry, "device", f"source #{position}")
        if not DEVICE_RE.fullmatch(device):
            raise AuditError(f"{device}: invalid device identifier")
        if device in seen:
            raise AuditError(f"{device}: duplicate manifest entry")
        seen.add(device)

        module = _required_string(raw_entry, "module", device)
        model = _required_string(raw_entry, "model", device)
        csc = _required_string(raw_entry, "csc", device)
        if not MODEL_RE.fullmatch(model):
            raise AuditError(f"{device}: invalid Samsung model {model!r}")
        if not CSC_RE.fullmatch(csc):
            raise AuditError(f"{device}: invalid CSC {csc!r}")

        credential = raw_entry.get("credential")
        if credential is not None:
            if not isinstance(credential, str) or not (
                IMEI_RE.fullmatch(credential) or SERIAL_RE.fullmatch(credential)
            ):
                raise AuditError(
                    f"{device}: FUS credential must be an 8-15 digit TAC/IMEI "
                    "or an 11-character serial beginning with R"
                )

        auto_update = raw_entry.get("auto_update", credential is not None)
        if not isinstance(auto_update, bool):
            raise AuditError(f"{device}: 'auto_update' must be a boolean")
        if auto_update and credential is None:
            raise AuditError(f"{device}: automatic updates require a FUS credential")

        compatibility_boundary = raw_entry.get("compatibility_boundary", "")
        note = raw_entry.get("note", "")
        if not isinstance(compatibility_boundary, str) or not isinstance(note, str):
            raise AuditError(
                f"{device}: 'compatibility_boundary' and 'note' must be strings"
            )

        device_dir = prebuilts_dir / device
        if not device_dir.is_dir():
            raise AuditError(f"{device}: prebuilt directory not found: {device_dir}")

        sources.append(
            Source(
                device=device,
                module=module,
                model=model,
                csc=csc,
                credential=credential,
                auto_update=auto_update,
                compatibility_boundary=compatibility_boundary.strip(),
                note=note.strip(),
                current=_read_current(prebuilts_dir, device),
            )
        )

    actual_devices = {
        path.name
        for path in prebuilts_dir.iterdir()
        if path.is_dir() and (path / ".current").is_file()
    }
    missing = sorted(actual_devices - seen)
    extra = sorted(seen - actual_devices)
    if missing or extra:
        details = []
        if missing:
            details.append(f"missing from manifest: {', '.join(missing)}")
        if extra:
            details.append(f"not a prebuilt directory: {', '.join(extra)}")
        raise AuditError("manifest coverage mismatch (" + "; ".join(details) + ")")

    return sources


def fetch_latest(source: Source, timeout: float, attempts: int) -> tuple[str, str]:
    url = FOTA_URL.format(
        csc=urllib.parse.quote(source.csc, safe=""),
        model=urllib.parse.quote(source.model, safe=""),
    )
    request = urllib.request.Request(url, headers={"User-Agent": "UN1CA-prebuilt-audit/1"})
    last_error: Exception | None = None

    for attempt in range(1, attempts + 1):
        try:
            with urllib.request.urlopen(request, timeout=timeout) as response:
                payload = response.read()
            root = ET.fromstring(payload)
            returned_model = (root.findtext("./firmware/model") or "").strip()
            returned_csc = (root.findtext("./firmware/cc") or "").strip()
            latest_node = root.find("./firmware/version/latest")
            if returned_model != source.model or returned_csc != source.csc:
                raise AuditError(
                    f"{source.device}: Samsung feed identity mismatch "
                    f"({returned_model}/{returned_csc})"
                )
            if latest_node is None:
                raise AuditError(f"{source.device}: Samsung feed has no latest firmware")
            latest = (latest_node.text or "").strip()
            if not BUILD_RE.fullmatch(latest):
                raise AuditError(
                    f"{source.device}: Samsung feed returned invalid firmware {latest!r}"
                )
            android_version = (latest_node.get("o") or "unknown").strip()
            if not re.fullmatch(r"[0-9]+|unknown", android_version):
                raise AuditError(
                    f"{source.device}: Samsung feed returned invalid Android version "
                    f"{android_version!r}"
                )
            return latest, android_version
        except (AuditError, ET.ParseError, OSError, urllib.error.URLError) as error:
            last_error = error
            if attempt < attempts:
                time.sleep(2 ** (attempt - 1))

    raise AuditError(
        f"{source.device}: failed to query Samsung FOTA after {attempts} attempts: "
        f"{last_error}"
    )


def audit_sources(sources: list[Source], timeout: float, attempts: int) -> list[Result]:
    results: list[Result] = []
    for source in sources:
        try:
            latest, android_version = fetch_latest(source, timeout, attempts)
            current_key = sec_build_key(source.current)
            latest_key = sec_build_key(latest)
            if latest == source.current:
                status = "current"
            elif latest_key < current_key:
                status = "ahead"
            elif latest_key == current_key:
                status = "review"
            elif source.auto_update:
                status = "update"
            else:
                status = "blocked"
            results.append(Result(source, latest, android_version, status))
        except AuditError as error:
            results.append(Result(source, "", "unknown", "error", str(error)))
    return results


def _pda(firmware: str) -> str:
    if not firmware:
        return "-"
    return firmware.split("/", maxsplit=1)[0]


def sec_build_key(firmware: str) -> tuple[str, str, str, str]:
    """Return the chronological Samsung build key used by firmware_utils.sh."""
    pda = _pda(firmware)
    if len(pda) < 4:
        raise AuditError(f"cannot compare Samsung build version {pda!r}")
    return pda[-4], pda[-3], pda[-2], pda[-1]


def print_table(results: list[Result]) -> None:
    rows = [
        (
            result.status.upper(),
            result.source.device,
            f"{result.source.model}/{result.source.csc}",
            _pda(result.source.current),
            _pda(result.latest),
            result.android_version,
            result.source.compatibility_boundary or "-",
        )
        for result in results
    ]
    headers = (
        "STATUS",
        "DEVICE",
        "SOURCE",
        "CURRENT PDA",
        "LATEST PDA",
        "ANDROID",
        "BOUNDARY",
    )
    widths = [
        max(len(headers[index]), *(len(row[index]) for row in rows))
        for index in range(len(headers))
    ]
    print("  ".join(value.ljust(widths[index]) for index, value in enumerate(headers)))
    print("  ".join("-" * width for width in widths))
    for row in rows:
        print("  ".join(value.ljust(widths[index]) for index, value in enumerate(row)))

    update_count = sum(result.status == "update" for result in results)
    blocked_count = sum(result.status == "blocked" for result in results)
    current_count = sum(result.status == "current" for result in results)
    error_count = sum(result.status == "error" for result in results)
    attention_count = sum(result.status in {"ahead", "review"} for result in results)
    print(
        f"\n{len(results)} sources: {update_count} update(s), "
        f"{blocked_count} blocked, {current_count} current, "
        f"{attention_count} attention, {error_count} error(s)"
    )
    for result in results:
        if result.status == "blocked":
            reason = result.source.note or "automatic updates are disabled"
            print(f"BLOCKED {result.source.device}: {reason}", file=sys.stderr)
        elif result.status == "error":
            print(f"ERROR {result.source.device}: {result.error}", file=sys.stderr)
        elif result.status in {"ahead", "review"}:
            print(
                f"{result.status.upper()} {result.source.device}: current="
                f"{result.source.current} latest={result.latest}",
                file=sys.stderr,
            )


def matrix_for(results: list[Result]) -> dict[str, list[dict[str, str]]]:
    include = []
    for result in results:
        if result.status != "update":
            continue
        include.append(
            {
                "module": result.source.module,
                "device": result.source.device,
                "firmware": result.source.firmware,
                "current": result.source.current,
                "latest": result.latest,
                "android_version": result.android_version,
                "compatibility_boundary": result.source.compatibility_boundary,
                "note": result.source.note,
            }
        )
    return {"include": include}


def write_github_output(path: Path, results: list[Result]) -> None:
    matrix = matrix_for(results)
    update_count = len(matrix["include"])
    blocked_count = sum(result.status == "blocked" for result in results)
    error_count = sum(result.status == "error" for result in results)
    attention_count = sum(result.status in {"ahead", "review"} for result in results)
    with path.open("a", encoding="utf-8", newline="\n") as output:
        output.write(f"matrix={json.dumps(matrix, separators=(',', ':'))}\n")
        output.write(f"has_updates={'true' if update_count else 'false'}\n")
        output.write(f"update_count={update_count}\n")
        output.write(f"blocked_count={blocked_count}\n")
        output.write(f"error_count={error_count}\n")
        output.write(f"attention_count={attention_count}\n")


def _markdown(value: str) -> str:
    return value.replace("|", "\\|").replace("\n", " ")


def write_markdown_summary(path: Path, results: list[Result]) -> None:
    with path.open("a", encoding="utf-8", newline="\n") as summary:
        summary.write("## Samsung prebuilt firmware audit\n\n")
        summary.write(
            "| Status | Device | Source | Current | Latest | Android | Boundary |\n"
        )
        summary.write("| --- | --- | --- | --- | --- | --- | --- |\n")
        for result in results:
            summary.write(
                "| {status} | `{device}` | `{model}/{csc}` | `{current}` | "
                "`{latest}` | {android} | {track} |\n".format(
                    status=result.status.upper(),
                    device=_markdown(result.source.device),
                    model=_markdown(result.source.model),
                    csc=_markdown(result.source.csc),
                    current=_markdown(result.source.current),
                    latest=_markdown(result.latest),
                    android=_markdown(result.android_version),
                    track=_markdown(result.source.compatibility_boundary or "—"),
                )
            )
        blocked = [result for result in results if result.status == "blocked"]
        if blocked:
            summary.write("\n### Blocked sources\n\n")
            for result in blocked:
                reason = result.source.note or "automatic updates are disabled"
                summary.write(f"- `{result.source.device}`: {_markdown(reason)}\n")
        errors = [result for result in results if result.status == "error"]
        if errors:
            summary.write("\n### Feed errors\n\n")
            for result in errors:
                summary.write(f"- `{result.source.device}`: {_markdown(result.error)}\n")
        notes = [result for result in results if result.source.note]
        if notes:
            summary.write("\n### Source notes\n\n")
            for result in notes:
                summary.write(
                    f"- `{result.source.device}`: {_markdown(result.source.note)}\n"
                )


def parse_args() -> argparse.Namespace:
    repo_root = Path(__file__).resolve().parents[2]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--manifest",
        type=Path,
        default=repo_root / "prebuilts" / "samsung" / "sources.json",
        help="prebuilt source manifest (default: prebuilts/samsung/sources.json)",
    )
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=repo_root,
        help="UN1CA repository root",
    )
    parser.add_argument("--timeout", type=float, default=20.0, help="HTTP timeout in seconds")
    parser.add_argument("--attempts", type=int, default=3, help="Samsung feed attempts")
    parser.add_argument(
        "--validate-only",
        action="store_true",
        help="validate manifest coverage without querying Samsung",
    )
    parser.add_argument(
        "--github-output",
        type=Path,
        help="append the update matrix to a GitHub Actions output file",
    )
    parser.add_argument(
        "--markdown-summary",
        type=Path,
        help="append an audit table to a Markdown or GitHub Actions summary file",
    )
    parser.add_argument(
        "--json-output",
        type=Path,
        help="write the complete audit result as JSON",
    )
    return parser.parse_args()


def result_as_dict(result: Result) -> dict[str, Any]:
    return {
        "status": result.status,
        "device": result.source.device,
        "module": result.source.module,
        "model": result.source.model,
        "csc": result.source.csc,
        "auto_update": result.source.auto_update,
        "current": result.source.current,
        "latest": result.latest,
        "android_version": result.android_version,
        "compatibility_boundary": result.source.compatibility_boundary or None,
        "note": result.source.note or None,
        "error": result.error or None,
    }


def main() -> int:
    args = parse_args()
    if args.timeout <= 0:
        raise AuditError("--timeout must be greater than zero")
    if args.attempts <= 0:
        raise AuditError("--attempts must be greater than zero")

    repo_root = args.repo_root.resolve()
    manifest_path = args.manifest.resolve()
    sources = load_sources(manifest_path, repo_root)
    if args.validate_only:
        print(f"Validated {len(sources)} prebuilt sources in {manifest_path}")
        return 0

    results = audit_sources(sources, args.timeout, args.attempts)
    print_table(results)

    if args.github_output:
        write_github_output(args.github_output, results)
    if args.markdown_summary:
        write_markdown_summary(args.markdown_summary, results)
    if args.json_output:
        args.json_output.write_text(
            json.dumps([result_as_dict(result) for result in results], indent=2) + "\n",
            encoding="utf-8",
            newline="\n",
        )
    error_count = sum(result.status == "error" for result in results)
    if error_count:
        raise AuditError(f"{error_count} Samsung firmware feed query failed")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AuditError as error:
        print(f"error: {error}", file=sys.stderr)
        raise SystemExit(2) from error
