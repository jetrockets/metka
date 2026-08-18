# Cloud Table Naming Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rename the table-strategy generator's derived summary-table name from `tagged_<source_table>` to `<source_table>_<columns>_cloud` (e.g. `songs_tags_cloud`), matching the index strategy's `<source_table>_<column>_index` pattern.

**Architecture:** One code change — the `table_name` derivation in the table generator. The ERB migration templates interpolate `<%= table_name %>` everywhere, so they need no changes. Everything else is fixtures and docs modeling the new convention: generator tests, the dummy app's hand-written equivalent migration/model/test, the README, and the benchmark.

**Tech Stack:** Ruby gem (metka), Rails generators, Minitest, dummy Rails app under `test/dummy` running on PostgreSQL or SQLite (`DB=sqlite` env var switches the adapter).

**Spec:** `docs/superpowers/specs/2026-08-18-cloud-table-naming-design.md`

**Reference — the naming rule:** derived name is `#{source_table_name}_#{source_columns.join("_and_")}_cloud`, uniformly. No special case for the default `tags` column. `--table-name` still overrides. Migration name stays `create_#{table_name}_table`.

**Reference — what does NOT change:** trigger names (`metka_ins_on_<source_table>_<columns>` — derived from the source table), the `tag_name`/`taggings_count` columns, both ERB templates, all runtime code in `lib/metka/`, and the historical benchmark results files (`benchmark/results*.txt` are recorded outputs of past runs — leave them).

**Test environment setup (once, before Task 1):**

```bash
cd /home/igor/Work/metka/.claude/worktrees/tagging-table-naming-5cd0c9
bundle install
DB=sqlite bundle exec rake dummy:db:migrate:reset
```

SQLite always works locally. PostgreSQL runs the other template branch; if a local server is available (`psql -h localhost -U postgres -c 'select 1'` succeeds), also run the PG variants of each verification step (`bundle exec rake dummy:db:create dummy:db:migrate:reset`, no `DB` env var). If PG is unavailable, say so in the final report — CI runs both.

---

### Task 1: Generator derivation (TDD)

**Files:**
- Modify: `test/generators/strategies/table_generator_test.rb`
- Modify: `lib/generators/metka/strategies/table/table_generator.rb:62-67`

- [ ] **Step 1: Update the generator test's expected names**

In `test/generators/strategies/table_generator_test.rb`:

1. Change the migration constant (line 8):

```ruby
  MIGRATION = "db/migrate/create_notes_tags_cloud_table.rb"
```

2. Replace every `tagged_notes` in the assertion regexes with `notes_tags_cloud`. That is exactly these lines: 24 (`CREATE TABLE`), 28 (`INSERT INTO ... (tag_name, taggings_count)`), 44 (`DROP TABLE IF EXISTS`), 73 (`INSERT INTO` inside the lock-ordering test), 80–82 (`CREATE OR REPLACE FUNCTION metka_ins/upd/del_notes_tags_cloud`), 93–95 (`DROP FUNCTION IF EXISTS metka_ins/upd/del_notes_tags_cloud`). Do NOT touch the trigger-name assertions (lines 32–34, 38–40, `metka_ins_on_notes` etc.) — trigger names derive from the source table and stay the same.

3. Add two new tests at the end of the class (before the closing `end`, after the `if SQLITE`/`else` block), covering the multi-column derivation and the override — both previously untested:

```ruby
  test "derives the name from the source columns when given" do
    prepare_destination
    run_generator [ "--source-table-name=notes", "--source-columns=tags", "genres" ]

    assert_migration "db/migrate/create_notes_tags_and_genres_cloud_table.rb",
      /CREATE TABLE notes_tags_and_genres_cloud/i
  end

  test "respects an explicit --table-name" do
    prepare_destination
    run_generator [ "--source-table-name=notes", "--table-name=note_cloud" ]

    assert_migration "db/migrate/create_note_cloud_table.rb", /CREATE TABLE note_cloud/i
  end
```

- [ ] **Step 2: Run the generator tests to verify they fail**

```bash
DB=sqlite bundle exec ruby -Itest test/generators/strategies/table_generator_test.rb
```

Expected: FAIL — every test errors or fails because the generator still emits `db/migrate/*_create_tagged_notes_table.rb`, so `assert_migration "db/migrate/create_notes_tags_cloud_table.rb"` finds no migration.

- [ ] **Step 3: Change the derivation**

In `lib/generators/metka/strategies/table/table_generator.rb`, replace the `table_name` method (lines 62–67):

```ruby
          def table_name
            return options[:table_name] if options[:table_name]

            "#{source_table_name}_#{source_columns_names}_cloud"
          end
```

