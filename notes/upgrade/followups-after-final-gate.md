# Follow-ups recorded at the final gate

Two items from the final sign-off audit, neither blocking (no shipped users,
pull request 1 unmerged), both owned going forward.

1. Schema migration across the v2 upgrade. A store created before the
   upgrade fails lightweight migration (mandatory attribute validation on
   Round) and the app falls back to its in-memory store, which silently
   drops persistence for that launch. The fallback predates the upgrade;
   the new fields widen the migration surface. Before any release that
   upgrades existing installs: add a SwiftData migration plan with defaults
   for the added fields, and replace the silent fallback with an explicit
   user-facing recovery path.

2. GitHub Copilot code review runs on pull requests in this repository. It
   is an owner-only repository setting that the command line cannot read or
   change. If the no-AI-artifacts posture is meant to cover review comments
   too, disable it at github.com/dhruvsood12/FairwayIQ/settings; recorded
   here so the decision is deliberate either way.
