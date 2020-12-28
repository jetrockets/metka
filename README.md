[![Gem Version](https://badge.fury.io/rb/metka.svg)](https://badge.fury.io/rb/metka)
[![Build Status](https://github.com/jetrockets/metka/workflows/Build/badge.svg?branch=master)](https://github.com/jetrockets/metka/actions)
[![Open Source Helpers](https://www.codetriage.com/jetrockets/metka/badges/users.svg)](https://www.codetriage.com/jetrockets/metka)

# Metka

Rails gem to manage tags with PostgreSQL array columns.

:exclamation: Requirements:

* Ruby ~> 2.5
* Rails >= 5.2 (for Rails 5.1 and 5.0 use version <2.1.0)

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
class CreateSongs < ActiveRecord::Migration[5.0]
  def change
    create_table :songs do |t|
      t.string :title
      t.string :tags, array: true
      t.string :genres, array: true
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

## Find tagged objects

### .with_all_#{column_name}

```ruby
Song.with_all_tags('top')
#=> [#<Song id: 1, title: 'Migrate tags in Rails to PostgreSQL', tags: ['top', 'chill'], genres: ['rock', 'jazz', 'pop']]

Song.with_all_tags('top, 1990')
#=> []

Song.with_all_tags('')
#=> []

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
#=> []

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
#=> []

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
#=> []
```

### .tagged_with

```ruby
Song.tagged_with('top')
#=> [#<Song id: 1, title: 'Migrate tags in Rails to PostgreSQL', tags: ['top', 'chill'], genres: ['rock', 'jazz', 'pop']]

Song.tagged_with('top, 1990')
#=> []

Song.tagged_with('')
#=> []

Song.tagged_with('rock')
#=> [#<Song id: 1, title: 'Migrate tags in Rails to PostgreSQL', tags: ['top', 'chill'], genres: ['rock', 'jazz', 'pop']]

Song.tagged_with('rock', join_operator: Metka::And)
#=> []

Song.tagged_with('chill', any: true)
#=> [#<Song id: 1, title: 'Migrate tags in Rails to PostgreSQL', tags: ['top', 'chill'], genres: ['rock', 'jazz', 'pop']]

Song.tagged_with('chill, 1980', any: true)
#=> [#<Song id: 1, title: 'Migrate tags in Rails to PostgreSQL', tags: ['top', 'chill'], genres: ['rock', 'jazz', 'pop']]

Song.tagged_with('', any: true)
#=> []

Song.tagged_with('rock, rap', any: true, on: ['genres'])
#=> [#<Song id: 1, title: 'Migrate tags in Rails to PostgreSQL', tags: ['top', 'chill'], genres: ['rock', 'jazz', 'pop']]

Song.without_all_tags('top')
#=> []

Song.tagged_with('top, 1990', exclude: true)
#=> [#<Song id: 1, title: 'Migrate tags in Rails to PostgreSQL', tags: ['top', 'chill'], genres: ['rock', 'jazz', 'pop']]

Song.tagged_with('', exclude: true)
#=> []

Song.tagged_with('top, 1990', any: true, exclude: true)
#=> []

Song.tagged_with('1990, 1980', any: true, exclude: true)
#=> [#<Song id: 1, title: 'Migrate tags in Rails to PostgreSQL', tags: ['top', 'chill'], genres: ['rock', 'jazz', 'pop']]

Song.without_any_genres('rock, pop')
#=> []
```

## Custom delimiter

By default, a comma is used as a delimiter to create tags from a string.
You can make your own custom separator:

```ruby
Metka.config.delimiter = '|'
parsed_data = Metka::GenericParser.instance.call('cool, data|I have')
parsed_data.to_a
#=>['cool, data', 'I have']
```

## Tags with quote

```ruby
parsed_data = Metka::GenericParser.instance.call("'cool, data', code")
parsed_data.to_a
#=> ['cool, data', 'code']
```

## Custom parser

By default we use [generic_parser](lib/metka/generic_parser.rb "generic_parser")
If you want to use your custom parser you can do:

```ruby
class Song < ActiveRecord::Base
  include Metka::Model(columns: %w[genres tags], parser: Your::Custom::Parser.instance)
end
```

Custom parser must be a singleton class that has a `.call` method that accepts the tag string

## Tag Cloud Strategies

There are several strategies to get tag statistics

### ActiveRecord Strategy (Default)

Data about taggings is accessible via class methods of your model with `Metka::Model` attached. You can calculate a cloud for a single tagged column or multiple columns, the latter case would return to you a sum of taggings from multiple tagged columns, that are provided as arguments, for each tag present. ActiveRecord Strategy is an easiest way to implement, since it wouldn't require any additional code, but it's the slowest one on SELECT.

```ruby

class Book < ActiveRecord::Base
  include Metka::Model(column: 'authors')
  include Metka::Model(column: 'co_authors')
end

tag_cloud = Book.author_cloud
#=> [["L.N. Tolstoy", 3], ["F.M. Dostoevsky", 6]]
genre_cloud = Book.co_author_cloud
#=> [["A.P. Chekhov", 5], ["N.V. Gogol", 8], ["L.N. Tolstoy", 2]]
summary_cloud = Book.metka_cloud('authors', 'co_authors')
#=> [["L.N. Tolstoy", 5], ["F.M. Dostoevsky", 6], ["A.P. Chekhov", 5], ["N.V. Gogol", 8]]
```

### View Strategy

Data about taggings will be aggregated in SQL View. Performance-wise that strategy has no benefits over ActiveRecord Strategy, but if you need to store tags aggregations in a distinct model, that's an easiest way to achieve it.

```bash
rails g metka:strategies:view --source-table-name=NAME_OF_TABLE_WITH_TAGS [--source-columns=NAME_OF_COLUMN_1 NAME_OF_COLUMN_2] [--view-name=NAME_OF_RESULTING_VIEW]
```

The code above will generate a migration that creates view with specified `NAME_OF_RESULTING_VIEW`, that would aggregate tags data from specified array of tagged columns [`NAME_OF_COLUMN_1`, `NAME_OF_COLUMN_2`, ...], that are present within specified table `NAME_OF_TABLE_WITH_TAGS`.
If `source-columns` option is not provided, then `tags` column would be used as defaults. If array of multiple values would be provided to the option, then the aggregation would be made with the tags from multiple tagged columns, so if a single tag would be found within multiple tagged columns, the resulting aggregation inside the view would have a single row for that tag with a sum of it's occurrences across all stated tagged columns.
`view-name` option is also optional, it would just force the resulting view's name to the one of your choice. If it's not provided, then view name would be generated automatically, you could check it within generated migration.

Lets take a look at real example. We have a `notes` table with `tags` column.

| Column | Type                | Default                           |
|--------|---------------------|-----------------------------------|
| id     | integer             | nextval('notes_id_seq'::regclass) |
| body   | text                |                                   |
| tags   | character varying[] | '{}'::character varying[]         |

Now lets generate a migration.

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
          COUNT ( * ) AS taggings_count
        FROM (
          SELECT UNNEST
            ( tags ) AS tag_name
          FROM
            view_posts
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

Now lets take a look at `tagged_notes` view.

| tag_name | taggings_count |
|----------|----------------|
| Ruby     | 124056         |
| React    | 30632          |
| Rails    | 28696          |
| Crystal  | 6566           |
| Elixir   | 3475           |

Now you can create `TaggedNote` model and work with the view like you usually do with Rails models.

### Materialized View Strategy

Data about taggings will be aggregated in SQL Materialized View, that would be refreshed with the trigger on each change of the tagged column's data. Except for the another type of view being used, that strategy behaves the same way, as a View Strategy above.

```bash
rails g metka:strategies:materialized_view --source-table-name=NAME_OF_TABLE_WITH_TAGS --source-columns=NAME_OF_COLUMN_1 NAME_OF_COLUMN_2 --view-name=NAME_OF_RESULTING_VIEW
```

All of the options for that strategy's generation command are the same as for the View Strategy.

The migration template can be seen [here](spec/dummy/db/migrate/06_create_tagged_materialized_view_posts_materialized_view.rb "here")

With the same `notes` table with `tags` column the resulting view would have the same two columns

| tag_name | taggings_count |
|----------|----------------|
| Ruby     | 124056         |
| React    | 30632          |
| Rails    | 28696          |
| Crystal  | 6566           |
| Elixir   | 3475           |

And you can also create `TaggedNote` model to work with the view as with a Rails model.

### Table Strategy with Triggers

TBD

## Inspired by

1. [ActsAsTaggableOn](https://github.com/mbleigh/acts-as-taggable-on)
2. [ActsAsTaggableArrayOn](https://github.com/tmiyamon/acts-as-taggable-array-on)
3. [TagColumns](https://github.com/hopsoft/tag_columns)

## Benchmark Comparison

There are some results of benchmarking a performance of write, read and find operations for different gems, that provide solution for tagging. Keep in mind, that those results can't be used as a proof, that some solution is better than the others, since each of the benchmarked gems has their unique features. You could run the benchmarks yourself or check, what exact operations has been used for benchmarking, with [MetkaBench application](https://github.com/jetrockets/metka_bench).

```bash
$ rake bench:all
Deleted all MetkaSong
Deleted all ActsAsTaggableOn::Tagging
Deleted all ActsAsTaggableOn::Tag
Deleted all ActsAsTaggableSong
Deleted all ActsAsTaggableArraySong
Deleted all TagColumnsSong
Finished to clean

###################################################################

bench:write

Time measurements:

Rehearsal ----------------------------------------------------------
Metka:                   2.192410   0.161092   2.353502 (  2.754766)
ActsAsTaggableOn:       13.769918   0.554951  14.324869 ( 16.990127)
ActsAsTaggableOnArray:   2.150441   0.154127   2.304568 (  2.700022)
TagColumns:              2.202647   0.156162   2.358809 (  2.753400)
------------------------------------------------ total: 21.341748sec

                             user     system      total        real
Metka:                   2.137315   0.154046   2.291361 (  2.643363)
ActsAsTaggableOn:       11.302848   0.448674  11.751522 ( 14.019458)
ActsAsTaggableOnArray:   2.143134   0.128655   2.271789 (  2.670797)
TagColumns:              2.133780   0.125749   2.259529 (  2.653404)

Memory measurements:

Calculating -------------------------------------
Metka:                   179.064M memsize (     0.000  retained)
                           1.689M objects (     0.000  retained)
                          50.000  strings (     0.000  retained)
ActsAsTaggableOn:        843.949M memsize (     0.000  retained)
                           8.550M objects (     0.000  retained)
                          50.000  strings (     0.000  retained)
ActsAsTaggableOnArray:   178.807M memsize (     0.000  retained)
                           1.684M objects (     0.000  retained)
                          50.000  strings (     0.000  retained)
TagColumns:              180.009M memsize (     0.000  retained)
                           1.699M objects (     0.000  retained)
                          50.000  strings (     0.000  retained)

###################################################################

bench:read

Time measurements:

Rehearsal ----------------------------------------------------------
Metka:                   0.479695   0.044399   0.524094 (  0.590616)
ActsAsTaggableOn:        2.436328   0.140581   2.576909 (  3.096142)
ActsAsTaggableOnArray:   0.515198   0.042127   0.557325 (  0.623205)
TagColumns:              0.518363   0.042661   0.561024 (  0.626968)
------------------------------------------------- total: 4.219352sec

                             user     system      total        real
Metka:                   0.446751   0.041886   0.488637 (  0.554018)
ActsAsTaggableOn:        2.395166   0.164500   2.559666 (  3.069655)
ActsAsTaggableOnArray:   0.439608   0.041682   0.481290 (  0.544679)
TagColumns:              0.435404   0.041623   0.477027 (  0.540359)

Memory measurements:

Calculating -------------------------------------
Metka:                    42.291M memsize (     0.000  retained)
                         388.694k objects (     0.000  retained)
                          50.000  strings (     0.000  retained)
ActsAsTaggableOn:        178.664M memsize (     0.000  retained)
                           1.812M objects (     0.000  retained)
                          50.000  strings (     0.000  retained)
ActsAsTaggableOnArray:    42.173M memsize (     0.000  retained)
                         383.003k objects (     0.000  retained)
                          50.000  strings (     0.000  retained)
TagColumns:               41.948M memsize (     0.000  retained)
                         383.003k objects (     0.000  retained)
                          50.000  strings (     0.000  retained)

###################################################################

bench:find_by_tag

Time measurements:

Rehearsal ----------------------------------------------------------
Metka:                   0.029961   0.000059   0.030020 (  0.030052)
ActsAsTaggableOn:        0.067095   0.000068   0.067163 (  0.067205)
ActsAsTaggableOnArray:   0.043156   0.000133   0.043289 (  0.043440)
TagColumns:              0.056475   0.000143   0.056618 (  0.056697)
------------------------------------------------- total: 0.197090sec

                             user     system      total        real
Metka:                   0.028291   0.000019   0.028310 (  0.028321)
ActsAsTaggableOn:        0.065925   0.000036   0.065961 (  0.065989)
ActsAsTaggableOnArray:   0.043214   0.000079   0.043293 (  0.043361)
TagColumns:              0.056390   0.000160   0.056550 (  0.056666)

Memory measurements:

Calculating -------------------------------------
Metka:                     4.752M memsize (     0.000  retained)
                          43.000k objects (     0.000  retained)
                           1.000  strings (     0.000  retained)
ActsAsTaggableOn:          8.967M memsize (     0.000  retained)
                          81.002k objects (     0.000  retained)
                           9.000  strings (     0.000  retained)
ActsAsTaggableOnArray:     5.211M memsize (     0.000  retained)
                          57.003k objects (     0.000  retained)
                           6.000  strings (     0.000  retained)
TagColumns:                6.696M memsize (     0.000  retained)
                          94.003k objects (     0.000  retained)
                           8.000  strings (     0.000  retained)

Finished all benchmarks
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/jetrockets/metka](https://github.com/jetrockets/metka). This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## Credits

![JetRockets](https://media.jetrockets.pro/jetrockets-white.png)
Metka is maintained by [JetRockets](http://www.jetrockets.ru).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Metka project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/metka/blob/master/CODE_OF_CONDUCT.md).
