# Testing

FairwayIQ includes a growing test suite focused on pure domain behavior and safety-critical edge cases.

## Unit Test Coverage

App-target tests under `FairwayIQTests/` cover:

- `ClubGappingEngine`
  - empty data
  - single shot
  - multiple clubs
  - average/median/min/max
  - standard deviation
  - sample-size confidence
  - filters
  - nil distances
  - carry estimate derivation
- `StrategyEngine`
  - no yardage
  - no club data
  - standard/conservative/aggressive recommendations
  - driver miss avoidance
  - miss tendency detection
  - sparse-data warnings
- `CoachingEngine`
  - empty rounds
  - three-putts
  - penalties
  - clean putting
  - baseline comparisons
  - action item caps
- `GoalEngine`
  - no-data state
  - achieved goals
  - above/below metrics
  - progress bounds
  - invalid metric types
- `InputValidation`
  - distance bounds
  - handicap bounds
  - coordinate bounds
  - numeric sanitization
- `ExportManager`
  - location privacy note
  - club report formatting
- `PerformanceInsights`
  - baseline comparisons
  - costliest mistake detection

## SwiftPM Core Tests

`Sources/FairwayIQCore` is the app's single analytics implementation, and its
package tests cover the analytics math, the golden parity fixtures, and the
shot distance conversion.

Run:

```sh
swift test
```

## App Test Command

The FairwayIQTests unit-test bundle runs 102 tests in 9 suites against any
installed iPhone simulator:

```sh
xcodebuild test \
  -project FairwayIQ.xcodeproj \
  -scheme FairwayIQ \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

CI runs the same bundle on every push, picking the first available iPhone
simulator on the runner by name.

## UI Test Scenarios To Maintain

The app is designed around these UI-critical flows:

- onboarding and profile creation
- starting a round
- entering a hole score
- logging a mapped or manual shot
- viewing analytics tabs
- creating a practice session
- creating and deleting a goal
- exporting a summary
- handling denied/missing location gracefully

## Performance Coverage

Recommended performance tests:

- generate club summaries from thousands of shot records
- compute Smart Caddie recommendations over many rounds/practice shots
- generate coaching summaries over large local datasets
- refresh analytics dashboard summaries from large round histories
