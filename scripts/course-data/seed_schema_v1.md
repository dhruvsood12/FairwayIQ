# Course seed schema v1

This is the **app-facing** schema exported by `normalize.py`.

## Top-level

The export is a JSON array of course objects:

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
    "holes": [{ "number": 1, "par": 4, "yardage": null }],
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

- `id` (string, required): stable identifier. For OSM, use `osm:<type>:<id>`.
- `name` (string, required)
- `city` (string, required): best-effort from OSM tags; required after normalization (use `"Unknown"` if needed).
- `state` (string, required): 2-letter US abbreviation when known; `"Unknown"` fallback.
- `kind` (string, optional): `Public | Private | Resort | Municipal | Unknown`
- `websiteURL` (string, optional): canonicalized URL
- `latitude` / `longitude` (number, optional): centerpoint
- `holes` (array, required): for MVP seed we may emit pars only; later versions add yardage/tees.
  - `number` (int, required)
  - `par` (int, required)
  - `yardage` (int|null)
- `source` (object, required): provenance
  - `provider` (string): `osm`
  - `osmType` (string): `node | way | relation`
  - `osmId` (int)
  - `fetchedAt` (ISO8601 string)

## Versioning

When schema changes (e.g. tee sets), create `seed_schema_v2.md` and export `courses_seed_v2.json`.
