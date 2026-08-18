# Metka benchmark

Compares Metka against four other ActiveRecord tagging gems:

| Gem | Version | Storage model |
| --- | --- | --- |
| [metka](https://github.com/jetrockets/metka) | this checkout | PostgreSQL array column + GIN index |
| [acts-as-taggable-array-on](https://github.com/tmiyamon/acts-as-taggable-array-on) | 0.7.0 | PostgreSQL array column + GIN index |
| [tag_columns](https://github.com/hopsoft/tag_columns) | 0.1.10 | PostgreSQL array column + GIN index |
| [acts-as-taggable-on](https://github.com/mbleigh/acts-as-taggable-on) | 13.0.0 | normalized `tags` + polymorphic `taggings` join tables |
| [gutentag](https://github.com/pat/gutentag) | 3.0.1 | normalized `gutentag_tags` + `gutentag_taggings` join tables |

## Running

Needs a scratch PostgreSQL (the run drops and recreates all tables):

```bash
docker run -d --name metka-bench-pg \
  -e POSTGRES_PASSWORD=bench -e POSTGRES_USER=bench -e POSTGRES_DB=metka_bench \
  -p 127.0.0.1:5434:5432 postgres:18
bundle install
bundle exec ruby benchmark.rb          # POSTS=n to change dataset size
```

Dataset: 10,000 posts per gem, 5 tags per post drawn from a 100-tag
vocabulary, identical tag assignment across gems (seeded RNG). Join-table
schemas come from each gem's own bundled migrations. Raw output of the last
run is in `results.txt`.

Metka is benchmarked three times in the cloud/write suites, once per
tag-cloud aggregate: bare (no aggregate maintained), `materialized_view`
(statement-level triggers refresh a matview), and `table` (statement-level
triggers upsert per-tag deltas into a summary table). The table DDL matches
the output of the `metka:strategies:table` generator; the materialized-view
variant reproduces the DDL of a strategy Metka used to ship and stays in the
suite as the comparison that motivated replacing it with the summary table.

## Results (Ruby 4.0.6, Rails 8.1, PostgreSQL 18.3, 10k posts)

Higher i/s is better; multipliers are relative to the fastest gem per row.

| Operation | metka | taggable-array | tag_columns | acts-as-taggable-on | gutentag |
| --- | --- | --- | --- | --- | --- |
| Query: ALL of 2 tags, load records | 6,393 i/s | 6,606 i/s | 970 (6.8x slower) | 2,380 (2.8x slower) | 1,292 (5.1x slower) |
| Query: ANY of 2 tags, count | 4,629 i/s | 4,625 i/s | 679 (6.8x slower) | 791 (5.9x slower) | 1,026 (4.5x slower) |
| Tag cloud (counts over 10k posts) | 209 i/s | 197 i/s | 194 i/s | 126 (1.7x slower) | 158 (1.3x slower) |
| Create post with 5 tags | 1,631 i/s | 1,636 i/s | 1,579 i/s | 196 (8.3x slower) | 183 (9.0x slower) |
| Replace tags of existing post | 8,122 i/s | 7,480 i/s | 7,158 i/s | 186 (44x slower) | 176 (46x slower) |
| Bulk seed 10k posts (`insert_all` where possible) | 0.21 s | 0.17 s | 0.16 s | 51.6 s | 49.5 s |
| Storage, tables + indexes | 2.68 MB | 2.68 MB | 2.68 MB | 17.64 MB | 11.87 MB |

Differences between metka and acts-as-taggable-array-on are within
benchmark noise on every operation.

Tag-cloud strategies, same dataset (bare metka repeated for reference):

| Operation | metka (bare) | metka (materialized_view) | metka (table) |
| --- | --- | --- | --- |
| Tag cloud (counts over 10k posts) | 209 i/s | 9,082 i/s | 9,337 i/s |
| Create post with 5 tags | 1,631 i/s | 133 (12.3x slower) | 1,524 i/s |
| Replace tags of existing post | 8,122 i/s | 173 (47x slower) | 7,696 i/s |
| Bulk seed 10k posts | 0.21 s | 0.24 s | 0.17 s |
| Storage, tables + indexes | 2.68 MB | 2.78 MB | 2.75 MB |

After all suites (tens of thousands of trigger firings), both maintained
aggregates matched a live `UNNEST .. GROUP BY` aggregation exactly — the
script verifies this at the end of every run.

## Why the numbers fall where they do

- **Array gems vs join-table gems.** Every tag operation in metka /
  acts-as-taggable-array-on is a single-table statement
  (`tags @> ARRAY[...]`, `tags && ARRAY[...]`) served by the GIN index.
  acts-as-taggable-on builds one `INNER JOIN taggings` per requested tag plus
  `ILIKE` subqueries against `tags`; gutentag uses an
  `IN (SELECT ... GROUP BY ... HAVING COUNT(*))` subquery. Writes are the
  starkest difference: replacing a tag list is a one-column `UPDATE` for the
  array gems, while the join-table gems load current taggings, diff them, and
  insert/delete rows plus counter-cache updates — hence 47–57x.
- **tag_columns defeats its own index.** Its scopes wrap the column in
  `CAST(tags AS text[])`, and the planner will not use the GIN index on the
  column under a cast: `EXPLAIN` shows metka using a Bitmap Index Scan and
  tag_columns a Seq Scan for the same logical query. Writes (no cast
  involved) match the other array gems.
- **materialized_view vs table strategy.** Both serve tag-cloud reads from a
  small pre-aggregated relation (~45x faster than aggregating live), but they
  pay for freshness very differently. Every tagged write statement re-runs the
  matview's full `UNNEST .. GROUP BY` via `REFRESH MATERIALIZED VIEW
  CONCURRENTLY` (~7 ms here, growing with table size), which drags creates to
  12.3x and tag replacements to 47x slower than bare metka — the same order as
  the join-table gems. The table strategy's triggers instead read the
  statement's transition tables and upsert only the touched tags' counters,
  keeping every write within benchmark noise of bare metka. Both stay exact:
  the run ends by checking each aggregate against a live aggregation.
- **What you give up with arrays.** acts-as-taggable-on and gutentag maintain
  a normalized tag vocabulary, which array columns don't give you: global
  rename in one place, tag metadata, taggings_count caches, cross-model tags,
  taggers/contexts (ATO). Metka's answer for aggregate views is the
  `metka:strategies:table` generator. If those features are unused,
  the join tables are pure overhead — 4.4–6.6x on disk here.

Caveats: single machine, Dockerized PostgreSQL with default settings, one
run per suite via benchmark-ips (2 s warmup / 5 s measure), 10k rows fits in
memory. Relative ordering is stable across runs; treat absolute numbers as
indicative only.
