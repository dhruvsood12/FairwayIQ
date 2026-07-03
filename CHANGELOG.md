# Changelog

All notable changes to this project are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- A runnable FairwayIQTests unit-test bundle (88 tests in 7 suites) wired into the shared scheme and CI.
- FairwayIQCore trend, split, course performance, and shot distance functions with golden parity tests against the previous app implementation.

- Smart Caddie rules engine with explainable tee and approach recommendations.
- Club Gapping Lab with average, median, range, consistency, confidence, carry/total estimates, and miss tendencies.
- Practice sessions and practice shots for building club data outside of rounds.
- Player goals with progress, trend, and achieved-state evaluation.
- Post-round coaching summaries with strengths, weaknesses, stroke-cost categories, action items, baseline comparisons, and best/worst stretches.
- Privacy-first export DTOs and text reports for round summaries, stats snapshots, and club gapping.
- Profile privacy controls for hiding exact location in exports and preferring manual location logging.
- Shared design system components for premium cards, chips, stat tiles, progress rings, validation messages, and buttons.
- Input validation utilities for score, distance, handicap, goal, and coordinate data.
- Tests for club gapping, strategy, coaching, goals, validation, export formatting, and performance insights.
- `ARCHITECTURE.md`, `SECURITY.md`, and `TESTING.md`.

### Changed

- FairwayIQCore is the single analytics implementation; the app renders from it and the duplicate app-side calculators were deleted.
- Course performance ordering is deterministic: ties on rounds played and average score now break by course name.
- Analytics screens now include richer tabs for overview, scoring, putting, driving/approach, clubs, and goals.
- Home dashboard now surfaces goals, score trend, most-improved metric, hole-type insight, and recent mistake category.
- Live round flow now shows a Smart Caddie preview card where hole and player data are available.
- Round summaries now include baseline context and best/worst stretch insights.
- Practice, goals, and club gapping are scoped to the active profile.
- README rewritten for final-project/recruiter presentation.

### Security

- Location capture remains optional and local-first.
- Exports default to excluding exact location detail.
- Delete-all-local-data flow deletes profile-scoped user data after confirmation.
