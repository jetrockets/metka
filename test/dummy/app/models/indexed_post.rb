# frozen_string_literal: true

# The posts table through the index strategy: on SQLite, tag queries answer
# from the trigger-maintained (tag_name, record_id) side tables instead of
# scanning json_each. On PostgreSQL the declaration is inert — queries use
# the GIN-indexed array operators like any other model — so this class must
# behave identically to Post on both adapters.
class IndexedPost < ActiveRecord::Base
  self.table_name = "posts"

  include Metka::Model(
    columns: %w[tags categories],
    index_tables: {
      "tags" => "posts_tags_index",
      "categories" => "posts_categories_index"
    }
  )

  belongs_to :user
end
