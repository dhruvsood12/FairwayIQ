# Sample data must be obviously sample

Three fabrication patterns hid in the demo path. Fake leaderboard friends
with invented handicaps had no flag separating them from real entries, so
once seeded they were indistinguishable from real data. Demo courses wore
real venue names (Pebble Beach, Augusta National, Torrey Pines in the
starter seed) with invented per-hole pars, which reads as a data claim about
real places. And the sample seeding used the same inverse-assignment
double-linking the test fixtures had, so demo rounds carried doubled
aggregates.

Resolution: the friends factory is deleted outright since no real friend
path exists yet and the leaderboard empty state already tells the truth.
Demo courses are fictional (Sample Links, Sample Parkland, Sample Muni Nine,
kind Sample, no coordinates), so invented pars are clearly sample values on
places that do not exist. The starter seed with real venue names is deleted
with its loader fallback. The double-link loops are gone.

Proof pattern for the phase gate: grep for FriendEntry( outside the model
file returns nothing, and grep for the real venue names returns nothing.
