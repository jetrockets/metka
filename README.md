[![Gem Version](https://badge.fury.io/rb/metka.svg)](https://badge.fury.io/rb/metka)
[![Build Status](https://travis-ci.org/jetrockets/metka.svg?branch=master)](https://travis-ci.org/jetrockets/metka)
[![Open Source Helpers](https://www.codetriage.com/jetrockets/metka/badges/users.svg)](https://www.codetriage.com/jetrockets/metka)

# Metka

Rails gem to manage tags with PostgreSQL array columns.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'metka'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install metka

## Tag objects

```bash
rails g migration CreateSongs
```

```ruby
class CreateSongs < ActiveRecord::Migration[5.0]
  def change
    create_table :songs do |t|
      t.string  :title
      t.string  :tags, array: true
      t.string  :genres, array: true
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
=> [#<Song id: 1, title: 'Migrate tags in Rails to PostgreSQL', tags: ['top', 'chill'], genres: ['rock', 'jazz', 'pop']]

Song.with_all_tags('top, 1990')
=> []

Song.with_all_tags('')
=> []

Song.with_all_genres('rock')
=> [#<Song id: 1, title: 'Migrate tags in Rails to PostgreSQL', tags: ['top', 'chill'], genres: ['rock', 'jazz', 'pop']]
```

### .with_any_#{column_name}
```ruby
Song.with_any_tags('chill')
=> [#<Song id: 1, title: 'Migrate tags in Rails to PostgreSQL', tags: ['top', 'chill'], genres: ['rock', 'jazz', 'pop']]

Song.with_any_tags('chill, 1980')
=> [#<Song id: 1, title: 'Migrate tags in Rails to PostgreSQL', tags: ['top', 'chill'], genres: ['rock', 'jazz', 'pop']]

Song.with_any_tags('')
=> []

Song.with_any_genres('rock, rap')
=> [#<Song id: 1, title: 'Migrate tags in Rails to PostgreSQL', tags: ['top', 'chill'], genres: ['rock', 'jazz', 'pop']]
```
### .without_all_#{column_name}
```ruby
Song.without_all_tags('top')
=> []

Song.without_all_tags('top, 1990')
=> [#<Song id: 1, title: 'Migrate tags in Rails to PostgreSQL', tags: ['top', 'chill'], genres: ['rock', 'jazz', 'pop']]

Song.without_all_tags('')
=> []

Song.without_all_genres('rock, pop')
=> [#<Song id: 1, title: 'Migrate tags in Rails to PostgreSQL', tags: ['top', 'chill'], genres: ['rock', 'jazz', 'pop']]

Song.without_all_genres('rock')
=> []
```

### .without_any_#{column_name}
```ruby
Song.without_any_tags('top, 1990')
=> []

Song.without_any_tags('1990, 1980')
=> [#<Song id: 1, title: 'Migrate tags in Rails to PostgreSQL', tags: ['top', 'chill'], genres: ['rock', 'jazz', 'pop']]

Song.without_any_genres('rock, pop')
=> []

Song.without_any_genres('')
=> []
```

### .tagged_with
```ruby
Song.tagged_with('top')
=> [#<Song id: 1, title: 'Migrate tags in Rails to PostgreSQL', tags: ['top', 'chill'], genres: ['rock', 'jazz', 'pop']]

Song.tagged_with('top, 1990')
=> []

Song.tagged_with('')
=> []

Song.tagged_with('rock')
=> [#<Song id: 1, title: 'Migrate tags in Rails to PostgreSQL', tags: ['top', 'chill'], genres: ['rock', 'jazz', 'pop']]

Song.tagged_with('rock', join_operator: Metka::And)
=> []

Song.tagged_with('chill', any: true)
=> [#<Song id: 1, title: 'Migrate tags in Rails to PostgreSQL', tags: ['top', 'chill'], genres: ['rock', 'jazz', 'pop']]

Song.tagged_with('chill, 1980', any: true)
=> [#<Song id: 1, title: 'Migrate tags in Rails to PostgreSQL', tags: ['top', 'chill'], genres: ['rock', 'jazz', 'pop']]

Song.tagged_with('', any: true)
=> []

Song.tagged_with('rock, rap', any: true, on: ['genres'])
=> [#<Song id: 1, title: 'Migrate tags in Rails to PostgreSQL', tags: ['top', 'chill'], genres: ['rock', 'jazz', 'pop']]

Song.without_all_tags('top')
=> []

Song.tagged_with('top, 1990', exclude: true)
=> [#<Song id: 1, title: 'Migrate tags in Rails to PostgreSQL', tags: ['top', 'chill'], genres: ['rock', 'jazz', 'pop']]

Song.tagged_with('', exclude: true)
=> []

Song.tagged_with('top, 1990', any: true, exclude: true)
=> []

Song.tagged_with('1990, 1980', any: true, exclude: true)
=> [#<Song id: 1, title: 'Migrate tags in Rails to PostgreSQL', tags: ['top', 'chill'], genres: ['rock', 'jazz', 'pop']]

Song.without_any_genres('rock, pop')
=> []
```

## Custom delimiter
By default, a comma is used as a delimiter to create tags from a string.
You can make your own custom separator:
```ruby
Metka.config.delimiter = [',', ' ', '|']
parsed_data = Metka::GenericParser.instance.call('cool, data|I have')
parsed_data.to_a
=>['cool', 'data', 'I', 'have']
```

## Tags with quote
```ruby
parsed_data = Metka::GenericParser.instance.call("'cool, data', code")
parsed_data.to_a
=> ['cool, data', 'code']
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
=> [["L.N. Tolstoy", 3], ["F.M. Dostoevsky", 6]]
genre_cloud = Book.co_author_cloud
=> [["A.P. Chekhov", 5], ["N.V. Gogol", 8], ["L.N. Tolstoy", 2]]
summary_cloud = Book.metka_cloud('authors', 'co_authors')
=> [["L.N. Tolstoy", 5], ["F.M. Dostoevsky", 6], ["A.P. Chekhov", 5], ["N.V. Gogol", 8]]
```

### View Strategy

Data about taggings will be agregated in SQL View. Performance-wise that strategy has no benefits over ActiveRecord Strategy, but if you need to store tags aggregations in a distinct model, that's an easiest way to achieve it.

```bash
rails g metka:strategies:view --source-table-name=NAME_OF_TABLE_WITH_TAGS [--source-columns=NAME_OF_COLUMN_1 NAME_OF_COLUMN_2] [--view-name=NAME_OF_RESULTING_VIEW]
```

The code above will generate a migration that creates view with specified `NAME_OF_RESULTING_VIEW`, that would aggregate tags data from specified array of tagged columns [`NAME_OF_COLUMN_1`, `NAME_OF_COLUMN_2`, ...], that are present within specified table `NAME_OF_TABLE_WITH_TAGS`.
If `source-columns` option is not provided, then `tags` column would be used as defaults. If array of multiple values would be provided to the option, then the aggregation would be made with the tags from multiple tagged columns, so if a single tag would be found within multiple tagged columns, the resulting aggregation inside the view would have a single row for that tag with a sum of it's occurences across all stated tagged columns.
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

All of the options for that stategy's generation command are the same as for the View Strategy.

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

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/metka. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## Credits
![JetRockets](https://jetrockets.pro/jetrockets-icons-black.png)
Metka is maintained by [JetRockets](http://www.jetrockets.ru).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Metka project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/metka/blob/master/CODE_OF_CONDUCT.md).
