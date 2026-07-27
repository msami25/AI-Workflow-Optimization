# Unedited first response - 11 Event list performance

There is no measured baseline or supplied SQL/query log, so no performance
improvement can honestly be claimed.

Potential risks visible in the evaluation service are an unbounded list and
absence of the requested CategoryName/remaining-capacity projection. There is
no demonstrated N+1 query in the current scalar projection.

Measurement plan:

1. Seed exactly 50,000 events, 500 categories, and 2,000 organizers.
2. Warm up, then run a fixed request set for page 1, middle, and last page.
3. Capture EF command count plus median/p95 elapsed time.
4. Add `pageNumber >= 1`, `pageSize 1-100` (default 50), deterministic
   `OrderBy(StartUtc).ThenBy(Id)`, `Skip`, `Take`, and one untracked projection.
5. Repeat on the same machine/data and compare.

An index on `(StartUtc, Id)` is a candidate because it supports the ordering,
but it should be accepted only after examining the query plan; it adds write
and storage cost.

Regression tests should assert bounds, deterministic ordering, response
equivalence, one SQL command, cancellation, and no tracking. Result table
fields remain `PENDING` until measurement is run.

