# Security And Privacy

FairwayIQ is a local-first iOS app. Its primary security goals are protecting user-entered performance data, minimizing location exposure, validating inputs, and making destructive/export actions explicit.

## Threat Model

FairwayIQ protects against:

- accidental sharing of exact shot locations in reports
- crashes or corrupted data from malformed numeric input
- unintended location permission prompts
- partial or invalid local round/practice data
- accidental local data deletion
- demo/sample data being mistaken for private player data

FairwayIQ does not currently protect against:

- a fully compromised device
- a malicious user with direct file-system access to the app sandbox
- cloud compromise, because the app does not currently sync to a backend

## Local-First Assumptions

- User profile, rounds, shots, goals, and practice sessions are stored locally with SwiftData.
- There are no hardcoded API secrets.
- There is no analytics SDK or advertising tracker.
- Course seed data is bundled locally.
- Networking is not required for core app use.

## Location Privacy

Location is optional and scoped to shot logging:

- The app requests When-In-Use location only when shot capture needs it.
- Users can still log shots manually without GPS.
- Profile settings include a preference for manual location logging.
- Exports default to hiding exact location detail.
- Missing or denied location should not block scoring, practice, analytics, or goals.

## Input Validation

`InputValidation` centralizes bounds and parsing for:

- strokes
- putts
- penalties
- yardage
- shot distance
- handicap estimate
- course rating and slope rating
- goal targets
- latitude/longitude

Validation uses sensible ranges and returns user-friendly messages instead of silently coercing bad input.

## Data Safety

Implemented mitigations:

- save errors are surfaced in onboarding, round setup, live scoring, shot entry, and practice entry
- destructive delete-all-data flow requires confirmation
- player-scoped helpers prevent analytics from mixing profiles when multiple profiles exist
- export generation uses DTOs instead of dumping raw persistence objects
- demo/sample data is debug-only and clearly fictional (Sample Links, Sample Parkland, Sample Muni Nine)

## App Configuration Review

The generated Info.plist includes `NSLocationWhenInUseUsageDescription` explaining that location is used to record shot positions and display them on the map.

Recommended release checks:

- verify App Transport Security defaults remain strict
- verify no arbitrary network exceptions are added
- verify no private keys/secrets are committed
- verify `DEBUG`-only sample-data controls are not exposed in release builds

## Limitations

- SwiftData encryption depends on iOS device protection and app sandboxing; the app does not implement a custom encrypted database layer.
- Text exports are user-initiated and can be shared outside the app by the user.
- Location privacy controls hide location detail in app-generated exports, but screenshots or manually shared data are outside the app’s control.

