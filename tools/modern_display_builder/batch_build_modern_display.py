#!/usr/bin/env python3
"""Batch generate and merge official modern display mappings."""

from __future__ import annotations

import argparse
import datetime as _dt
import json
import sys
from pathlib import Path
from typing import Any
from urllib.error import HTTPError, URLError

import extract_modern_display as extractor


SCHEMA = "xt.modern_display.v1"
DEFAULT_MANIFEST = Path("tools/modern_display_builder/characters.json")
DEFAULT_CANDIDATE_DIR = Path("tools/modern_display_builder/out")
DEFAULT_FORMAL_DIR = Path("data/TrainingComboTrials_data/modern_display")
DEFAULT_DOCS_DIR = Path("docs")


def action_keys(mapping: dict[str, Any]) -> set[str]:
    return {key for key in mapping if key != "_meta" and str(key).isdigit()}


def sorted_action_ids(values: set[str] | list[str]) -> list[str]:
    return sorted(values, key=lambda value: int(value))


def read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, data: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def append_note(entry: dict[str, Any], text: str) -> None:
    current = str(entry.get("note") or "").strip()
    if text in current:
        return
    entry["note"] = (current + " " + text).strip() if current else text


def merge_candidate(
    character: str,
    candidate: dict[str, Any],
    current: dict[str, Any] | None,
) -> tuple[dict[str, Any], dict[str, Any]]:
    candidate_ids = action_keys(candidate)
    current_ids = action_keys(current or {})

    before_count = len(current_ids)
    added: list[str] = []
    conflicts: list[tuple[str, Any, Any]] = []
    official_missing = sorted_action_ids(current_ids - candidate_ids)

    if current:
        merged = json.loads(json.dumps(current, ensure_ascii=False))
        meta = merged.setdefault("_meta", {})
        meta["schema"] = SCHEMA
        meta["character"] = character
        meta["updated_at"] = _dt.date.today().isoformat()
        meta.setdefault("description", f"Modern control display mapping for {character}")
    else:
        merged = {
            "_meta": {
                "schema": SCHEMA,
                "character": character,
                "updated_at": _dt.date.today().isoformat(),
                "description": f"Modern control display mapping for {character}",
            }
        }

    for action_id in sorted_action_ids(candidate_ids):
        candidate_entry = candidate[action_id]
        if action_id not in current_ids:
            merged[action_id] = candidate_entry
            added.append(action_id)
            continue

        existing_entry = merged[action_id]
        existing_display = existing_entry.get("modern_display")
        candidate_display = candidate_entry.get("modern_display")
        if existing_display != candidate_display:
            conflicts.append((action_id, existing_display, candidate_display))
            append_note(
                existing_entry,
                "Official candidate differs: "
                f"{candidate_display}. Current display kept because existing mapping may be sample/manual verified.",
            )

    ordered: dict[str, Any] = {"_meta": merged.get("_meta", {})}
    for action_id in sorted_action_ids(action_keys(merged)):
        ordered[action_id] = merged[action_id]

    classic_only = [
        key for key in action_keys(ordered)
        if isinstance(ordered.get(key), dict) and ordered[key].get("control_support") == "classic_only"
    ]
    needs_review = [
        key for key in action_keys(candidate)
        if "Needs review" in str(candidate[key].get("note") or "")
    ]

    summary = {
        "before_count": before_count,
        "candidate_count": len(candidate_ids),
        "after_count": len(action_keys(ordered)),
        "added": added,
        "classic_only": sorted_action_ids(classic_only),
        "conflicts": conflicts,
        "official_missing": official_missing,
        "needs_review": sorted_action_ids(set(needs_review + classic_only)),
        "created_formal": current is None,
    }
    return ordered, summary


def markdown_list(values: list[Any]) -> str:
    if not values:
        return "- None\n"
    return "".join(f"- `{value}`\n" for value in values)


def fmt_cell(value: Any) -> str:
    if value is None:
        return "null"
    return str(value).replace("|", "\\|")


