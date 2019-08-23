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

```ruby
class Post < ActiveRecord::Base
  include Metka::Model

end

@post = Post.new(title: 'Migrate tags in Rails to PostgreSQL')
@post.tags = ['ruby', 'postgres', 'rails']
@post.save
```

## Find tagged objects

```ruby
Post.tagged_with('ruby')
=> [#<Post id: 1, title: 'Migrate tags in Rails to PostgreSQL', tags: ['ruby', 'postgres', 'rails']

Post.tagged_with('ruby, crystal')
=> nil
```

In example above you will get records that are tagged with `ruby` and `crystal`. To get records that are tagged with any of these tags use `any` option.

```ruby
Post.tagged_with('ruby, crystal', any: true)
=> [#<Post id: 1, title: 'Migrate tags in Rails to PostgreSQL', tags: ['ruby', 'postgres', 'rails']
```

## Tag Cloud Strategies

There are several strategies to get tag statistics

### View Strategy

Data about taggings will be agregated in SQL View. The easiest way to implement but the most slow on SELECT.

```bash
rails g metka:strategies:view --source-table-name=NAME_OF_TABLE_WITH_TAGS
```

The code above will generate a migration that creates view to store aggregated data about tag in `NAME_OF_TABLE_WITH_TAGS` table.

Lets take a look at real example. We have a `notes` table with `tags` column.

| Column | Type                | Default                           |
|--------|---------------------|-----------------------------------|
| id     | integer             | nextval('notes_id_seq'::regclass) |
| body   | text                |                                   |
| tags   | character varying[] | '{}'::character varying[]         |

Now lets generate a migration.

```bash
RAILS_ENV=test rails g metka:strategies:view --source-table-name=notes
```

The result would be:

```ruby
# frozen_string_literal: true

class CreateTaggedNotesView < ActiveRecord::Migration[5.0]
  def up
    execute <<-SQL
    CREATE OR REPLACE VIEW tagged_notes AS

    SELECT UNNEST
      ( tags ) AS tag_name,
      COUNT ( * ) AS taggings_count
    FROM
      notes
    GROUP BY
      name;
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

| name    | taggings_count |
|---------|----------------|
| Ruby    | 124056         |
| React   | 30632          |
| Rails   | 28696          |
| Crystal | 6566           |
| Elixir  | 3475           |

Now you can create `TaggedNote` model and work with the view like you usually do with Rails models.

### Materialized View Strategy

Similar to the strategy above, but the view will be Materialized and refreshed with the trigger

TBD

### Table Strategy with Triggers



TBD

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/metka. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Metka project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/metka/blob/master/CODE_OF_CONDUCT.md).
