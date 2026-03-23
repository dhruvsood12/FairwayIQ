#!/usr/bin/env python3
"""Merge multiple normalized FairwayIQ catalog JSON files; dedupe by course id (last wins)."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any, Dict, List


def load_array(path: Path) -> List[Dict[str, Any]]:
    with path.open(encoding="utf-8") as f:
        data = json.load(f)
    if not isinstance(data, list):
        raise ValueError(f"{path} must be a JSON array")
    return data


def main() -> None:
    p = argparse.ArgumentParser(description="Merge course catalog JSON files by id.")
    p.add_argument("inputs", nargs="+", type=str, help="Normalized JSON files")
    p.add_argument("--out", type=str, required=True)
    args = p.parse_args()

    merged: Dict[str, Dict[str, Any]] = {}
    for raw in args.inputs:
        path = Path(raw)
        for item in load_array(path):
            cid = item.get("id")
            if isinstance(cid, str) and cid:
                merged[cid] = item

    out = list(merged.values())
    out.sort(key=lambda x: (x.get("state") or "", x.get("city") or "", x.get("name") or ""))

    Path(args.out).parent.mkdir(parents=True, exist_ok=True)
    with open(args.out, "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False, indent=2)
    print(f"Wrote {len(out)} courses to {args.out}")


if __name__ == "__main__":
    main()