def write_character_report(
    character: str,
    manifest_entry: dict[str, Any],
    report_path: Path,
    summary: dict[str, Any] | None,
    error: str | None,
) -> None:
    lines = [
        f"# {character} Official Modern Display Diff\n",
        "\n",
        "## Source\n",
        "\n",
        f"- URL: {manifest_entry.get('url', '')}\n",
        f"- Official name: `{manifest_entry.get('official_name', '')}`\n",
        f"- Success: {'yes' if summary and not error else 'no'}\n",
    ]
    if error:
        lines.append("- Error: " + error + "\n")

    if not summary:
        report_path.parent.mkdir(parents=True, exist_ok=True)
        report_path.write_text("".join(lines), encoding="utf-8")
        return

    lines.extend([
        "\n",
        "## Summary\n",
        "\n",
        f"- Official candidate action_id count: {summary['candidate_count']}\n",
        f"- Formal action_id count before merge: {summary['before_count']}\n",
        f"- Formal action_id count after merge: {summary['after_count']}\n",
        f"- Added action_id count: {len(summary['added'])}\n",
        f"- classic_only action_id count: {len(summary['classic_only'])}\n",
        f"- modern_display conflict count: {len(summary['conflicts'])}\n",
        f"- Needs manual review action_id count: {len(summary['needs_review'])}\n",
        "\n",
        "## Added Official Action IDs\n",
        "\n",
        markdown_list(summary["added"]),
        "\n",
        "## Official Candidate Missing But Formal Mapping Kept\n",
        "\n",
        markdown_list(summary["official_missing"]),
        "\n",
        "## Modern Display Conflicts Kept From Formal Mapping\n",
        "\n",
    ])
    if summary["conflicts"]:
        lines.extend(["| action_id | formal | official candidate |\n", "| --- | --- | --- |\n"])
        for action_id, existing, candidate in summary["conflicts"]:
            lines.append(f"| `{action_id}` | `{fmt_cell(existing)}` | `{fmt_cell(candidate)}` |\n")
    else:
        lines.append("- None\n")

    lines.extend([
        "\n",
        "## Classic Only Action IDs\n",
        "\n",
        markdown_list(summary["classic_only"]),
        "\n",
        "## Needs Manual Review\n",
        "\n",
        markdown_list(summary["needs_review"]),
    ])
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text("".join(lines), encoding="utf-8")


def build_candidate(character: str, entry: dict[str, Any], candidate_dir: Path) -> dict[str, Any]:
    url = entry.get("url")
    official_name = entry.get("official_name") or character
    chunk_text, source_chunk = extractor.load_source_text(url, None)
    modules = extractor.parse_json_modules(chunk_text)
    char_map = extractor.parse_character_var_map(chunk_text)
    var_name = char_map.get(official_name)
    if not var_name:
        raise RuntimeError(f"Could not resolve character variable for {character} ({official_name}).")
    data = modules.get(var_name)
    if not isinstance(data, dict) or not isinstance(data.get("frame"), list):
        raise RuntimeError(f"Frame data for {character} was not found in parsed modules.")

    candidate = extractor.build_candidate(character, url, source_chunk, data["frame"])
    candidate["_meta"]["character"] = character
    candidate_path = candidate_dir / f"{character}.official.generated.json"
    write_json(candidate_path, candidate)
    return candidate


def write_total_report(path: Path, results: list[dict[str, Any]]) -> None:
    success = [r for r in results if r.get("status") == "success"]
    failed = [r for r in results if r.get("status") != "success"]
    classic_only_total = sum(r.get("classic_only_count", 0) for r in success)
    conflict_total = sum(r.get("conflict_count", 0) for r in success)

    lines = [
        "# Modern Display All Characters Batch Report\n",
        "\n",
        f"- Generated at: {_dt.date.today().isoformat()}\n",
        f"- Successful characters: {len(success)}\n",
        f"- Failed / skipped characters: {len(failed)}\n",
        f"- classic_only total: {classic_only_total}\n",
        f"- conflict total: {conflict_total}\n",
        "- Lua changed: no\n",
        "- Validator / ActionMatcher / PendingAbsorb changed: no\n",
        "- timeline changed: no\n",
        "- auto demo changed: no\n",
        "- recorder main flow changed: no\n",
        "\n",
        "## Character Summary\n",
        "\n",
        "| Character | Status | Candidate IDs | Formal IDs | classic_only | Conflicts | Formal table |\n",
        "| --- | --- | ---: | ---: | ---: | ---: | --- |\n",
    ]
    for result in results:
        lines.append(
            f"| {result['character']} | {result['status']} | "
            f"{result.get('candidate_count', 0)} | {result.get('formal_count', 0)} | "
            f"{result.get('classic_only_count', 0)} | {result.get('conflict_count', 0)} | "
            f"{'yes' if result.get('formal_written') else 'no'} |\n"
        )

    lines.extend(["\n", "## Failure / Skipped Reasons\n", "\n"])
    if failed:
        for result in failed:
            lines.append(f"- {result['character']}: {result.get('error', 'unknown error')}\n")
    else:
        lines.append("- None\n")

    lines.extend([
        "\n",
        "## Community Follow-Up\n",
        "\n",
        "- Official data is a baseline. Community modern samples are still needed for contextual follow-ups, automatic derivations, and action IDs absent from public official frame data.\n",
        "- `classic_only` and `Needs review` entries should be prioritized for manual verification before using them as polished modern display mappings.\n",
    ])
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("".join(lines), encoding="utf-8")


