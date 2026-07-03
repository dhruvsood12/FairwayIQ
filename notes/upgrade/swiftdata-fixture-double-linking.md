# SwiftData test fixtures must not set the inverse after init

Twenty fixture sites across four test files built rounds as
`Round(courseNameSnapshot:holeScores:)` and then looped
`for s in scores { s.round = round }`. The init already establishes the
relationship, and assigning the inverse afterward appends every score to
`round.holeScores` a second time, even outside a ModelContainer. Every
aggregate over the round then doubles: a 72-stroke fixture reads as 144.

The tests were written blind (no runnable target existed), so five
expectations failed on the first real run while sixteen others passed only
because their assertions are insensitive to doubling (ratios, contains
checks). The engines were correct throughout; the fix was deleting the
redundant loops, not touching the engines.

Lesson: after `Round(holeScores:)`, do not touch `score.round`. And a test
suite that has never executed proves nothing either way about the code it
covers; expectations and fixtures both need their first real run.
