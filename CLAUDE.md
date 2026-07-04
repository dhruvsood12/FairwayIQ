# CLAUDE.md

Project constitution for the FairwayIQ v2 rebuild. Every change in this repo
is bound by the rules below. The phase plan and acceptance criteria live in
the v2 execution contract; this file records what every phase must respect.

## Ground rules

- No AI artifacts. No `Co-Authored-By` trailers, no "Generated with" lines,
  no emoji in commits, no marketing adjectives in code or docs. Every commit
  must read like a human engineer wrote it. This extends to prose; tool-name
  leaks in docs get removed on contact.
- Conventional Commits only, scoped and imperative: `fix(analytics): ...`,
  `feat(core): ...`, `chore(ci): ...`, `refactor(data): ...`. One logical
  change per commit.
- No inline code comments. Use clear names. Doc comments on public APIs only.
- No fabricated data or metrics. If real golf data (par, yardage, rating,
  slope) is unavailable, store null and surface that honestly in the UI.
  Never invent par 72.
- Every README claim must be verifiable by a command, a test, or a file.
  Unverifiable claims get deleted, not softened.
- Verify, don't assert. Before each commit, run the gate (build + test +
  lint) and paste the output. If the iOS app target cannot be built in the
  current environment, build and test the FairwayIQCore package and say so
  explicitly. A phase is not done without a green gate.
- Analytics and business logic live in `FairwayIQCore` where tests can reach
  them. Views format and bind, nothing else.
- Tests must exercise the code the app ships. A test that imports a parallel
  reimplementation is a defect, not coverage.

## Commands

Core package (always available):

```
swift build
swift test
```

iOS app target (requires macOS + Xcode):

```
xcodebuild build -project FairwayIQ.xcodeproj -scheme FairwayIQ -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO
xcodebuild test -project FairwayIQ.xcodeproj -scheme FairwayIQ -destination 'platform=iOS Simulator,name=iPhone 17'
```

Lint / format:

```
swiftformat --lint .
swiftlint --strict
```

Toolchain, verified 2026-07-04: Xcode 26.3, Swift 6.2.4, iOS 26.3 simulator
runtimes (iPhone 17 family plus iPhone 16e; no device named iPhone 16).
Tools live in
~/.local/bin: swiftformat 0.61.1 and swiftlint 0.63.3, matching the pinned
CI versions; the xcodeproj gem is 1.27.0. CI runs on macos-26 with Xcode
26.3 pinned behind an existence assertion and picks its simulator by name at
run time. The FairwayIQTests bundle (102 tests in 9 suites) runs through the
shared scheme; the package suite is `swift test` (34 tests).

## Architecture

```
FairwayIQ.xcodeproj       Two native targets: FairwayIQ (iOS app) and
                          FairwayIQTests (unit-test bundle hosted by the app).
                          The shared scheme runs both.
FairwayIQ/
  FairwayIQApp.swift      App entry at the target root: builds the SwiftData
                          ModelContainer (10-model schema, in-memory fallback).
  App/                    RootView routes onboarding vs main and applies the
                          bundled catalog, MainTabView holds 5 tabs.
                          AppState/SessionStore scopes data to the profile.
  Components/             Theme colors and layout constants.
  Core/                   DesignSystem components, InputValidation (pure bounds
                          checks), utilities (PlayerScopedData, DebugLogger).
  Data/                   ProfileRepository, Seed/ (CourseSeedLoader +
                          Resources/courses_catalog.json, honest nulls),
                          Export/ExportManager (DTO-based, labeled values).
  Domain/Engines/         Pure rules engines: ClubGappingEngine, StrategyEngine,
                          CoachingEngine, GoalEngine.
  Domain/Analytics/       RoundAnalytics and HandicapAnalytics (mappings into
                          FairwayIQCore), PerformanceInsights.
  Features/               @Query-driven screens: Analytics, ClubGapping, Goals,
                          Practice, SmartCaddie.
  Models/                 SwiftData @Model classes: UserProfile, Course, Hole,
                          Round, HoleScore, Shot, FriendEntry, PracticeSession,
                          PracticeShot, PlayerGoal. SampleData seeds fictional
                          demo data, DEBUG only.
  Services/               RoundService, CourseService, LeaderboardService,
                          LocationManager.
  Views/                  Screens by tab: Home, Courses, Rounds, Analytics,
                          Leaderboard (empty scaffold), Profile, Onboarding.
Sources/FairwayIQCore/    The single implementation of the dashboard analytics
                          math: AnalyticsMath, HandicapMath (WHS), GeoMath.
                          The app links this package.
Tests/FairwayIQCoreTests/ XCTest: 34 tests including golden parity fixtures
                          and published WHS worked examples.
FairwayIQTests/           Swift Testing: 102 tests in 9 suites over the app
                          engines, seeds, exports, and handicap qualification.
scripts/course-data/      OSM Overpass pipeline; emits only source data,
                          nulls where the source is silent (13 unit tests).
scripts/xcode/            Idempotent xcodeproj-gem scripts for the package
                          link and the test bundle target.
```

Data flow: views declare `@Query`, SessionStore/PlayerScopedData filter to the
active profile, views map models to value objects, FairwayIQCore and the pure
engines compute, DesignSystem components render with explicit unavailable
states. Writes go through `modelContext` with InputValidation at the
boundaries.

## Repo state to respect

- `main` is the trunk and the GitHub default branch; `v2` carries the
  upgrade and is the working branch, with pull request 1 targeting `main`.
  The remote is `origin` (github.com/dhruvsood12/FairwayIQ). The backup
  branch `backup/pre-filter-2026-06-11` preserves pre-rewrite history until
  the final merge gate and is not to be deleted before then.
- History is clean: all subjects Conventional, no AI trailers, no tracked
  build artifacts (`git ls-files | grep .build` is empty).
- Data honesty is load-bearing: par, yardage, ratings, and handicaps are
  real, user-entered, or explicitly unavailable. The bundled catalog carries
  no per-hole data; DATA.md and MODEL.md record every constant and method.

## Workflow for every phase

1. Plan mode first. Use the `explore` subagent for reconnaissance, produce a
   written plan, wait for approval.
2. Execute the smallest coherent slice.
3. Gate: build + test + lint, paste the output. Green or it is not done.
4. Commit with a Conventional Commit message.
5. Report what changed and what is next in two or three sentences.

History rewrites run in a dedicated worktree or fresh clone, never the
primary working tree. Long commands run in the background.

## Guardrails in this repo

- `.claude/hooks/pre-write-guard.sh` (PreToolUse on Edit|Write): blocks any
  write into `.build/` or `DerivedData/` paths and any write that would
  produce a file over 1 MB.
- `.claude/hooks/post-write-gate.sh` (PostToolUse on Edit|Write): lints any
  changed `*.swift` file with `swiftformat --lint` and runs `swift test` when
  the change touches `Sources/` or `Tests/`. Failures block with the output.
  Warns instead of blocking while swiftformat is not installed.
- Subagents in `.claude/agents/`: `explore` (read-only recon),
  `swift-reviewer` (diff review: correctness, force unwraps, retain cycles,
  layer violations, duplicate symbols), `analytics-quant` (strokes gained,
  dispersion, handicap math and tests; tests first, cited baselines),
  `repo-hygiene` (history rewrite, CI, lint configs; backup branch before
  any destructive step), and `ruthless-reviewer` (adversarial phase-close
  and final-gate auditor; reviews and blocks, never fixes).