def run(args: argparse.Namespace) -> int:
    manifest = read_json(Path(args.manifest))
    candidate_dir = Path(args.candidate_dir)
    formal_dir = Path(args.formal_dir)
    docs_dir = Path(args.docs_dir)

    selected = args.character
    if selected:
        if selected not in manifest:
            raise RuntimeError(f"Character {selected} not found in manifest.")
        items = [(selected, manifest[selected])]
    else:
        items = sorted(manifest.items())

    results: list[dict[str, Any]] = []
    for character, entry in items:
        print(f"[{character}] build begin")
        character_report = docs_dir / f"modern_display_{character}_official_diff.md"
        result: dict[str, Any] = {"character": character, "status": "success"}
        try:
            candidate = build_candidate(character, entry, candidate_dir)
            candidate_count = len(action_keys(candidate))
            result["candidate_count"] = candidate_count
            if candidate_count == 0:
                raise RuntimeError("Official candidate has zero action IDs; formal mapping was not generated.")

            formal_path = formal_dir / f"{character}.json"
            current = read_json(formal_path) if formal_path.exists() else None
            merged, summary = merge_candidate(character, candidate, current)
            write_json(formal_path, merged)
            write_character_report(character, entry, character_report, summary, None)

            result.update({
                "formal_count": summary["after_count"],
                "classic_only_count": len(summary["classic_only"]),
                "conflict_count": len(summary["conflicts"]),
                "formal_written": True,
                "created_formal": summary["created_formal"],
                "added_count": len(summary["added"]),
            })
            print(
                f"[{character}] candidate={candidate_count} formal={summary['after_count']} "
                f"classic_only={len(summary['classic_only'])} conflicts={len(summary['conflicts'])}"
            )
        except (RuntimeError, OSError, HTTPError, URLError, json.JSONDecodeError) as exc:
            result["status"] = "failed"
            result["error"] = str(exc)
            result.setdefault("candidate_count", 0)
            result["formal_written"] = False
            write_character_report(character, entry, character_report, None, str(exc))
            print(f"[{character}] failed: {exc}", file=sys.stderr)
        results.append(result)

    if not selected:
        write_total_report(docs_dir / "modern_display_all_characters_batch_report.md", results)

    failed = [r for r in results if r.get("status") != "success"]
    print(f"success={len(results) - len(failed)} failed={len(failed)}")
    return 0 if len(results) - len(failed) > 0 else 2


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Batch build and merge Capcom official modern display mappings.")
    parser.add_argument("--manifest", default=str(DEFAULT_MANIFEST), help="Character manifest JSON")
    parser.add_argument("--character", help="Optional single formal character name from the manifest")
    parser.add_argument("--candidate-dir", default=str(DEFAULT_CANDIDATE_DIR), help="Generated candidate output directory")
    parser.add_argument("--formal-dir", default=str(DEFAULT_FORMAL_DIR), help="Formal modern_display output directory")
    parser.add_argument("--docs-dir", default=str(DEFAULT_DOCS_DIR), help="Diff and batch report output directory")
    args = parser.parse_args(argv)

    try:
        return run(args)
    except RuntimeError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