(The `columns_sequence` local and its default-columns special case disappear entirely; `source_columns_names` already joins with `_and_`.)

Also update the generator's `desc` LONGDESC if it mentions the derived name — it currently doesn't (it only shows the flags), so no change expected there; just confirm.

- [ ] **Step 4: Run the generator tests to verify they pass**

```bash
DB=sqlite bundle exec ruby -Itest test/generators/strategies/table_generator_test.rb
```

Expected: PASS (SQLite runs 11 tests after the two added in Step 1). If PostgreSQL is available, also run without `DB=sqlite` — it exercises the PG branch (function-name assertions): PASS, 13 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/generators/metka/strategies/table/table_generator.rb test/generators/strategies/table_generator_test.rb
git commit -m "feat(generator): Derive cloud table name as <source>_<columns>_cloud

The table strategy summary table default changes from
tagged_<source_table> to <source_table>_<columns>_cloud
(songs_tags_cloud), mirroring the index strategy's
<source_table>_<column>_index naming. Generation-time only:
existing installs keep their tagged_* tables; --table-name
still overrides.

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 2: Dummy app models the new convention

**Files:**
- Rename: `test/dummy/db/migrate/11_create_tagged_table_posts_table.rb` → `test/dummy/db/migrate/11_create_table_posts_tags_cloud_table.rb`
- Rename: `test/dummy/app/models/tagged_table_post.rb` → `test/dummy/app/models/table_posts_tags_cloud.rb`
- Rename: `test/metka/tagged_table_post_test.rb` → `test/metka/table_posts_tags_cloud_test.rb`

The dummy source table is `table_posts` (migration 10), so the new summary table name is `table_posts_tags_cloud`.

- [ ] **Step 1: Rename and edit the dummy migration**

```bash
git mv test/dummy/db/migrate/11_create_tagged_table_posts_table.rb test/dummy/db/migrate/11_create_table_posts_tags_cloud_table.rb
```

Then in the renamed file:
- Class name: `CreateTaggedTablePostsTable` → `CreateTablePostsTagsCloudTable` (must match the new filename or Rails raises on migrate).
- Replace all `tagged_table_posts` → `table_posts_tags_cloud` (both the SQLite and PostgreSQL branches: CREATE TABLE, INSERT INTO, UPDATE, DELETE FROM, DROP TABLE, and the PG function names `metka_ins/upd/del_tagged_table_posts` → `metka_ins/upd/del_table_posts_tags_cloud`, including the `DROP FUNCTION IF EXISTS` lines).
- Leave trigger names (`metka_*_on_table_posts*`) untouched.

Sanity check — this file must end up matching what the updated generator emits. After editing, verify with:

```bash
grep -c "tagged" test/dummy/db/migrate/11_create_table_posts_tags_cloud_table.rb
```

Expected: `0`.

- [ ] **Step 2: Rename and edit the dummy model**

```bash
git mv test/dummy/app/models/tagged_table_post.rb test/dummy/app/models/table_posts_tags_cloud.rb
```

New content (the explicit `table_name` is required — Rails infers the plural `table_posts_tags_clouds` from the class name):

```ruby
# frozen_string_literal: true

class TablePostsTagsCloud < ActiveRecord::Base
  self.table_name = "table_posts_tags_cloud"
end
```

- [ ] **Step 3: Rename and edit the test**

```bash
git mv test/metka/tagged_table_post_test.rb test/metka/table_posts_tags_cloud_test.rb
```

In the renamed file: class `TaggedTablePostTest` → `TablePostsTagsCloudTest`, and every `TaggedTablePost` constant reference → `TablePostsTagsCloud` (10 lines contain it, including the class name; `grep -n TaggedTablePost` afterwards must return nothing). Everything else (fixtures, `TablePost` writes, trigger assertions) stays.

- [ ] **Step 4: Recreate the dummy DB and run the suite**

```bash
DB=sqlite bundle exec rake dummy:db:migrate:reset
DB=sqlite bundle exec ruby -Itest test/metka/table_posts_tags_cloud_test.rb
```

Expected: migration reset succeeds (the renamed migration runs under its new class name); test PASS. If PostgreSQL is available, repeat both commands without `DB=sqlite`.

- [ ] **Step 5: Commit**

