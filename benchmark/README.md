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

Metka is benchmarked twice in the cloud/write suites, once per tag-cloud
aggregate: `table` (statement-level triggers upsert per-tag deltas into a
summary table; this is what the main results table reports) and bare (no
aggregate maintained, tag clouds computed on the fly). The table DDL matches
the output of the `metka:strategies:table` generator.

## Results (Ruby 4.0.6, Rails 8.1, PostgreSQL 18.3, 10k posts)

Higher i/s is better; multipliers are relative to the fastest gem per row.
The metka column has the `metka:strategies:table` aggregate in place. Tag
queries never touch the aggregate, so the two query rows are measured on the
bare table and apply to either setup.

| Operation | metka | taggable-array | tag_columns | acts-as-taggable-on | gutentag |
| --- | --- | --- | --- | --- | --- |
| Query: ALL of 2 tags, load records | 5,860 i/s | 6,201 i/s | 955 (6.5x slower) | 2,164 (2.9x slower) | 1,171 (5.3x slower) |
| Query: ANY of 2 tags, count | 4,208 i/s | 4,408 i/s | 683 (6.5x slower) | 771 (5.7x slower) | 939 (4.7x slower) |
| Tag cloud (counts over 10k posts) | 8,750 i/s | 197 (44x slower) | 197 (44x slower) | 125 (70x slower) | 160 (55x slower) |
| Create post with 5 tags | 1,495 i/s | 1,615 i/s | 1,590 i/s | 205 (7.9x slower) | 192 (8.4x slower) |
| Replace tags of existing post | 8,051 i/s | 7,781 i/s | 7,219 i/s | 179 (45x slower) | 122 (66x slower) |
| Bulk seed 10k posts (`insert_all` where possible) | 0.21 s | 0.19 s | 0.17 s | 46.9 s | 52.7 s |
| Storage, tables + indexes | 2.75 MB | 2.68 MB | 2.68 MB | 18.07 MB | 11.21 MB |

On queries and writes, differences between metka and
acts-as-taggable-array-on are within benchmark noise; on the tag cloud, the
maintained summary table puts metka ~44x ahead of every gem that aggregates
on the fly.

Bare metka — no aggregate maintained, tag clouds computed on the fly with
`UNNEST .. GROUP BY` — on the same dataset (`table` strategy repeated for
reference):

| Operation | metka (table) | metka (bare) |
| --- | --- | --- |
| Tag cloud (counts over 10k posts) | 8,750 i/s | 211 (41x slower) |
| Create post with 5 tags | 1,495 i/s | 1,601 i/s |
| Replace tags of existing post | 8,051 i/s | 8,304 i/s |
| Bulk seed 10k posts | 0.21 s | 0.22 s |
| Storage, tables + indexes | 2.75 MB | 2.68 MB |

After all suites (tens of thousands of trigger firings), the maintained
aggregate matched a live `UNNEST .. GROUP BY` aggregation exactly — the
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
  insert/delete rows plus counter-cache updates — hence the 45–66x gap.
- **tag_columns defeats its own index.** Its scopes wrap the column in
  `CAST(tags AS text[])`, and the planner will not use the GIN index on the
  column under a cast: `EXPLAIN` shows metka using a Bitmap Index Scan and
  tag_columns a Seq Scan for the same logical query. Writes (no cast
  involved) match the other array gems.
- **What the table strategy costs.** It serves tag-cloud reads from a small
  pre-aggregated relation (~41x faster than aggregating live) while keeping
  every write within benchmark noise of bare metka: its statement-level
  triggers read the statement's transition tables and upsert only the touched
  tags' counters, so a write pays for the tags it changed rather than for a
  full re-aggregation. It stays exact: the run ends by checking the aggregate
  against a live aggregation.
- **What you give up with arrays.** acts-as-taggable-on and gutentag maintain
  a normalized tag vocabulary, which array columns don't give you: global
  rename in one place, tag metadata, taggings_count caches, cross-model tags,
  taggers/contexts (ATO). Metka's answer for tag-count aggregates is the
  `metka:strategies:table` generator. If those features are unused,
  the join tables are pure overhead — 4.1–6.6x on disk here.

Caveats: single machine, Dockerized PostgreSQL with default settings, one
run per suite via benchmark-ips (2 s warmup / 5 s measure), 10k rows fits in
memory. Relative ordering is stable across runs; treat absolute numbers as
indicative only.
