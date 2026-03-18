# FairwayIQ

FairwayIQ is a native iPhone golf performance app built with SwiftUI. The goal is to make round tracking, shot logging, course selection, and performance analysis feel premium, fast, and credible as a real product rather than a one-off UI prototype.

It is designed around a clean, dark, sports-dashboard aesthetic with local-first persistence today and a clear path toward larger course data, cloud sync, and social features later.

## Product overview

FairwayIQ helps a golfer:

- create and persist a real player profile
- browse a starter catalog of U.S. golf courses
- start and track rounds with low-friction scoring
- log shots with structured club, lie, shot type, notes, and optional map-based landing points
- review scorecards, shot maps, and round summaries
- explore performance trends with premium chart-driven analytics

## Current feature set

### Profile and preferences

- persisted player profile with name, skill level, handicap estimate, preferred units, and home course
- editable clubs-in-bag flow with add, delete, and reorder support
- first-launch onboarding tied to a stable current-profile session

### Course catalog

- searchable starter course catalog with real U.S. courses
- course detail screens with location, type, par, and hole breakdown
- seed-data architecture that can scale into a broader ingestion pipeline

### Round workflow

- course-based round setup
- hole-by-hole live entry for strokes, putts, penalties, FIR, and GIR
- safer save flow with user-facing error handling
- end-of-round summary with scorecard, to-par scoring, stats, and shot map

### Shot tracking

- structured shot entry using typed club, lie, and shot type selections
- current-location capture for start and landing
- manual landing placement from a map tap
- automatic distance calculation when both points are available
- optional notes for context

### Analytics

- score trend chart
- index estimate trend
- average score, FIR, GIR, putts per round, penalties per round
- best and worst round callouts
- front-nine vs back-nine comparison
- course-by-course average scoring

## Tech stack

| Area | Technology |
|------|------------|
| App UI | SwiftUI |
| Persistence | SwiftData |
| Maps and location | MapKit, CoreLocation |
| Charts | Swift Charts |
| Architecture | MVVM-oriented feature structure with repositories and pure calculators |
| Platform | iOS |

## Architecture summary

The project is being refactored from a demo-first structure into a production-minded layout with clearer boundaries:

- `App/`
  - app boot, root routing, session state
- `Core/`
  - design system and shared utilities such as debug logging
- `Domain/`
  - models, value types, and pure analytics calculations
- `Data/`
  - repositories and starter seed loaders
- `Features/`
  - feature-specific view models and UI flows
- `Views/`
  - existing screens being migrated feature-by-feature into a cleaner structure

Key production-minded decisions:

- `SessionStore` tracks the current profile instead of relying on `profiles.first`.
- `Round` now relates directly to `Course` and `UserProfile`.
- course seeding is separated from demo-only sample data
- analytics math is moving out of views into testable calculators
- critical save flows now surface errors instead of silently failing

## Folder highlights

```text
FairwayIQ/
├── FairwayIQ/
│   ├── App/
│   ├── Core/
│   ├── Data/
│   ├── Domain/
│   ├── Features/
│   ├── Models/
│   ├── Views/
│   └── Services/
├── scripts/
│   └── course-data/
├── Sources/
│   └── FairwayIQCore/
└── Tests/
    └── FairwayIQCoreTests/
```

## Course data strategy

FairwayIQ is being built with a real course-data pipeline in mind.

### Current approach

- ship a lightweight bundled starter dataset for MVP usability
- persist seeded courses into SwiftData on first launch
- use that catalog for onboarding, browsing, and round setup

### Planned scalable pipeline

The repo includes `scripts/course-data/` for a structured ingestion approach based on OpenStreetMap and Overpass.

Pipeline stages:

1. source discovery from OSM objects tagged `leisure=golf_course`
2. Overpass API ingestion by region or state
3. normalization and deduplication into a stable app-facing schema
4. export to versioned seed files for app import

See:

- `scripts/course-data/README.md`
- `scripts/course-data/seed_schema_v1.md`
- `scripts/course-data/overpass_fetch.py`
- `scripts/course-data/normalize.py`

This avoids brittle HTML scraping and keeps the data story credible for production and interviews.

## Screenshots

Add screenshots here as the UI continues to harden:

- onboarding
- home dashboard
- course catalog
- live round
- round summary
- analytics dashboard
- profile

## Setup

1. Clone the repo:
   `git clone https://github.com/dhruvsood12/FairwayIQ.git`
2. Open `FairwayIQ.xcodeproj` in Xcode.
3. Choose an iPhone simulator or a physical device.
4. Build and run.

Notes:

- The app uses SwiftData for local persistence.
- A starter course catalog seeds on first launch.
- In debug/dev flows, additional demo sample data may be available.
- Shot logging works best with location permission enabled.

## Testability

The app now separates more logic from UI so core calculations can be tested independently.

Current test scaffolding includes:

- a lightweight Swift Package test harness for pure analytics math
- first tests around scoring summaries, denominator correctness, and chart domains

Recommended next unit-test targets:

- course-driven par and to-par calculations
- front/back split logic
- round creation and persistence boundaries
- shot-distance calculations

## Roadmap

### Near-term

- improve course filtering by state, city, and type
- expand shot replay and dispersion views
- tighten round resume and in-progress round handling
- replace remaining legacy service usage with repositories/view models

### Product roadmap

- larger U.S. course dataset import
- optional remote catalog updates
- WHS-style handicap calculation
- cloud backup and sync
- friend system and social comparison
- export/share flows
- Apple Watch companion

## Known limitations

- the bundled course catalog is intentionally small today
- tee-box metadata, course rating, and slope are not complete yet
- handicap is still an estimate, not a full WHS implementation
- social features are scaffolded but not yet connected to a real backend
- Swift Package tests were added for pure logic, but app-target XCTest coverage is still limited

## Recommended commit checkpoints

Suggested incremental commit messages for your local workflow:

- `refactor: introduce app state + repositories boundary`
- `feat(profile): persisted profile, preferences, clubs bag`
- `feat(courses): searchable catalog + seed loader + pipeline docs`
- `feat(rounds): robust round setup + live scoring tied to course holes`
- `feat(shots): structured shot entry + distance + map improvements`
- `feat(analytics): premium dashboard + testable calculators`
- `chore: harden persistence, states, and debug tooling`
- `docs: product narrative, architecture, course data pipeline`

## Author

Built and maintained by [dhruvsood12](https://github.com/dhruvsood12).
