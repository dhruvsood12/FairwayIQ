# Development Guide

## Layout

The authoritative structure lives in [ARCHITECTURE.md](ARCHITECTURE.md).
In short: the app target under `FairwayIQ/` (App, Components, Core, Data,
Domain, Features, Models, Services, Views), the analytics package under
`Sources/FairwayIQCore` with its tests under `Tests/FairwayIQCoreTests`,
app-target tests under `FairwayIQTests/`, and the course data pipeline under
`scripts/course-data/`.

## Build and test

Core package:

```sh
swift build
swift test
```

App target and test bundle (any installed iPhone simulator works; iPhone 17
is the local default):

```sh
xcodebuild build -project FairwayIQ.xcodeproj -scheme FairwayIQ \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO
xcodebuild test -project FairwayIQ.xcodeproj -scheme FairwayIQ \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

Lint and format (pinned in CI to swiftformat 0.61.1 and swiftlint 0.63.3):

```sh
swiftformat --lint .
swiftlint --strict
```

CI runs all of the above on every push (.github/workflows/ci.yml).

## Running the app

1. Open `FairwayIQ.xcodeproj` in Xcode.
2. Select the FairwayIQ scheme and an iPhone simulator.
3. Run. Debug builds seed clearly labeled sample data (fictional Sample
   courses with rounds) when no sample courses exist yet; the bundled
   catalog loads independently.

## Project scripts

- `scripts/xcode/link_fairwayiqcore.rb` and `scripts/xcode/add_test_target.rb`
  are idempotent xcodeproj-gem scripts that maintain the package link and the
  test bundle target; run `add_test_target.rb` after adding a test file.
- `scripts/course-data/` fetches and normalizes the OSM course catalog; see
  its README.

## Commit convention

Conventional Commits, scoped and imperative, one logical change per commit,
no AI trailers, no inline code comments. CLAUDE.md holds the full house
rules.
