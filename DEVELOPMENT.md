# FairwayIQ — Development Guide

## Folder Structure

```
FairwayIQ/
├── App/
│   └── MainTabView.swift          # Tab bar and root navigation
├── Models/
│   ├── UserProfile.swift
│   ├── Course.swift
│   ├── Hole.swift
│   ├── Round.swift
│   ├── HoleScore.swift
│   ├── Shot.swift
│   ├── FriendEntry.swift
│   └── SampleData.swift           # Seed data for demo
├── Views/
│   ├── Home/
│   │   └── HomeView.swift
│   ├── Rounds/
│   │   └── RoundsView.swift
│   ├── Analytics/
│   │   └── AnalyticsView.swift
│   ├── Leaderboard/
│   │   └── LeaderboardView.swift
│   └── Profile/
│       └── ProfileView.swift
├── ViewModels/                    # Add per-screen ViewModels as needed
├── Services/
│   ├── LocationManager.swift
│   ├── RoundService.swift
│   ├── CourseService.swift
│   └── LeaderboardService.swift
├── Managers/                       # Shared app state / managers
├── Components/
│   └── Theme.swift                # Colors, layout constants
├── Assets.xcassets/
├── FairwayIQApp.swift
└── (Info.plist / config as needed)
```

## Implementation Order (Next Steps)

### Step 4 — Onboarding and Home
- [ ] Add onboarding flow (welcome, name, skill level, units, optional home course).
- [ ] Persist onboarding completion and show Home when done; otherwise show onboarding.
- [ ] Wire Home “Start New Round” to round setup.

### Step 5 — Round Setup and Live Round
- [ ] Round setup screen: course picker (from CourseService), tee box, date, weather, partners.
- [ ] Live round flow: current hole, strokes, putts, fairway hit, GIR, penalties.
- [ ] “Save hole” → next hole; persist round with HoleScores via RoundService.

### Step 6 — Shot Entry and Map
- [ ] Shot entry: club, lie, shot type, start/end location (LocationManager).
- [ ] Compute distance when both points available; save Shot to current round.
- [ ] Map screen: plot shots for round using MapKit and Shot coordinates.

### Step 7 — Round Summary and Analytics
- [ ] Round summary: scorecard, fairways/GIR/putts/penalties, shot map, club usage.
- [ ] Analytics dashboard: handicap trend, average score, fairway/GIR/putts (Swift Charts).
- [ ] Best/worst rounds and club dispersion.

### Step 8 — Leaderboard and Profile
- [ ] Leaderboard: weekly best, latest round, average (mock FriendEntry data).
- [ ] Profile: edit name, skill level, units, home course; clubs in bag management.

### Step 9 — Polish
- [ ] Animations, loading states, empty states.
- [ ] Demo-ready data and flows; screenshots for README.

### Step 10 — README
- [ ] Public README: pitch, features, tech stack, architecture, setup, screenshots, author.

## Running the App

1. Open `FairwayIQ.xcodeproj` in Xcode.
2. Select an iOS Simulator (e.g. iPhone 16).
3. Run (⌘R). Sample data seeds on first launch.

## Git Commit Suggestions

- `Initialize FairwayIQ app architecture`
- `Add onboarding and home dashboard`
- `Implement round setup and live scoring flow`
- `Add shot logging and map integration`
- `Build analytics dashboard and leaderboard`
- `Polish UI and prepare GitHub README`
