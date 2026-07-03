---
description: Restate the execution loops for the FairwayIQ v2 upgrade. Fire this when you are unsure whether to advance, commit, or review.
---

Run the loops in this order. Do not skip a gate to make progress.

Phase loop. Phases 1 through 5, strictly in order. For each phase: run `explore` for recon, write a short plan, run the commit loop, then run the phase-close gate. Do not begin a phase until the previous one has passed its ruthless review.

Commit loop, once per commit inside a phase:
1. Implement that commit's scope only. Nothing else rides along.
2. Run the commit's gate exactly as written in the contract.
3. If red: read the real failure, fix the cause not the symptom, re-run. Repeat until green. Never edit a gate to pass.
4. When green: stage only the files this commit owns, commit with the specified subject and body, record any nonobvious lesson in `notes/upgrade/`.
5. Advance only after a green gate and a clean commit. Never carry a red gate forward.

Verification interval, at every commit boundary: dispatch a fresh-context verifier subagent given only that commit's scope, its gate, and the acceptance items it touches. It re-runs the gate from a clean state and confirms the invariants. If it disagrees with you, trust the fresh run and fix.

Phase-close gate, once per phase before declaring it done: the phase's own acceptance checks pass with pasted output, and `ruthless-reviewer` reviews the phase diff and returns PASS. A BLOCK means the phase is not done; resolve every blocker and re-run the review.

Final gate, once at the end: `ruthless-reviewer` audits the entire upgrade diff on `v2` against the global acceptance contract and returns PASS, and CI is green on the pushed `v2` across every job.

If your last paragraph is a plan, a question, or an "I'll do X next", that is not an end state. Do the work now with tool calls, or return to the loop.
