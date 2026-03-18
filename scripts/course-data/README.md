# FairwayIQ course data pipeline (OSM / Overpass)

This folder is the **production-minded path** to build a real U.S. golf course catalog without scraping websites.

The strategy is:

1. **Source discovery**: OpenStreetMap (OSM) objects tagged with `leisure=golf_course`.
2. **Ingestion**: Query Overpass API for a region (state bbox / custom bbox).
3. **Normalization**: Clean and dedupe records into a stable app-facing schema.
4. **Export**: Produce a versioned seed file the app can load (`courses_seed_v*.json`).

The app currently ships a **small bundled starter dataset** (see `FairwayIQ/FairwayIQ/Data/Seed/`) for MVP usability.
This pipeline is how you scale beyond that starter set.

---

## Data we aim to capture (MVP → future)

- Course name (**required**)
- City/state (best-effort; required in normalized output)
- Course type (public/private/resort/municipal) when inferred
- Hole count + par (later: tee sets, distances)
- Coordinates (centerpoint)
- Website when present (`website`, `contact:website`)

---

## Setup

From repo root:

```bash
python3 -m venv .venv && source .venv/bin/activate
pip install -r scripts/course-data/requirements.txt
```

---

## Ingest (Overpass)

Fetch golf courses within a bounding box:

```bash
python scripts/course-data/overpass_fetch.py \
  --south 32.50 --west -117.35 --north 33.30 --east -116.60 \
  --out "scripts/course-data/out/raw_sandiego.json"
```

Notes:
- The script fetches OSM **nodes/ways/relations** tagged `leisure=golf_course`.
- This is a **structured API query**, not scraping HTML pages.

---

## Normalize + export app seed

```bash
python scripts/course-data/normalize.py \
  --in "scripts/course-data/out/raw_sandiego.json" \
  --out "scripts/course-data/out/courses_seed_v1_sandiego.json"
```

The normalized output follows the schema in `seed_schema_v1.md`.

---

## Scaling to all U.S. courses

Recommended approach (incremental, reliable):
- Fetch **state-by-state** (or region-by-region) using bounding boxes.
- Normalize each chunk.
- Dedupe globally by:
  - normalized name + city + state, plus
  - proximity (coordinates within a small threshold)
- Then export a single `courses_seed_v*.json`.

Later (beyond MVP), you can:
- host the normalized dataset remotely (S3/GitHub Releases/CDN),
- ship a small starter dataset in-app,
- and periodically sync updates.

