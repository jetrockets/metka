[![Gem Version](https://badge.fury.io/rb/metka.svg)](https://badge.fury.io/rb/metka)
[![Build Status](https://github.com/jetrockets/metka/workflows/Tests/badge.svg?branch=master)](https://github.com/jetrockets/metka/actions)
[![Open Source Helpers](https://www.codetriage.com/jetrockets/metka/badges/users.svg)](https://www.codetriage.com/jetrockets/metka)

# Metka

A Rails tagging gem built on PostgreSQL array columns. Tags live in an indexed array column right on your table — no join tables, no extra models, no N+1 queries.

:exclamation: Requirements:

* Ruby >= 3.2
* Rails >= 7.1 (for Rails 5.2 to 6.1 use version ~> 2.3, for Rails 5.1 and 5.0 use version <2.1.0)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'metka'
```

And then execute:

```bash
bundle
```

Or install it yourself as:

```bash
gem install metka
```

## Tag objects

```bash
rails g migration CreateSongs
```

```ruby
class CreateSongs < ActiveRecord::Migration[7.1]
  def change
    create_table :songs do |t|
      t.string :title
      t.string :tags, array: true, default: [], index: { using: :gin }
      t.string :genres, array: true, default: [], index: { using: :gin }
      t.timestamps
    end
  end
end
```

```ruby
class Song < ActiveRecord::Base
  include Metka::Model(columns: %w[genres tags])
end

@song = Song.new(title: 'Migrate tags in Rails to PostgreSQL')
@song.tag_list = 'top, chill'
@song.genre_list = 'rock, jazz, pop'
@song.save
```

### Writing tags: `tag_list=` vs the raw column

`tag_list=` (and its per-column siblings like `genre_list=`) is the Metka write
path. Input goes through the configured parser, which splits on the delimiter,
honors quoting, strips blanks, and de-duplicates:

```ruby
@song.tag_list = 'chill, chill, top'
@song.tags
#=> ["chill", "top"]
```

Assigning the array column directly is a plain ActiveRecord attribute write.
Metka does not see it, so nothing is parsed or de-duplicated — and duplicates
stored this way are counted twice by tag clouds, which aggregate the raw array
elements:

```ruby
@song.tags = [ 'chill', 'chill' ]   # stored exactly as given
```

This is by design: the column belongs to your schema, and Metka only owns the
`*_list` API. If you write the column directly, normalizing the array is your
responsibility.

## Find tagged objects

Every scope below builds on PostgreSQL's array operators (`@>` for "all", `&&` for "any"), so queries can use the GIN indexes created in the migration above. Passing an empty string or `nil` returns the unfiltered relation.

### .with_all_#{column_name}

```ruby
Song.with_all_tags('top')
#=> [#<Song id: 1, title: 'Migrate tags in Rails to PostgreSQL', tags: ['top', 'chill'], genres: ['rock', 'jazz', 'pop']]

Song.with_all_tags('top, 1990')
#=> []

Song.with_all_tags('')
#=> [#<Song id: 1, title: 'Migrate tags in Rails to PostgreSQL', tags: ['top', 'chill'], genres: ['rock', 'jazz', 'pop']]

Song.with_all_tags(nil)
#=> [#<Song id: 1, title: 'Migrate tags in Rails to PostgreSQL', tags: ['top', 'chill'], genres: ['rock', 'jazz', 'pop']]

Song.with_all_genres('rock')
#=> [#<Song id: 1, title: 'Migrate tags in Rails to PostgreSQL', tags: ['top', 'chill'], genres: ['rock', 'jazz', 'pop']]
```

### .with_any_#{column_name}

```ruby
Song.with_any_tags('chill')
#=> [#<Song id: 1, title: 'Migrate tags in Rails to PostgreSQL', tags: ['top', 'chill'], genres: ['rock', 'jazz', 'pop']]

Song.with_any_tags('chill, 1980')
#=> [#<Song id: 1, title: 'Migrate tags in Rails to PostgreSQL', tags: ['top', 'chill'], genres: ['rock', 'jazz', 'pop']]

Song.with_any_tags('')
#=> [#<Song id: 1, title: 'Migrate tags in Rails to PostgreSQL', tags: ['top', 'chill'], genres: ['rock', 'jazz', 'pop']]

Song.with_any_tags(nil)
#=> [#<Song id: 1, title: 'Migrate tags in Rails to PostgreSQL', tags: ['top', 'chill'], genres: ['rock', 'jazz', 'pop']]

Song.with_any_genres('rock, rap')
#=> [#<Song id: 1, title: 'Migrate tags in Rails to PostgreSQL', tags: ['top', 'chill'], genres: ['rock', 'jazz', 'pop']]
```

### .without_all_#{column_name}

```ruby
Song.without_all_tags('top')
#=> []

Song.without_all_tags('top, 1990')
#=> [#<Song id: 1, title: 'Migrate tags in Rails to PostgreSQL', tags: ['top', 'chill'], genres: ['rock', 'jazz', 'pop']]

Song.without_all_tags('')
#=> [#<Song id: 1, title: 'Migrate tags in Rails to PostgreSQL', tags: ['top', 'chill'], genres: ['rock', 'jazz', 'pop']]

Song.without_all_tags(nil)
#=> [#<Song id: 1, title: 'Migrate tags in Rails to PostgreSQL', tags: ['top', 'chill'], genres: ['rock', 'jazz', 'pop']]

Song.without_all_genres('rock, pop')
#=> [#<Song id: 1, title: 'Migrate tags in Rails to PostgreSQL', tags: ['top', 'chill'], genres: ['rock', 'jazz', 'pop']]

Song.without_all_genres('rock')
#=> []
```

### .without_any_#{column_name}

```ruby
Song.without_any_tags('top, 1990')
#=> []

Song.without_any_tags('1990, 1980')
#=> [#<Song id: 1, title: 'Migrate tags in Rails to PostgreSQL', tags: ['top', 'chill'], genres: ['rock', 'jazz', 'pop']]

Song.without_any_genres('rock, pop')
#=> []

Song.without_any_genres('')
#=> [#<Song id: 1, title: 'Migrate tags in Rails to PostgreSQL', tags: ['top', 'chill'], genres: ['rock', 'jazz', 'pop']]

Song.without_any_genres(nil)
#=> [#<Song id: 1, title: 'Migrate tags in Rails to PostgreSQL', tags: ['top', 'chill'], genres: ['rock', 'jazz', 'pop']]
```

### .tagged_with

```ruby
Song.tagged_with('top')
#=> [#<Song id: 1, title: 'Migrate tags in Rails to PostgreSQL', tags: ['top', 'chill'], genres: ['rock', 'jazz', 'pop']]

Song.tagged_with('top, 1990')
#=> []

Song.tagged_with('')
#=> [#<Song id: 1, title: 'Migrate tags in Rails to PostgreSQL', tags: ['top', 'chill'], genres: ['rock', 'jazz', 'pop']]

Song.tagged_with(nil)
#=> [#<Song id: 1, title: 'Migrate tags in Rails to PostgreSQL', tags: ['top', 'chill'], genres: ['rock', 'jazz', 'pop']]

Song.tagged_with('rock')
#=> [#<Song id: 1, title: 'Migrate tags in Rails to PostgreSQL', tags: ['top', 'chill'], genres: ['rock', 'jazz', 'pop']]

Song.tagged_with('rock', join_operator: Metka::AND)
#=> []

Song.tagged_with('chill', any: true)
#=> [#<Song id: 1, title: 'Migrate tags in Rails to PostgreSQL', tags: ['top', 'chill'], genres: ['rock', 'jazz', 'pop']]

Song.tagged_with('chill, 1980', any: true)
#=> [#<Song id: 1, title: 'Migrate tags in Rails to PostgreSQL', tags: ['top', 'chill'], genres: ['rock', 'jazz', 'pop']]

Song.tagged_with('', any: true)
#=> [#<Song id: 1, title: 'Migrate tags in Rails to PostgreSQL', tags: ['top', 'chill'], genres: ['rock', 'jazz', 'pop']]

Song.tagged_with('rock, rap', any: true, on: [ 'genres' ])
#=> [#<Song id: 1, title: 'Migrate tags in Rails to PostgreSQL', tags: ['top', 'chill'], genres: ['rock', 'jazz', 'pop']]

Song.tagged_with('top, 1990', exclude: true)
#=> [#<Song id: 1, title: 'Migrate tags in Rails to PostgreSQL', tags: ['top', 'chill'], genres: ['rock', 'jazz', 'pop']]

Song.tagged_with('', exclude: true)
#=> [#<Song id: 1, title: 'Migrate tags in Rails to PostgreSQL', tags: ['top', 'chill'], genres: ['rock', 'jazz', 'pop']]

Song.tagged_with('top, 1990', any: true, exclude: true)
#=> []

Song.tagged_with('1990, 1980', any: true, exclude: true)
#=> [#<Song id: 1, title: 'Migrate tags in Rails to PostgreSQL', tags: ['top', 'chill'], genres: ['rock', 'jazz', 'pop']]
```

`join_operator:` controls how multiple tagged columns combine: `Metka::OR`
(the default) matches when any column satisfies the tags, `Metka::AND` requires
every column to. The plain symbols `:or` and `:and` work too. Anything else
raises `ArgumentError`, as does any option other than `any:`, `exclude:`,
`join_operator:` and `on:`.

## Custom delimiter

By default, a comma is used to split a tag string into tags.
You can configure your own delimiter:

```ruby
Metka.delimiter = '|'

parsed_data = Metka::GenericParser.instance.call('cool, data|I have')
parsed_data.to_a
#=> ['cool, data', 'I have']
```

The setting is global and affects every model that uses the default parser.
`Metka.config.delimiter = '|'` and `Metka.configure { |config| config.delimiter = '|' }`
still work as well.

## Tags with quote

```ruby
parsed_data = Metka::GenericParser.instance.call("'cool, data', code")
parsed_data.to_a
#=> ['cool, data', 'code']
```

## Custom parser

By default tags are parsed with [Metka::GenericParser](lib/metka/generic_parser.rb "generic_parser").
To plug in your own parser for a specific model:

```ruby
class Song < ActiveRecord::Base
  include Metka::Model(columns: %w[genres tags], parser: Your::Custom::Parser.instance)
end
```

A parser is any object that responds to `call`, accepts the raw tag value (a
string or an array) and returns a `Metka::TagList`. The simplest approach is to
subclass `Metka::GenericParser`. You can also replace the parser globally with
`Metka.parser = Your::Custom::Parser` — note that the global setting takes the
singleton class itself, and `.instance` is called on it at parse time.

## Tag Cloud Strategies

There are several strategies to get tag statistics. The ActiveRecord Strategy is what you get out of the box with zero setup; for anything beyond occasional clouds on small tables, the [Table Strategy](#table-strategy-with-triggers-recommended) is the recommended default — it reads like a pre-aggregated table and writes within measurement noise of having no strategy at all (see the [benchmark](#benchmark-comparison)).

### ActiveRecord Strategy (Zero Setup)

Tagging statistics are available via class methods on any model that includes `Metka::Model`. You can build a cloud for a single tagged column or for several at once — in the latter case each tag's count is summed across the given columns. The ActiveRecord strategy is the easiest to use since it requires no additional code, but it is the slowest one on SELECT.

```ruby
class Book < ActiveRecord::Base
  include Metka::Model(columns: %w[authors co_authors])
end

author_cloud = Book.author_cloud
#=> [["L.N. Tolstoy", 3], ["F.M. Dostoevsky", 6]]
co_author_cloud = Book.co_author_cloud
#=> [["A.P. Chekhov", 5], ["N.V. Gogol", 8], ["L.N. Tolstoy", 2]]
summary_cloud = Book.metka_cloud('authors', 'co_authors')
#=> [["L.N. Tolstoy", 5], ["F.M. Dostoevsky", 6], ["A.P. Chekhov", 5], ["N.V. Gogol", 8]]
```

`metka_cloud` accepts only columns declared in `Metka::Model`; anything else
raises `ArgumentError`.

### View Strategy

Tagging data is aggregated in an SQL view. Performance-wise this strategy has no benefits over the ActiveRecord strategy, but if you want to expose tag aggregations as a separate model, this is the easiest way to do it.

```bash
rails g metka:strategies:view --source-table-name=NAME_OF_TABLE_WITH_TAGS [--source-columns=NAME_OF_COLUMN_1 NAME_OF_COLUMN_2] [--view-name=NAME_OF_RESULTING_VIEW]
```

The command generates a migration that creates a view aggregating tag data from the listed tagged columns of `NAME_OF_TABLE_WITH_TAGS`.

* If `--source-columns` is omitted, the `tags` column is used by default. When several columns are given, a tag found in more than one of them gets a single row in the view with the sum of its occurrences across all those columns.
* `--view-name` is optional too. Without it, the view name is derived from the table and column names — you can see it in the generated migration.

Let's take a look at a real example. We have a `notes` table with a `tags` column.

| Column | Type                | Default                           |
|--------|---------------------|-----------------------------------|
| id     | integer             | nextval('notes_id_seq'::regclass) |
| body   | text                |                                   |
| tags   | character varying[] | '{}'::character varying[]         |

Now let's generate a migration.

```bash
rails g metka:strategies:view --source-table-name=notes
```

The result would be:

```ruby
# frozen_string_literal: true

class CreateTaggedNotesView < ActiveRecord::Migration[5.0]
  def up
    execute <<-SQL
    CREATE OR REPLACE VIEW tagged_notes AS
      SELECT
        tag_name,
        COUNT(*) AS taggings_count
      FROM (
        SELECT UNNEST
          (tags) AS tag_name
        FROM
          notes
      ) subquery
      GROUP BY
        tag_name;
    SQL
  end

  def down
    execute <<-SQL
      DROP VIEW tagged_notes;
    SQL
  end
end
```

Now let's take a look at the `tagged_notes` view.

| tag_name | taggings_count |
|----------|----------------|
| Ruby     | 124056         |
| React    | 30632          |
| Rails    | 28696          |
| Crystal  | 6566           |
| Elixir   | 3475           |

Now you can create `TaggedNote` model and work with the view like you usually do with Rails models.

### Materialized View Strategy

Tagging data is aggregated in an SQL materialized view that is refreshed by statement-level triggers — once per INSERT, UPDATE or DELETE statement that changes the tagged columns' data, no matter how many rows the statement touches. Apart from the type of view being used, this strategy behaves the same way as the View Strategy above.

```bash
rails g metka:strategies:materialized_view --source-table-name=NAME_OF_TABLE_WITH_TAGS [--source-columns=NAME_OF_COLUMN_1 NAME_OF_COLUMN_2] [--view-name=NAME_OF_RESULTING_VIEW]
```

All of the options are the same as for the View Strategy.

The migration template can be seen [here](test/dummy/db/migrate/06_create_tagged_materialized_view_posts_materialized_view.rb "here")

With the same `notes` table and `tags` column, the resulting view has the same two columns

| tag_name | taggings_count |
|----------|----------------|
| Ruby     | 124056         |
| React    | 30632          |
| Rails    | 28696          |
| Crystal  | 6566           |
| Elixir   | 3475           |

And you can also create `TaggedNote` model to work with the view as with a Rails model.

### Table Strategy with Triggers (Recommended)

Data about taggings will be maintained in a real table with the same two columns as the views above, kept up to date by statement-level triggers. Instead of recomputing the whole aggregation like the Materialized View Strategy does on every refresh, the triggers read the statement's transition tables and apply per-tag deltas, so a write statement only touches the counters of the tags it actually changed. That keeps writes within measurement noise of a table with no triggers at all while reads stay as fast as a plain indexed table — the trade-off is that it is an ordinary table, so anything that writes `NAME_OF_TABLE_WITH_TAGS` without firing the triggers (`TRUNCATE`, restoring from a dump) leaves the counters stale until you reseed the table by hand. The same ownership caveat as for raw column writes applies: keeping the counters honest is your responsibility the moment you go around the write path.

```bash
rails g metka:strategies:table --source-table-name=NAME_OF_TABLE_WITH_TAGS --source-columns=NAME_OF_COLUMN_1 NAME_OF_COLUMN_2 --table-name=NAME_OF_RESULTING_TABLE
```

All of the options for that strategy's generation command are the same as for the View Strategy, except that the resulting table's name is forced with `table-name` instead of `view-name`.

The generated migration creates the table, seeds it from the rows already present in `NAME_OF_TABLE_WITH_TAGS`, and installs one statement-level trigger per operation (`INSERT`, `UPDATE`, `DELETE`). The migration template can be seen [here](test/dummy/db/migrate/11_create_tagged_table_posts_table.rb "here")

With the same `notes` table with `tags` column the resulting table would have the same two columns

| tag_name | taggings_count |
|----------|----------------|
| Ruby     | 124056         |
| React    | 30632          |
| Rails    | 28696          |
| Crystal  | 6566           |
| Elixir   | 3475           |

And you can also create `TaggedNote` model to work with the table as with a Rails model.

#### Migrating from on-the-fly tag clouds

If you already tag rows with Metka and serve clouds straight off the model — `Song.tag_cloud`, `Book.author_cloud`, `Book.metka_cloud('authors', 'co_authors')` — the generated migration doubles as the migration path. It backfills the summary table from your existing rows and installs the triggers in the same transaction, locking the source table against writes (reads are not blocked) so no statement can slip between the backfill and the triggers; the counts are exact from the moment the migration commits, even under live traffic.

Generate and run the migration, listing every column your cloud aggregates:

```bash
rails g metka:strategies:table --source-table-name=songs
```

```bash
rails db:migrate
```

For a multi-column cloud like `Book.metka_cloud('authors', 'co_authors')` pass `--source-columns=authors co_authors`, and the seeded counts sum both columns exactly like `metka_cloud` does.

Add a model for the summary table and swap the call sites — `tag_cloud` returns `[tag_name, count]` pairs, and the summary table stores the same data one row per tag:

```ruby
class TaggedSong < ActiveRecord::Base
end

Song.tag_cloud                                # before
TaggedSong.pluck(:tag_name, :taggings_count)  # after
```

Sorting and limiting that used to happen in Ruby becomes a normal query: `TaggedSong.order(taggings_count: :desc).limit(50)`.

Nothing about how you write tags changes: `tag_list=` and friends keep working, and the triggers keep the counts in step with every `INSERT`, `UPDATE` and `DELETE`, including bulk statements like `insert_all`, `update_all` and `delete_all`. If you ever write around the triggers (`TRUNCATE`, restoring from a dump), rebuild the table the same way the migration seeded it:

```sql
BEGIN;
LOCK TABLE songs IN SHARE ROW EXCLUSIVE MODE;
DELETE FROM tagged_songs;
INSERT INTO tagged_songs (tag_name, taggings_count)
  SELECT tag_name, COUNT(*)
  FROM (SELECT UNNEST(tags) AS tag_name FROM songs) subquery
  GROUP BY tag_name;
COMMIT;
```

## Inspired by

1. [ActsAsTaggableOn](https://github.com/mbleigh/acts-as-taggable-on)
2. [ActsAsTaggableArrayOn](https://github.com/tmiyamon/acts-as-taggable-array-on)
3. [TagColumns](https://github.com/hopsoft/tag_columns)

## Migration from ActsAsTaggable

Migrating your data from `ActsAsTaggable` can be done with a migration like the following.

```ruby
class AddTagsToYourTable < ActiveRecord::Migration[7.1]
  def change
    add_column :your_table, :tags, :string, array: true
    add_index :your_table, :tags, using: 'gin'

    execute <<~SQL
      UPDATE your_table
      SET tags = tags.names
      FROM (
        SELECT taggings.taggable_id AS your_table_id,
               array_agg(tags.name) as names
        FROM tags
        INNER JOIN taggings
                ON tags.id = taggings.tag_id
        WHERE
          taggings.taggable_type = 'YourTableType'
        GROUP BY taggings.taggable_id
      ) as tags
      WHERE your_table.id = tags.your_table_id
    SQL
  end
end
```

## Benchmark Comparison

Metka ships a [benchmark suite](benchmark/) comparing it to
[acts-as-taggable-on](https://github.com/mbleigh/acts-as-taggable-on),
[acts-as-taggable-array-on](https://github.com/tmiyamon/acts-as-taggable-array-on),
[gutentag](https://github.com/pat/gutentag) and
[tag_columns](https://github.com/hopsoft/tag_columns) on a shared dataset:
10,000 posts per gem, 5 tags per post from a 100-tag vocabulary, identical
seeded tag assignments. Iterations per second, higher is better (Ruby 4.0,
Rails 8.1, PostgreSQL 18):

| Operation | metka | taggable-array | tag_columns | acts-as-taggable-on | gutentag |
| --- | --- | --- | --- | --- | --- |
| Query: ALL of 2 tags, load records | 6,393 | 6,606 | 970 | 2,380 | 1,292 |
| Query: ANY of 2 tags, count | 4,629 | 4,625 | 679 | 791 | 1,026 |
| Tag cloud over all posts | 209 | 197 | 194 | 126 | 158 |
| Create post with 5 tags | 1,631 | 1,636 | 1,579 | 196 | 183 |
| Replace tags of existing post | 8,122 | 7,480 | 7,158 | 186 | 176 |
| Bulk seed 10k posts | 0.21 s | 0.17 s | 0.16 s | 51.6 s | 49.5 s |
| Storage, tables + indexes | 2.68 MB | 2.68 MB | 2.68 MB | 17.64 MB | 11.87 MB |

The suite also measures what each tag-cloud strategy costs on the same
dataset — reads via the maintained aggregate against the write overhead of
keeping it fresh:

| Tag-cloud strategy | Cloud read | Create post | Replace tags | Bulk seed | Storage |
| --- | --- | --- | --- | --- | --- |
| none (live aggregation) | 209 | 1,631 | 8,122 | 0.21 s | 2.68 MB |
| materialized_view | 9,082 | 133 | 173 | 0.24 s | 2.78 MB |
| table | 9,337 | 1,524 | 7,696 | 0.17 s | 2.75 MB |

Keep in mind that these results alone can't prove one solution better than
the others — each gem has unique features. The join-table gems maintain a
normalized tag vocabulary (global renames, tag metadata, cross-model tags)
that array columns don't provide; their storage and write overhead buys those
features. See [benchmark/README.md](benchmark/README.md) for methodology,
analysis of the generated SQL and query plans, and instructions for running
the suite yourself.

## Development

After checking out the repo, run `bin/setup` to install dependencies and prepare the test database (a running PostgreSQL server is required). Then run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/jetrockets/metka](https://github.com/jetrockets/metka). This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## Credits

Metka is maintained by [JetRockets](https://jetrockets.com).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Metka project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/jetrockets/metka/blob/master/CODE_OF_CONDUCT.md).
