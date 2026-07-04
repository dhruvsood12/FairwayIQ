# Analytics methods

How FairwayIQ computes what it shows. Constants and sources live in DATA.md;
this file records the method decisions and their limits.

## Handicap index (WHS)

The index is computed by `HandicapMath` in FairwayIQCore per the Rules of
Handicapping (USGA and R&A, 2024): score differentials from Rule 5.1a, the
Rule 5.2a schedule from three scores up, the Rule 5.2b best 8 of the latest
20, and the Rule 5.3 cap of 54.0. `HandicapAnalytics` in the app maps rounds
to differentials.

A round counts toward the index only when nothing about it needs inventing:

- a user-entered course rating and slope rating from the scorecard,
- exactly 18 scored holes,
- a known par for every hole (real hole detail on the course).

Rounds that fail any test are excluded and the analytics screen says how many
rounds qualify. With fewer than three qualifying rounds the app shows an
explicit unavailable state, never a number. A hole with zero strokes marks an
unplayed placeholder and disqualifies its round.

Reachability, stated plainly: no bundled catalog course carries per-hole
pars, so today only courses with real hole detail can host qualifying rounds,
and the shipped catalog alone cannot produce an index. The analytics screen
says so. Per-hole par entry is the planned path out.

Method limits, stated plainly:

- Adjusted gross scores use the par plus five cap of Rule 3.1a. Net double
  bogey (Rule 3.1b) needs per-hole stroke indexes, which are not in the data
  model; when they arrive, the established-index path in `HandicapMath` is
  already implemented and tested.
- Nine-hole scores do not produce differentials. The 2024 expected-score
  method for nine-hole rounds is not implemented.
- PCC is zero, per the Rule 5.6 fallback for an app that never sees a full
  day of scores (see DATA.md).
- The soft and hard caps of Rule 5.8 need a Low Handicap Index history the
  app does not yet track; indexes here are uncapped below 54.0.

The index trend recomputes the index after each qualifying round in date
order, so the chart shows what the index would have been at each point with
the record known at that time.

The profile's self-reported handicap estimate remains only as a labeled
fallback where no computed index exists, and exports label which value they
contain.

## Summary analytics

`AnalyticsMath` in FairwayIQCore is the single implementation for scoring
averages, fairway and green percentages, putting, penalties, best and worst
rounds, score trends, front and back nine splits, and course performance.
Golden parity tests pin its outputs to the pre-refactor app implementation.
Course performance orders ties deterministically by course name; that is the
one documented deviation.

## Par and course data

Par is never assumed. A round's par comes from real hole detail or a
source-stated course par, otherwise the app shows an unavailable state
(see DATA.md for the catalog's honest-null counts).

## Shot distance

`GeoMath` converts CoreLocation geodesic meters to yards with the exact
international yard definition. No dispersion or strokes-gained model ships
yet; nothing here estimates what was not measured.
