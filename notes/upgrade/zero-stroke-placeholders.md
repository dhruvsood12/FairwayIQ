# Placeholder rows are fabricated data waiting to happen

Round setup saves 18 zero-stroke HoleScore placeholders the moment a round
starts, and an abandoned round keeps them forever. The handicap qualification
gate checked ratings, hole count, and pars, but never asked whether a hole
was played, so a freshly started round could reach the index as an adjusted
gross of zero and a differential of minus 72.

The correct math was not enough. The seam between a correct calculator and
the app's data shapes is where fabrication sneaks back in: any aggregate fed
from persisted rows must know which rows represent reality and which are
scaffolding. Zero strokes now disqualifies the round, and the test suite pins
fresh and partially scored rounds producing no differential.

Related reachability lesson: a feature can be mathematically correct, fully
tested, and still structurally unreachable for every real user (no bundled
course carries per-hole pars, so no production round can qualify). That gap
is now disclosed in MODEL.md, the README, and the analytics screen itself
rather than left for a user to discover.
