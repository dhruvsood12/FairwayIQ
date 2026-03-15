# FairwayIQ

**A native iOS golf analytics app for tracking rounds, logging shots, and improving your game.**

FairwayIQ is a recruiter-ready SwiftUI app that helps golfers start and track rounds, record scores and shot locations, view GPS-based maps, analyze performance trends, estimate handicap progression, and compare with friends on a leaderboard—all with a premium, dark-mode-friendly UI and local persistence.

---

## Overview

FairwayIQ is built to feel like a real consumer sports product. It uses **SwiftUI**, **SwiftData**, **MapKit**, **CoreLocation**, and **Swift Charts** with a clear **MVVM**-style architecture. The app is fully demoable with sample courses and mock data, so you can run it immediately after cloning and see a complete flow from onboarding through round summary and analytics.

---

## Key Features

- **Onboarding** — Welcome flow: set player name, skill level, preferred units (yards/meters), and optional home course.
- **Home dashboard** — Quick start round, recent round card, handicap preview, and leaderboard preview.
- **Round setup** — Select from sample courses, choose tee box, date, weather, and playing partners.
- **Live round scoring** — Hole-by-hole entry: strokes, putts, fairway hit, GIR, penalties; save and advance.
- **Shot logging** — Record shots with club, lie, shot type; capture start/end location and distance.
- **Shot map** — MapKit view of all shots for a round (start/end pins).
- **Round summary** — Final score, scorecard, fairways/GIR/putts/penalties, shot map, club usage.
- **Analytics** — Handicap trend, score trend, average score, fairway %, GIR %, putts per round, best/worst rounds (Swift Charts).
- **Leaderboard** — Mock friends leaderboard with weekly best, latest round, and average score.
- **Profile** — View and edit player info, units, home course; manage clubs in bag.

---

## Tech Stack

| Area | Technology |
|------|------------|
| UI | SwiftUI |
| Data | SwiftData |
| Maps & location | MapKit, CoreLocation |
| Charts | Swift Charts |
| Architecture | MVVM-style, services layer |
| Min deployment | iOS 17+ (Xcode may show 26.x; adjust if needed) |

---

## Architecture

- **Models** — SwiftData `@Model` types: `UserProfile`, `Course`, `Hole`, `Round`, `HoleScore`, `Shot`, `FriendEntry`.
- **Views** — Tab shell (Home, Rounds, Analytics, Leaderboard, Profile); onboarding; round setup, live round, shot entry, round summary; profile edit; clubs in bag.
- **Services** — `LocationManager`, `RoundService`, `AnalyticsService`, `CourseService`, `LeaderboardService`.
- **Components** — `Theme` (colors, layout), reusable cards and list rows.
- **Sample data** — `SampleData` seeds courses, friends, and rounds on first launch (no profile so onboarding runs; complete onboarding to create profile and use the app).

---

## Folder Structure

```
FairwayIQ/
├── App/
│   ├── RootView.swift          # Gates onboarding vs main app
│   └── MainTabView.swift       # Tab bar
├── Models/
│   ├── UserProfile.swift
│   ├── Course.swift
│   ├── Hole.swift
│   ├── Round.swift
│   ├── HoleScore.swift
│   ├── Shot.swift
│   ├── FriendEntry.swift
│   └── SampleData.swift
├── Views/
│   ├── Onboarding/
│   │   └── OnboardingView.swift
│   ├── Home/
│   │   └── HomeView.swift
│   ├── Rounds/
│   │   ├── RoundsView.swift
│   │   ├── RoundSetupView.swift
│   │   ├── LiveRoundView.swift
│   │   ├── ShotEntryView.swift
│   │   ├── RoundSummaryView.swift
│   │   └── ShotMapView.swift
│   ├── Analytics/
│   │   └── AnalyticsView.swift
│   ├── Leaderboard/
│   │   └── LeaderboardView.swift
│   └── Profile/
│       ├── ProfileView.swift
│       ├── ProfileEditView.swift
│       └── ClubsInBagView.swift
├── Services/
│   ├── LocationManager.swift
│   ├── RoundService.swift
│   ├── AnalyticsService.swift
│   ├── CourseService.swift
│   └── LeaderboardService.swift
├── Components/
│   └── Theme.swift
├── FairwayIQApp.swift
└── Info.plist / Assets
```

