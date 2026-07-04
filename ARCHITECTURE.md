# Architecture

FairwayIQ is organized around local persistence, thin SwiftUI screens, and testable domain engines. The current structure preserves the original app shell while moving new feature logic into clearer architecture boundaries.

## Folder Structure

```text
FairwayIQ/
├── App/
│   ├── FairwayIQApp.swift
│   ├── RootView.swift
│   ├── MainTabView.swift
│   └── AppState/SessionStore.swift
├── Core/
│   ├── DesignSystem/
│   ├── Utilities/
│   └── Validation/
├── Data/
│   ├── Export/
│   ├── Repositories/
│   └── Seed/
├── Domain/
│   ├── Analytics/
│   ├── Engines/
│   └── ValueTypes/
├── Features/
│   ├── Analytics/
│   ├── ClubGapping/
│   ├── Goals/
│   ├── Practice/
│   └── SmartCaddie/
├── Models/
├── Services/
└── Views/
```

## App Layer

`FairwayIQApp` owns the SwiftData `ModelContainer` and falls back to in-memory persistence if the store cannot be opened. `RootView` resolves onboarding vs main app state using `ProfileRepository` and `SessionStore`.

`SessionStore` is the profile-scoping boundary. It resolves the current profile and filters rounds, practice sessions, and goals so multi-profile or demo data does not accidentally leak into a player’s analytics.

## Core Layer

The core layer contains shared UI and safety primitives:

- `DesignSystem.swift`: card, stat tile, chip, progress ring, button, empty/loading/validation components.
- `InputValidation.swift`: numeric bounds, parsing, coordinate checks, handicap, goal, score, and distance validation.
- `PlayerScopedData.swift`: profile-specific data filtering helpers.

## Domain Layer

The domain layer is intentionally deterministic and testable.

- `ClubGappingEngine`: aggregates round and practice shot records into per-club summaries, confidence levels, carry/total estimates, consistency, and miss tendencies.
- `StrategyEngine`: creates Smart Caddie recommendations from hole info, club summaries, miss tendencies, and strategy mode.
- `CoachingEngine`: produces post-round strengths, weaknesses, stroke-cost categories, action items, and baseline comparison support.
- `GoalEngine`: evaluates active goals against recent rounds and computes progress/trend status.
- `RoundAnalytics` and `HandicapAnalytics`: thin mappings from SwiftData rounds to the FairwayIQCore value types, including handicap qualification rules.
- `PerformanceInsights`: reusable high-level insights such as best/worst stretches, hole type scoring, baseline comparisons, and costliest mistake category; par-dependent insights require real hole data.

## Data Layer

The data layer keeps persistence and import/export behavior out of UI views:

- `ProfileRepository`: profile fetch/upsert boundary.
- `CourseSeedLoader`: bundled local course catalog import.
- `ExportManager`: formatted, privacy-conscious text exports for round summaries, club gapping, and stats snapshots.

## Feature Layer

Newer feature screens live under `Features/`:

- Practice mode logs range/practice shots and feeds Club Gapping.
- Club Gapping Lab visualizes club distance, confidence, consistency, and miss patterns.
- Smart Caddie previews hole strategy from deterministic local data.
- Goals provides measurable progress tracking and recent-trend context.
- Analytics view model centralizes dashboard calculations.

## FairwayIQCore package

The SwiftPM package at `Sources/FairwayIQCore` is the single implementation
of the analytics math the dashboards render: summaries, score trends, front
and back splits, course performance, chart domains, the WHS handicap
calculation, and shot distance conversion. The app links the package; the
package tests (including golden parity fixtures and published WHS worked
examples) assert on exactly what ships. Simple display counts inside views
remain view formatting.

## Data Flow

1. SwiftUI views read SwiftData models through `@Query`.
2. `SessionStore` scopes the raw model arrays to the active player.
3. Views map models to value objects (`ShotRecord`, `RoundSnapshot`).
4. FairwayIQCore math and the domain engines compute summaries,
   recommendations, goals, or coaching insights.
5. Views render the resulting DTO/value objects with the design system,
   showing explicit unavailable states where data is not on record.
6. Save/delete/export actions validate inputs and surface failures to users.

## Design Rationale

- Local-first persistence keeps the project credible without requiring a backend.
- Rules-based engines avoid fake AI and make recommendations explainable.
- Domain calculations stay outside views to improve test coverage.
- Profile scoping is explicit because demo data and future multi-player support are common sources of analytics bugs.
- Export behavior defaults toward privacy by hiding exact location detail.

