#!/usr/bin/env python3
"""
Fetch public-ish golf courses for each US state from OSM via Overpass, normalize, merge.

This does NOT scrape private websites — it uses structured Overpass queries (same as overpass_fetch.py).

Fair use: add delays between states; run overnight for a full national build.

Example:
  python scripts/course-data/ingest_us_public.py --out scripts/course-data/out/courses_us_public.json --delay 45

Optional: limit states for testing:
  python scripts/course-data/ingest_us_public.py --states CA AZ NV --out /tmp/partial.json --delay 10
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
import time
from pathlib import Path
from tempfile import TemporaryDirectory
from typing import Any, Dict, List, Set

ROOT = Path(__file__).resolve().parents[2]


def load_state_bboxes(path: Path) -> Dict[str, Dict[str, float]]:
    with path.open(encoding="utf-8") as f:
        raw = json.load(f)
    out: Dict[str, Dict[str, float]] = {}
    for row in raw["states"]:
        code = row["code"]
        out[code] = {
            "south": float(row["south"]),
            "west": float(row["west"]),
            "north": float(row["north"]),
            "east": float(row["east"]),
        }
    return out


def run(cmd: List[str]) -> None:
    r = subprocess.run(cmd, cwd=str(ROOT))
    if r.returncode != 0:
        sys.exit(r.returncode)


def main() -> None:
    p = argparse.ArgumentParser(description="Ingest US public golf courses (OSM) state by state.")
    p.add_argument("--bboxes", type=str, default=str(ROOT / "scripts/course-data/us_state_bboxes.json"))
    p.add_argument("--out", type=str, required=True)
    p.add_argument("--delay", type=float, default=45.0, help="Seconds between Overpass requests")
    p.add_argument("--states", type=str, default=None, help="Comma-separated state codes (default: all)")
    args = p.parse_args()

    bpath = Path(args.bboxes)
    by_code = load_state_bboxes(bpath)
    if args.states:
        want: Set[str] = {s.strip().upper() for s in args.states.split(",") if s.strip()}
        codes = [c for c in by_code if c in want]
        missing = want - set(codes)
        if missing:
            print("Unknown state codes:", ", ".join(sorted(missing)), file=sys.stderr)
            sys.exit(1)
    else:
        codes = list(by_code.keys())

    if not codes:
        print("No states to fetch.", file=sys.stderr)
        sys.exit(1)

    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    merge_inputs: List[str] = []

    fetch_py = ROOT / "scripts/course-data/overpass_fetch.py"
    norm_py = ROOT / "scripts/course-data/normalize.py"

    with TemporaryDirectory(prefix="fairwayiq_osm_") as tmp:
        tmp_path = Path(tmp)
        for i, code in enumerate(codes):
            bb = by_code[code]
            raw_json = tmp_path / f"raw_{code}.json"
            norm_json = tmp_path / f"norm_{code}.json"
            run(
                [
                    sys.executable,
                    str(fetch_py),
                    "--south",
                    str(bb["south"]),
                    "--west",
                    str(bb["west"]),
                    "--north",
                    str(bb["north"]),
                    "--east",
                    str(bb["east"]),
                    "--out",
                    str(raw_json),
                ]
            )
            run(
                [
                    sys.executable,
                    str(norm_py),
                    "--in",
                    str(raw_json),
                    "--out",
                    str(norm_json),
                    "--public-only",
                ]
            )
            merge_inputs.append(str(norm_json))
            if i < len(codes) - 1:
                time.sleep(max(0.0, args.delay))

        merge_py = ROOT / "scripts/course-data/merge_catalogs.py"
        cmd = [sys.executable, str(merge_py), *merge_inputs, "--out", str(out_path)]
        run(cmd)

    print(f"Done: {out_path}")


if __name__ == "__main__":
    main()
