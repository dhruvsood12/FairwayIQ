# Course seed schema v2

The app-facing schema exported by `normalize.py` and consumed by
`CourseSeedLoader`. Version 2 removes fabricated hole arrays and adds
course-level fields that carry only source-stated values.

## Top-level

A JSON array of course objects:

```json
[
  {
    "id": "osm:relation:123456",
    "name": "Example Golf Club",
    "city": "San Diego",
    "state": "CA",
    "kind": "Public",
    "websiteURL": "https://example.com",
    "latitude": 32.9001,
    "longitude": -117.2401,
    "coursePar": 72,
    "holeCount": null,
    "holes": [],
    "source": {
      "provider": "osm",
      "osmType": "relation",
      "osmId": 123456,
      "fetchedAt": "2026-03-17T00:00:00Z"
    }
  }
]
```

## Fields

- `id` (string, required): stable identifier; `osm:<type>:<id>` for OSM.
- `name` (string, required)
- `city` / `state` (string, required): best effort from tags, `"Unknown"`
  fallback (the loader maps `"Unknown"` to null).
- `kind` (string, optional): `Public | Private | Resort | Municipal | Unknown`
- `websiteURL` (string, optional): canonicalized URL
- `latitude` / `longitude` (number, optional): centerpoint
- `coursePar` (int, optional): course-level par, present only when the source
  states a plain positive integer (for OSM, the `golf:par` tag). Null means
  the source does not say.
- `holeCount` (int, optional): same rule for the `golf:holes` tag.
- `holes` (array, required): per-hole detail, emitted only when the source
  provides it. The OSM course-level query provides none, so this is empty
  for every catalog entry today. When present:
  - `number` (int, required)
  - `par` (int, required)
  - `yardage` (int|null)
- `source` (object, required): provenance (`provider`, `osmType`, `osmId`,
  `fetchedAt`)

## Change from v1

Version 1 filled `holes` with 18 fabricated par-4 entries for every course.
Version 2 emits only what the source states: empty hole arrays, and nullable
`coursePar`/`holeCount`. `scripts/course-data/test_normalize.py` pins the
behavior; `FairwayIQTests/CourseSeedTests.swift` pins the shipped catalog
counts.
