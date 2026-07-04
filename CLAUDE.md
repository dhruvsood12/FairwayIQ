# CLAUDE.md

Project constitution for the FairwayIQ v2 rebuild. Every change in this repo
is bound by the rules below. The phase plan and acceptance criteria live in
the v2 execution contract; this file records what every phase must respect.

## Ground rules

- No AI artifacts. No `Co-Authored-By` trailers, no "Generated with" lines,
  no emoji in commits, no marketing adjectives in code or docs. Every commit
  must read like a human engineer wrote it. This extends to prose: TESTING.md
  currently leaks the phrase "Codex sandbox" and that class of artifact gets
  removed on contact.
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
xcodebuild -scheme FairwayIQ -destination 'platform=iOS Simulator,name=iPhone 16' build
xcodebuild -scheme FairwayIQ -destination 'platform=iOS Simulator,name=iPhone 16' test
```

Lint / format:

```
swiftformat --lint .
swiftlint
```

Toolchain reality on this machine, verified 2026-06-10: Xcode 26.3, Swift
6.2.4, iOS 26.3 simulator runtimes only. There is no iPhone 16 simulator;
substitute `name=iPhone 17` (or `iPhone 16e`) locally and pin the CI
destination explicitly in the workflow. `swiftformat`, `swiftlint`,
`git-filter-repo`, and `gh` are not installed yet; install via Homebrew
before the phases that need them. Until a test bundle target exists in
`FairwayIQ.xcodeproj`, `xcodebuild ... test` has nothing to run; the only
runnable suite is `swift test`.

## Architecture

```
FairwayIQ.xcodeproj       One native target: FairwayIQ (iOS app). No test bundle
                          target and no shared scheme; FairwayIQTests/ files are
                          grouped in the project but cannot currently run.
FairwayIQ/
  App/                    Composition root. FairwayIQApp builds the SwiftData
                          ModelContainer (10-model schema, in-memory fallback),
                          RootView routes onboarding vs main, MainTabView holds
                          5 tabs. AppState/SessionStore scopes data to the
                          active profile.
  Core/                   DesignSystem components, InputValidation (pure bounds
                          checks), utilities (PlayerScopedData, DebugLogger).
  Data/                   ProfileRepository (protocol-fronted), Seed/
                          (CourseSeedLoader + Resources/courses_catalog.json),
                          Export/ExportManager (DTO-based, privacy-aware).
  Domain/Engines/         Pure rules engines: ClubGappingEngine, StrategyEngine,
                          CoachingEngine, GoalEngine. No SwiftUI imports.
  Domain/Analytics/       AnalyticsCalculators (the math the app actually runs,
                          including its own AnalyticsSummary), PerformanceInsights.
  Features/               Newer screens, @Query-driven: Analytics, ClubGapping,
                          Goals, Practice, SmartCaddie.
  Models/                 SwiftData @Model classes: UserProfile, Course, Hole,
                          Round, HoleScore, Shot, FriendEntry, PracticeSession,
                          PracticeShot, PlayerGoal. SampleData seeds demo rows
                          (including 5 fabricated leaderboard friends, DEBUG only).
  Services/               Older @Observable services: RoundService, CourseService,
                          LeaderboardService, LocationManager.
  Views/                  Original screens by tab: Home, Courses, Rounds
                          (LiveRoundView, ShotEntryView, ShotMapView), Analytics,
                          Leaderboard, Profile, Onboarding.
Sources/FairwayIQCore/    SwiftPM package, one file (AnalyticsMath.swift). A
                          parallel reimplementation of AnalyticsCalculators with
                          a second AnalyticsSummary type. The app does not import
                          it anywhere. Phase 2 makes this the single source of
                          truth.
Tests/FairwayIQCoreTests/ XCTest, 4 tests over AnalyticsMath. The only suite
                          that runs today.
FairwayIQTests/           7 Swift Testing files, 88 @Test functions targeting the
                          app's Domain engines. Real tests, no runnable target.
scripts/course-data/      OSM Overpass ingestion pipeline. normalize.py currently
                          fabricates every course as 18 holes of par 4 with null
                          yardage; the bundled catalog (79 courses) inherits that.
```

Data flow: views declare `@Query`, SessionStore/PlayerScopedData filter to the
active profile, views map models to value objects, pure Domain engines compute,
DesignSystem components render. Writes go through `modelContext` with
InputValidation at the boundaries.

## Repo state to respect

- Current branch is `core-schema`, not `main`. `main` exists locally. The
  single remote is named `a` (github.com/dhruvsood12/FairwayIQ.git) and only
  `core-schema` is pushed.
- The working tree carries roughly 6,700 uncommitted lines (staged, unstaged,
  and untracked), including load-bearing untracked files
  (`FairwayIQ/Domain/Analytics/PerformanceInsights.swift`,
  `FairwayIQ/Core/Utilities/PlayerScopedData.swift`). The staged set alone
  likely does not compile. This must be committed or resolved before any
  history rewrite.
- `.build/` has 222 tracked files (about 56 MB), all added in commit
  `a169f62`, six days before `.gitignore` existed. The ignore file is correct;
  the tracked files are the problem. Phase 1 purges them from history.
- The committed `Sources/FairwayIQCore/AnalyticsMath.swift` at HEAD does not
  compile (`let max` shadows `Swift.max`); an uncommitted working-tree edit
  already fixes it. `swift build` and `swift test` are green only because of
  that uncommitted change.
- History: 18 commits, no AI trailers, 13 with non-conventional verbose
  subjects.
- A linked git worktree exists at `.claude/worktrees/hardcore-noether`
  (branch `claude/hardcore-noether`, same commit as HEAD). Do not touch it
  without checking `git worktree list` first.

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
  any destructive step).
