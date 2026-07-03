---
description: Restate the FairwayIQ v2 upgrade goal and the non-negotiables. Fire this to re-anchor when the thread drifts.
---

The goal: ship FairwayIQ v2 as an honest, tested, single-source app on the `v2` branch.

- One analytics implementation. `FairwayIQCore` is the only analytics code; the app renders from it and the tests assert on it. Exactly one `AnalyticsSummary`. No parallel reimplementation, no test that covers a copy.
- No fabricated data, ever. Real value, user-entered value, or explicit null. Never an invented par, yardage, handicap, or leaderboard friend.
- Real WHS index, validated against a published worked example exactly, with an explicit low-data state and every constant cited.
- Documentation where every claim is backed by a command, a test, or a file. Unverifiable claims are deleted, not softened.
- A green CI run over all of it, including the app test bundle, from a fresh clone of `v2`.

Non-negotiables that bind every step: verify, do not assert; run the gate and paste the output before every commit; Conventional Commits, one logical change each; no inline comments; no AI artifacts; no em or en dashes. The only intentional behavior change in the entire upgrade is Phase 2's documented courseName tie-break.

You are done when the global acceptance contract is satisfied with pasted evidence and `ruthless-reviewer` returns PASS. Not before. If your current step does not move a phase closer to its acceptance checks, stop and return to the contract.