---

## Screenshots

_Screenshots can be added here after building and running the app (e.g. onboarding, home, live round, round summary, analytics, leaderboard, profile)._

| Onboarding | Home | Live Round | Round Summary |
|------------|------|------------|---------------|
| _Placeholder_ | _Placeholder_ | _Placeholder_ | _Placeholder_ |

| Analytics | Leaderboard | Profile |
|-----------|-------------|---------|
| _Placeholder_ | _Placeholder_ | _Placeholder_ |

---

## Demo Flow

1. **First launch** — Seed data creates sample courses and rounds; no profile yet, so onboarding is shown.
2. **Onboarding** — Complete welcome, name, skill level, units, and optional home course; profile is created and main app appears.
3. **Home** — Tap “Start New Round” → round setup sheet.
4. **Round setup** — Pick course, tee, date, weather/partners → “Start Round” → live round.
5. **Live round** — Enter strokes, putts, fairway/GIR, penalties per hole; optionally “Add shot” to log a shot; “Save & Next Hole” through 18; “Finish Round” → round summary.
6. **Round summary** — Review score, scorecard, stats, shot map, club usage; “Done” dismisses back to app.
7. **Rounds** — List of rounds; tap one for summary; “+” opens round setup.
8. **Analytics** — Score trend, handicap trend, key stats, best/worst rounds.
9. **Leaderboard** — Mock friends and scores.
10. **Profile** — Tap card to edit; “Clubs in bag” to manage clubs.

---

## Setup

1. Clone the repo:  
   `git clone https://github.com/dhruvsood12/FairwayIQ.git`
2. Open `FairwayIQ.xcodeproj` in Xcode.
3. Select an iOS Simulator (e.g. iPhone 16) or a device.
4. Build and run (⌘R).  
   On first launch, sample courses and rounds are seeded; complete onboarding to create your profile and use the full app.  
   **Location:** Shot logging uses GPS. Allow location when prompted, or use the simulator’s location simulation.

---

## Why This Project Is Interesting

- **Native SwiftUI** — Modern declarative UI, dark theme, and consistent layout.
- **SwiftData** — Schema design, relationships, and cascade deletes for rounds/scores/shots.
- **MapKit & CoreLocation** — Shot positions and map presentation.
- **Swift Charts** — Handicap and score trends, and key stats.
- **End-to-end flow** — Onboarding → round setup → live scoring → shot entry → summary → analytics and profile, with clear navigation and state.
- **Demo-ready** — Sample data and mock leaderboard make it easy to show without a backend.

---

## Future Improvements

- Real course database (e.g. API or local bundle).
- Handicap index calculation per USGA/WHS.
- Export scorecards or rounds (PDF/share).
- iCloud sync for rounds and profile.
- Social features: real friends, challenges, activity feed.
- Apple Watch companion for quick score entry.
- Accessibility: VoiceOver, Dynamic Type, reduced motion.

---

## Roadmap

- [x] Onboarding and home dashboard  
- [x] Round setup and live scoring  
- [x] Shot entry and map  
- [x] Round summary and analytics (Swift Charts)  
- [x] Leaderboard and profile (edit, clubs)  
- [x] Polish and README  
- [ ] Optional: Handicap calculation, export, iCloud, Watch

---

## Author

**[dhruvsood12](https://github.com/dhruvsood12)** — [GitHub](https://github.com/dhruvsood12)

---

## License

This project is available for portfolio and educational use. See repository for any license details.
