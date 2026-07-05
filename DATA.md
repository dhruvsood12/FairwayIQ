# Data sources and cited constants

Every constant and formula in FairwayIQ analytics traces to a source listed
here. Nothing in this file is invented; where a value is unavailable the app
stores null and says so.

## World Handicap System constants (Sources/FairwayIQCore/HandicapMath.swift)

Governing text: Rules of Handicapping, USGA and R&A, 2024 revision (effective
January 2024). Canonical locations:

- USGA PDF: https://www.usga.org/content/dam/usga/pdf/2024-revision/2024-Rules-of-Handicapping-USGA.pdf
- USGA rule browser: https://www.usga.org/handicapping/roh/rules-of-handicapping.html
- R&A Rule 5: https://www.randa.org/en/roh/the-rules-of-handicapping/rule-5

The USGA and R&A servers reject non-browser fetches, so the text was verified
against complete copies of the USGA publication hosted by the Southern
California Golf Association, an Allied Golf Association, and cross-checked
against the R&A rule pages:

- 2024 edition: https://www.scga.org/pdfs/2024%20Rules%20of%20Handicapping%20(V1).pdf
- 2020 edition: https://scga.org/pdfs/Rules%20of%20Handicapping_USGA_Final.pdf

| Constant or rule | Value | Source |
| --- | --- | --- |
| Standard slope rating | 113 | Rule 5.1a |
| Score differential | (113 / slope) x (adjusted gross - course rating - PCC) | Rule 5.1a |
| Differential rounding | nearest tenth, halves upward (negative halves toward zero: -1.55 becomes -1.5) | Rules 5.1a and 5.1c |
| PCC adjustment | 0 in this app | Rule 5.6: PCC "equals zero if fewer than eight acceptable scores are submitted" for the day; a local-first app never has the day-level score pool, so the no-adjustment value applies |
| Scores schedule | 3 scores: lowest 1 minus 2.0; 4: lowest 1 minus 1.0; 5: lowest 1; 6: average of lowest 2 minus 1.0; 7 to 8: average of lowest 2; 9 to 11: lowest 3; 12 to 14: lowest 4; 15 to 16: lowest 5; 17 to 18: lowest 6; 19: lowest 7; 20: average of lowest 8 | Rule 5.2a table |
| Established index | average of the lowest 8 of the most recent 20 differentials, rounded to the nearest tenth | Rule 5.2b |
| Maximum handicap index | 54.0 | Rule 5.3 |
| Minimum scores for an index | 3 (54 holes) | Rule 5.2a |
| Adjusted gross, established index | per hole at most par + 2 + strokes received (net double bogey) | Rule 3.1b |
| Adjusted gross, no index yet | per hole at most par + 5 | Rule 3.1a |
| Slope rating validity | greater than zero required; the official scale is 55 to 155 | Rules of Handicapping, Appendix G |
| Course rating input window | 40.0 to 90.0 | app-side sanity bounds, not an official constant: wide enough for any rated 18-hole course (typical ratings run the low 60s to the low 80s) while rejecting entry mistakes |

## Worked examples pinned in tests (Tests/FairwayIQCoreTests/HandicapMathTests.swift)

- Differentials 13.1 and 13.8 (Norma and Norman, with PCC +1 and net double
  bogey adjustment) and the 20-score record producing index 12.8 then 13.0
  when a new 11.8 differential ages the lowest one out: Guidance on the WHS
  Rules of Handicapping as Applied within GB&I, version 2.0, England Golf,
  Scottish Golf, Wales Golf, and Golf Ireland, pages 30 to 35.
  https://eastsussexnational.co.uk/wp-content/uploads/2023/11/109209_handicapping-advice-v2.0.-no-markup-1-1.pdf
- Three-score and six-score schedule progressions (13.2, 34.1, 37.4): Rules
  of Handicapping Clarifications 5.2a/1 and 5.2a/2 (2024 edition, page 55).
- Negative rounding examples (-1.54, -1.55, -1.56): Rule 5.1c (2024 edition,
  pages 53 to 54).
- Every published figure above was recomputed by hand before being pinned.

## Course catalog (FairwayIQ/Resources/courses_catalog.json)

Source: OpenStreetMap via the Overpass API (leisure=golf_course), San Diego
County snapshot fetched 2026-03-23, normalized by
scripts/course-data/normalize.py. OSM data is ODbL licensed;
attribution: (c) OpenStreetMap contributors, https://www.openstreetmap.org/copyright.

Honest-null policy: the catalog carries 79 courses; 3 carry a source-stated
course par (72, 65, 71 from integer golf:par tags), 76 carry null par, none
carry per-hole detail or yardage because the source states none. The
normalizer never invents values; scripts/course-data/test_normalize.py pins
this and FairwayIQTests/CourseSeedTests.swift pins the shipped counts.

## Geodesic distance (Sources/FairwayIQCore/GeoMath.swift)

Meters-to-yards divisor 0.9144: international yard definition (1 yard =
0.9144 m exactly). Distance itself comes from CoreLocation's
CLLocation.distance(from:).
