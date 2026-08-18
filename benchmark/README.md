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

## Results (Ruby 4.0.6, Rails 8.1, PostgreSQL 18.3, 10k posts)

Higher i/s is better; multipliers are relative to the fastest gem per row.

| Operation | metka | taggable-array | tag_columns | acts-as-taggable-on | gutentag |
| --- | --- | --- | --- | --- | --- |
| Query: ALL of 2 tags, load records | 6,183 i/s | 6,865 i/s | 977 (7.0x slower) | 2,401 (2.9x slower) | 1,365 (5.0x slower) |
| Query: ANY of 2 tags, count | 4,730 i/s | 4,795 i/s | 676 (7.1x slower) | 794 (6.0x slower) | 974 (4.9x slower) |
| Tag cloud (counts over 10k posts) | 213 i/s | 198 i/s | 194 i/s | 128 (1.7x slower) | 158 (1.3x slower) |
| Create post with 5 tags | 1,604 i/s | 1,634 i/s | 1,659 i/s | 203 (8.2x slower) | 197 (8.4x slower) |
| Replace tags of existing post | 8,223 i/s | 7,754 i/s | 7,342 i/s | 143 (57x slower) | 177 (47x slower) |
| Bulk seed 10k posts (`insert_all` where possible) | 0.21 s | 0.21 s | 0.21 s | 53.5 s | 49.8 s |
| Storage, tables + indexes | 2.68 MB | 2.68 MB | 2.68 MB | 17.98 MB | 12.03 MB |

Differences between metka and acts-as-taggable-array-on are within
benchmark noise on every operation.

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
- **What you give up with arrays.** acts-as-taggable-on and gutentag maintain
  a normalized tag vocabulary, which array columns don't give you: global
  rename in one place, tag metadata, taggings_count caches, cross-model tags,
  taggers/contexts (ATO). Metka's answer for aggregate views is the
  view/materialized-view generators. If those features are unused,
  the join tables are pure overhead — 4.5–6.7x on disk here.

Caveats: single machine, Dockerized PostgreSQL with default settings, one
run per suite via benchmark-ips (2 s warmup / 5 s measure), 10k rows fits in
memory. Relative ordering is stable across runs; treat absolute numbers as
indicative only.
