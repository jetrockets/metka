# Table-Strategy Summary Table Naming: `<source_table>_<columns>_cloud`

**Date:** 2026-08-18
**Status:** Approved by user
**Target:** 3.0 release

## Problem

The table strategy generator derives its summary table name as
`tagged_<source_table>` (e.g. `tagged_songs`), or
`tagged_with_<columns>_<source_table>` when non-default source columns are
given (e.g. `tagged_with_tags_and_genres_posts`). The prefix style reads
poorly, sorts the table away from its source table in the schema, and is
inconsistent with the index strategy, which names its tables
`<source_table>_<column>_index` (e.g. `posts_tags_index`).

The summary table is not a taggings join table: it holds one row per tag
(`tag_name varchar PRIMARY KEY, taggings_count bigint`) — a tag-cloud
aggregate maintained by triggers. The name should describe that.

## Decision

Rename the derived default to `<source_table>_<columns>_cloud`, with columns
joined by `_and_`, uniformly — no special case for the default `tags` column:

| Input | Old derived name | New derived name |
|---|---|---|
| `--source-table-name=songs` | `tagged_songs` | `songs_tags_cloud` |
| `--source-table-name=posts --source-columns=tags genres` | `tagged_with_tags_and_genres_posts` | `posts_tags_and_genres_cloud` |

This mirrors the index strategy's `<source_table>_<column>_index` pattern, so
the two strategies' tables read as siblings in the schema
(`songs_tags_cloud`, `songs_tags_index`), and matches the feature's name
throughout the README and API (`tag_cloud`).

Alternatives considered and rejected:

- `song_taggings` (`<singular>_taggings`): Rails-idiomatic, but in the Rails
  ecosystem "taggings" implies a join table with one row per tagging;
  this table holds per-tag counts, so the name misleads schema readers.
- `song_tag_counts`: semantically precise but breaks symmetry with the index
  strategy and derives awkwardly for non-default columns.

## Changes

### Generator (the only code change)

`lib/generators/metka/strategies/table/table_generator.rb` — `table_name`
becomes:

```ruby
def table_name
  return options[:table_name] if options[:table_name]

  "#{source_table_name}_#{source_columns_names}_cloud"
end
```

- The migration name keeps its existing `create_#{table_name}_table`
  derivation (→ `create_songs_tags_cloud_table`).
- The `--table-name` option remains as the override, unchanged.

### Templates: no changes

Both `migration.rb.erb` (PostgreSQL) and `migration.sqlite.rb.erb` (SQLite)
interpolate `<%= table_name %>` throughout — trigger function names become
`metka_ins_songs_tags_cloud()` etc. automatically. Trigger names derive from
the source table and columns, not the summary table, so they are untouched.

### Docs and fixtures (model the new convention)

- `test/generators/strategies/table_generator_test.rb`: expected table and
  migration names, including the trigger-function name assertions
  (`metka_ins_tagged_notes` → `metka_ins_notes_tags_cloud`); trigger-name
  assertions (`metka_ins_on_notes_...`) stay as they are.
- `README.md` table-strategy section: `tagged_notes` → `notes_tags_cloud`,
  `TaggedNote` → `NotesTagsCloud`, and the derived-name explanation.
- Dummy app: `test/dummy/db/migrate/11_create_tagged_table_posts_table.rb`
  and the `TaggedTablePost` model/test rename to the new convention
  (summary table `table_posts_tags_cloud`).
- `benchmark/benchmark.rb`: table strategy table (`tagged_metka_table_posts`)
  renamed to match. `benchmark/README.md` never names the table literally, so
  it needs no change.

Pluralization note: Rails infers `notes_tags_clouds` (plural) from a model
named `NotesTagsCloud`, so the renamed dummy model and the README example
model must set `self.table_name = "notes_tags_cloud"` explicitly — the old
`TaggedNote` → `tagged_notes` inference worked by accident of the naming.

## Compatibility

Generation-time only. The table name is baked into a migration when the user
runs the generator; no runtime code derives or reads the `tagged_` prefix.
Existing installs keep their `tagged_*` tables and working triggers untouched;
only newly generated migrations change. No deprecation shim is needed. The
README is the only doc surface (no CHANGELOG file in the repo).

## Testing

- Updated generator tests assert the new derived names for the default and
  multi-column cases, and that `--table-name` still overrides.
- Existing dummy-app trigger tests run against the renamed summary table,
  proving the templates work unchanged with the new name.

No new test types are needed.