```bash
git add -A test/dummy test/metka/table_posts_tags_cloud_test.rb
git commit -m "test(dummy): Rename summary table fixtures to table_posts_tags_cloud

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 3: README

**Files:**
- Modify: `README.md` (table-strategy section, ~lines 336–410)

- [ ] **Step 1: Update the derived-name examples and model example**

Exact edits (line numbers as of commit 281f0ea):

1. Line 345 — the migration-template link: `test/dummy/db/migrate/11_create_tagged_table_posts_table.rb` → `test/dummy/db/migrate/11_create_table_posts_tags_cloud_table.rb` (both the link target and any visible filename).
2. Line 347: `the resulting `tagged_notes` table` → `the resulting `notes_tags_cloud` table`.
3. Line 357 — replace the model sentence with one that carries the pluralization gotcha:

```markdown
And you can also create a model to work with the table as with a Rails model — set the table name explicitly, since Rails would infer the plural `notes_tags_clouds` from the class name:

```ruby
class NotesTagsCloud < ApplicationRecord
  self.table_name = "notes_tags_cloud"
end
```
```

4. Lines 378–385 — the `TaggedSong` model example in "Migrating from on-the-fly tag clouds". This is not a plain rename: like item 3, the new class name needs an explicit table name. Replace the code block and the sentence after it:

```markdown
```ruby
class SongsTagsCloud < ActiveRecord::Base
  self.table_name = "songs_tags_cloud"
end

Song.tag_cloud                                     # before
SongsTagsCloud.pluck(:tag_name, :taggings_count)   # after
```

Sorting and limiting that used to happen in Ruby becomes a normal query: `SongsTagsCloud.order(taggings_count: :desc).limit(50)`.
```

5. Lines 392–406 (the reseeding SQL in the same section): every `tagged_songs` → `songs_tags_cloud` (4 occurrences: two `DELETE FROM`, two `INSERT INTO`). Read the surrounding prose of that section and update any other derived-name mentions to match.

- [ ] **Step 2: Verify no stale names remain**

```bash
grep -n "tagged_notes\|tagged_songs\|tagged_table_posts\|TaggedNote\|TaggedTablePost\|TaggedSong" README.md
```

Expected: no output. (`tagged_with` and prose like "tagged columns" are unrelated and must remain.)

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs: Document <source>_<columns>_cloud naming in README

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 4: Benchmark

**Files:**
- Modify: `benchmark/benchmark.rb`

- [ ] **Step 1: Rename the benchmark's table-strategy table**

In `benchmark/benchmark.rb`, replace:
- every `tagged_metka_table_posts` → `metka_table_posts_tags_cloud` (SQL strings at lines ~172–341, the model's `self.table_name` at 378, `relation_size` at 480, `cloud_mismatches` at 705);
- the PG function names `metka_ins/upd/del_tagged_metka_table_posts` → `metka_ins/upd/del_metka_table_posts_tags_cloud`;
- the model class `TaggedMetkaTablePost` (line 377) → `MetkaTablePostsTagsCloud`, and its one usage (line ~558, the tag-cloud read benchmark).

Leave `benchmark/results.txt` / `benchmark/results.sqlite.txt` untouched — they are recorded outputs of past runs. `benchmark/README.md` never names the table literally; no change.

- [ ] **Step 2: Verify**

```bash
ruby -c benchmark/benchmark.rb
grep -n "tagged_metka\|TaggedMetka" benchmark/benchmark.rb
```

Expected: `Syntax OK`, then no grep output. (Running the benchmark itself needs a seeded DB and minutes of runtime — out of scope; the SQL mirrors the dummy migration verified in Task 2.)

- [ ] **Step 3: Commit**

```bash
git add benchmark/benchmark.rb
git commit -m "bench: Rename table strategy table to metka_table_posts_tags_cloud

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 5: Full-suite verification and sweep

- [ ] **Step 1: Run the whole suite on SQLite**

```bash
DB=sqlite bundle exec rake dummy:db:migrate:reset
DB=sqlite bundle exec rake test
```

Expected: 0 failures, 0 errors.

- [ ] **Step 2: Run the whole suite on PostgreSQL (if available)**

```bash
bundle exec rake dummy:db:create dummy:db:migrate:reset
bundle exec rake test
```

Expected: 0 failures, 0 errors. If no local PG server, note it in the report — CI covers it.

- [ ] **Step 3: Final repo sweep for stale names**

```bash
grep -rn "tagged_notes\|tagged_songs\|tagged_table_posts\|tagged_metka\|TaggedNote\|TaggedTablePost\|TaggedMetka\|TaggedSong" --include="*.rb" --include="*.erb" --include="*.md" . | grep -v benchmark/results | grep -v docs/superpowers
```

Expected: no output (the spec/plan docs and historical results files legitimately mention old names).

- [ ] **Step 4: Commit any stragglers found by the sweep**

Only if Step 3 surfaced something; fix and commit with an appropriate message.
