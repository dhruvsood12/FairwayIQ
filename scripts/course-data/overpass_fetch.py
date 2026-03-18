#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import time
from dataclasses import dataclass
from typing import Any, Dict

import requests


OVERPASS_URL = "https://overpass-api.de/api/interpreter"


@dataclass(frozen=True)
class BBox:
    south: float
    west: float
    north: float
    east: float


def build_query(bbox: BBox) -> str:
    # Fetch nodes/ways/relations tagged leisure=golf_course within bbox.
    # We request tags + center for ways/relations.
    return f"""
[out:json][timeout:180];
(
  node["leisure"="golf_course"]({bbox.south},{bbox.west},{bbox.north},{bbox.east});
  way["leisure"="golf_course"]({bbox.south},{bbox.west},{bbox.north},{bbox.east});
  relation["leisure"="golf_course"]({bbox.south},{bbox.west},{bbox.north},{bbox.east});
);
out tags center;
"""


def fetch_overpass(query: str) -> Dict[str, Any]:
    resp = requests.post(OVERPASS_URL, data={"data": query}, timeout=240)
    resp.raise_for_status()
    return resp.json()


def main() -> None:
    p = argparse.ArgumentParser(description="Fetch OSM golf courses via Overpass.")
    p.add_argument("--south", type=float, required=True)
    p.add_argument("--west", type=float, required=True)
    p.add_argument("--north", type=float, required=True)
    p.add_argument("--east", type=float, required=True)
    p.add_argument("--out", type=str, required=True)
    args = p.parse_args()

    bbox = BBox(south=args.south, west=args.west, north=args.north, east=args.east)
    query = build_query(bbox)
    payload = fetch_overpass(query)
    payload["_fairwayiq"] = {
        "provider": "osm",
        "fetchedAt": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "bbox": {"south": bbox.south, "west": bbox.west, "north": bbox.north, "east": bbox.east},
        "overpassUrl": OVERPASS_URL,
    }

    with open(args.out, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=2)


if __name__ == "__main__":
    main()

