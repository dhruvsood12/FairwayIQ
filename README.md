# FairwayIQ

[![CI (v2 branch)](https://github.com/dhruvsood12/FairwayIQ/actions/workflows/ci.yml/badge.svg?branch=v2)](https://github.com/dhruvsood12/FairwayIQ/actions/workflows/ci.yml)

FairwayIQ is a native iOS golf performance and strategy app built with SwiftUI, SwiftData, MapKit/CoreLocation, and Swift Charts. It is local-first, privacy-conscious, and designed to feel like a polished sports-tech dashboard rather than a basic CRUD score tracker.

The product vision is simple: help golfers record rounds, learn real club distances, understand miss tendencies, set measurable goals, and make smarter on-course decisions.

## Why It Exists

Most casual golf apps stop at score entry. FairwayIQ goes further by turning local round and practice data into explainable coaching and strategy:

- Which clubs are trustworthy?
- Where do misses usually go?
- What actually cost strokes in the last round?
- Which hole type fits the player best?
- What is the safer tee option when driver dispersion is risky?

The app intentionally avoids fake AI. Smart Caddie, Club Gapping, and Coaching insights are deterministic, rules-based, and derived from stored shot and scoring history.

## Core Features

- Player profile, onboarding, home course, handicap estimate, clubs-in-bag, and privacy preferences.
- Course catalog seeded from bundled local course data with searchable course browsing.
- Round setup, live hole-by-hole scoring, FIR/GIR/putts/penalties, and optional shot mapping.
- Round summaries with score vs par, scorecard, front/back splits, map previews, export, and post-round coaching.
- Analytics dashboard with scoring, putting, driving, approach, club gapping, and goals views.
- Practice/range sessions to build club distance data outside of rounds.
- Goals and progress tracking for break-score, putting, GIR, fairways, penalties, and best-score goals.
- Shareable local text exports for stats snapshots, round summaries, and club gapping reports.

## Standout Features

### Smart Caddie

Smart Caddie recommends conservative, standard, or aggressive strategies per hole using:

- hole par and yardage
- learned club distances
- club confidence and sample size
- miss tendencies from tee and approach shots
- warnings when data is sparse

Every recommendation includes a rationale and confidence summary.

### Club Gapping Lab

The Club Gapping Lab computes:

- average, median, min, max, and range
- carry-style and total-style estimates where shot data allows
- consistency rating using variance-style dispersion
- sample-size confidence
- left/right and short/long miss trends
- filters for round/practice data, recent timeframe, lie, and shot type

### Coaching Engine

Post-round coaching identifies:

- what went well
- what cost strokes
- three-putts, penalties, GIR changes, and baseline comparisons
- best and worst stretches
- 3-5 actionable practice takeaways

### Goals + Progress

Goals are evaluated against recent rounds with:

- current value
- target value
- progress percentage
- trend direction
- achieved / remaining status

## Architecture

FairwayIQ uses a production-style, MVVM-oriented layout:

```text
FairwayIQ/
├── App/                  App entry, root routing, session state
├── Core/                 Design system, validation, shared utilities
├── Data/                 Repositories, seed loaders, export helpers
├── Domain/               Pure analytics, strategy, coaching, goal engines
├── Features/             Practice, Club Gapping, Smart Caddie, Goals, Analytics
├── Models/               SwiftData persistence models
├── Services/             Platform services such as location
└── Views/                Existing app flows for home/courses/rounds/profile
```

Key design decisions:

- SwiftData models are kept local-first and relationship-oriented.
- Domain engines are pure and testable where possible.
- Views consume summaries and recommendations instead of duplicating math.
- Session scoping keeps profile-specific rounds, practice sessions, and goals separated.
- Demo/sample data is isolated from local user data.

See [ARCHITECTURE.md](ARCHITECTURE.md) for a deeper breakdown.

## Data Model Overview

- `UserProfile`: player identity, skill level, handicap estimate, home course, clubs, onboarding, and privacy settings.
- `Course` / `Hole`: local course and hole metadata.
- `Round` / `HoleScore` / `Shot`: scored rounds, per-hole stats, and optional mapped shots.
- `PracticeSession` / `PracticeShot`: range or practice data used by Club Gapping and Smart Caddie.
- `PlayerGoal`: measurable player goals evaluated by the Goal Engine.

## Security And Privacy

FairwayIQ is local-first:

- no backend dependency
- no analytics SDK
- no advertising tracker
- location is requested only for optional shot logging
- exports can hide exact location detail
- delete-all-data is available from Profile
- numeric inputs are validated and bounded

See [SECURITY.md](SECURITY.md) for threat model, risks, mitigations, and limitations.

## Screens And Flows

- Onboarding: profile setup and home course selection.
- Home Dashboard: score trend, goals, recent rounds, smart insights, quick actions.
- Live Round: current hole progress, score entry, shot logging, Smart Caddie preview.
- Round Summary: stats, scorecard, coaching, map preview, export.
- Analytics: overview, scoring, putting, driving/approach, clubs, goals.
- Practice: session logging and shot capture.
- Club Gapping Lab: distance chart, confidence, filters, dispersion.
- Profile: settings, privacy controls, data export, delete local data.

## Tech Stack

| Area | Technology |
| --- | --- |
| UI | SwiftUI |
| Persistence | SwiftData |
| Maps/location | MapKit, CoreLocation |
| Charts | Swift Charts |
| Architecture | MVVM-ish views + pure domain engines |
| Testing | Swift Testing / XCTest-style app test files + SwiftPM core tests |
| Platform | iOS |

## How To Run

1. Open `FairwayIQ.xcodeproj` in Xcode.
2. Select the `FairwayIQ` scheme.
3. Run on an iPhone simulator or device.
4. Complete onboarding, seed/sample data if needed, and start logging rounds or practice sessions.

For command-line builds, use a local derived data path:

```sh
xcodebuild -project FairwayIQ.xcodeproj -scheme FairwayIQ -derivedDataPath .build/DerivedData build
```

## Testing

The repo includes tests for:

- club gapping calculations
- strategy recommendations
- miss tendency detection
- coaching summary rules
- goal progress evaluation
- input validation
- export privacy formatting
- performance insight helpers
- SwiftPM core analytics math

Run the SwiftPM core tests:

```sh
swift test
```

Run the app test bundle (102 tests in 9 suites):

```sh
xcodebuild test \
  -project FairwayIQ.xcodeproj \
  -scheme FairwayIQ \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

CI runs both suites on every push. See [TESTING.md](TESTING.md) for coverage
details.

## Documentation

- [ARCHITECTURE.md](ARCHITECTURE.md)
- [SECURITY.md](SECURITY.md)
- [TESTING.md](TESTING.md)
- [CHANGELOG.md](CHANGELOG.md)
- `scripts/course-data/README.md`

## Known Limitations

- The course catalog is local and intentionally lightweight.
- Bundled catalog courses carry no per-hole par or yardage, so rounds on them
  cannot yet produce a handicap differential; the analytics screen states the
  requirements.
- The WHS index uses the par plus five cap only, 18-hole rounds only, PCC
  fixed at zero, and no Rule 5.8 caps; see MODEL.md.
- Smart Caddie is rules-based and intentionally does not overclaim when data is sparse.
- PDF export can be added later; current exports are privacy-safe formatted text.
- Simulator-based UI tests require a local Xcode simulator runtime.

## Future Improvements

- Per-hole par entry so any course can produce handicap differentials.
- Net double bogey adjusted gross scores once stroke indexes exist.
- Better tee-specific course metadata.
- Optional iCloud backup/sync while preserving local-first defaults.
- Apple Watch shot capture.
- PDF report rendering.
- Richer map overlays and dispersion visualizations.

