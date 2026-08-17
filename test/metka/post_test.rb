# frozen_string_literal: true

require "test_helper"

class PostTest < ActiveSupport::TestCase
  TAG1 = "tag1"
  TAG2 = "tag2"
  CATEGORY1 = "category1"
  CATEGORY2 = "category2"
  SHARED_TAG = "sharedtag"

  setup do
    user = User.create(name: Faker::Name.name)

    Post.create(user_id: user.id, tag_list: [ TAG1, SHARED_TAG ], category_list: [ CATEGORY1, CATEGORY2 ])
    Post.create(user_id: user.id, tag_list: [ TAG1, TAG2 ], category_list: [ CATEGORY2, SHARED_TAG ])
  end

  test "tagging clouds are correctly generated for tags column" do
    assert_equal [ [ SHARED_TAG, 1 ], [ TAG1, 2 ], [ TAG2, 1 ] ], Post.tag_cloud.sort
  end

  test "tagging clouds are correctly generated for categories column" do
    assert_equal [ [ CATEGORY1, 1 ], [ CATEGORY2, 2 ], [ SHARED_TAG, 1 ] ], Post.category_cloud.sort
  end

  test "tagging clouds are correctly generated for both tags and categories columns" do
    assert_equal [ [ CATEGORY1, 1 ], [ CATEGORY2, 2 ], [ SHARED_TAG, 2 ], [ TAG1, 2 ], [ TAG2, 1 ] ],
      Post.metka_cloud(:tags, :categories).sort
  end
end
