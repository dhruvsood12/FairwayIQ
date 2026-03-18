#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import re
from dataclasses import dataclass
from typing import Any, Dict, List, Optional, Tuple


KIND_MAP = {
    "public": "Public",
    "private": "Private",
    "resort": "Resort",
    "municipal": "Municipal",
}


def norm_space(s: str) -> str:
    return re.sub(r"\s+", " ", s).strip()


def canonical_website(tags: Dict[str, Any]) -> Optional[str]:
    for key in ("website", "contact:website", "url"):
        v = tags.get(key)
        if isinstance(v, str) and v.strip():
            v = v.strip()
            if v.startswith("http://") or v.startswith("https://"):
                return v
            return "https://" + v
    return None


def infer_kind(tags: Dict[str, Any]) -> Optional[str]:
    # OSM can have access=private/public, or operator:type, or description text.
    access = (tags.get("access") or "").lower()
    if access in ("private", "no"):
        return "Private"
    if access in ("yes", "permissive"):
        return "Public"

    leisure = (tags.get("sport") or "").lower()
    _ = leisure
    raw = " ".join(
        [
            str(tags.get("operator:type") or ""),
            str(tags.get("ownership") or ""),
            str(tags.get("description") or ""),
        ]
    ).lower()
    for k, v in KIND_MAP.items():
        if k in raw:
            return v
    return None


def pick_city_state(tags: Dict[str, Any]) -> Tuple[str, str]:
    city = tags.get("addr:city") or tags.get("is_in:city") or tags.get("city")
    state = tags.get("addr:state") or tags.get("is_in:state") or tags.get("state")

    city_s = norm_space(city) if isinstance(city, str) and city.strip() else "Unknown"
    state_s = norm_space(state) if isinstance(state, str) and state.strip() else "Unknown"
    return city_s, state_s


def center_lat_lon(element: Dict[str, Any]) -> Tuple[Optional[float], Optional[float]]:
    if "lat" in element and "lon" in element:
        return element.get("lat"), element.get("lon")
    center = element.get("center")
    if isinstance(center, dict):
        return center.get("lat"), center.get("lon")
    return None, None


@dataclass(frozen=True)
class NormalizedCourse:
    id: str
    name: str
    city: str
    state: str
    kind: Optional[str]
    websiteURL: Optional[str]
    latitude: Optional[float]
    longitude: Optional[float]
    holes: List[Dict[str, Any]]
    source: Dict[str, Any]


def normalize(raw: Dict[str, Any]) -> List[Dict[str, Any]]:
    meta = raw.get("_fairwayiq") or {}
    fetched_at = meta.get("fetchedAt")

    out: List[NormalizedCourse] = []
    for el in raw.get("elements", []):
        tags = el.get("tags") or {}
        name = tags.get("name")
        if not isinstance(name, str) or not name.strip():
            continue

        city, state = pick_city_state(tags)
        lat, lon = center_lat_lon(el)
        osm_type = el.get("type")
        osm_id = el.get("id")
        if osm_type not in ("node", "way", "relation") or not isinstance(osm_id, int):
            continue

        course_id = f"osm:{osm_type}:{osm_id}"
        course = NormalizedCourse(
            id=course_id,
            name=norm_space(name),
            city=city,
            state=state,
            kind=infer_kind(tags),
            websiteURL=canonical_website(tags),
            latitude=lat,
            longitude=lon,
            holes=[{"number": i, "par": 4, "yardage": None} for i in range(1, 19)],
            source={
                "provider": "osm",
                "osmType": osm_type,
                "osmId": osm_id,
                "fetchedAt": fetched_at,
            },
        )
        out.append(course)

    # Simple dedupe pass: name+city+state normalized.
    seen = set()
    result: List[Dict[str, Any]] = []
    for c in out:
        key = (c.name.lower(), c.city.lower(), c.state.lower())
        if key in seen:
            continue
        seen.add(key)
        result.append(
            {
                "id": c.id,
                "name": c.name,
                "city": c.city,
                "state": c.state,
                "kind": c.kind or "Unknown",
                "websiteURL": c.websiteURL,
                "latitude": c.latitude,
                "longitude": c.longitude,
                "holes": c.holes,
                "source": c.source,
            }
        )
    return result


def main() -> None:
    p = argparse.ArgumentParser(description="Normalize Overpass golf courses to FairwayIQ seed schema v1.")
    p.add_argument("--in", dest="inp", type=str, required=True)
    p.add_argument("--out", dest="outp", type=str, required=True)
    args = p.parse_args()

    with open(args.inp, "r", encoding="utf-8") as f:
        raw = json.load(f)

    normalized = normalize(raw)
    with open(args.outp, "w", encoding="utf-8") as f:
        json.dump(normalized, f, ensure_ascii=False, indent=2)


if __name__ == "__main__":
    main()

