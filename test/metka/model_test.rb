# frozen_string_literal: true

require 'test_helper'

class MetkaModelTest < ActiveSupport::TestCase
  TAG_LIST = 'ruby, rails, crystal'
  CATEGORY_LIST = 'programming, backend, frontend'

  setup do
    @user = User.create(name: Faker::Name.name)
    @user1 = User.create!(name: Faker::Name.name, tags: %w[developer senior])
    User.create!(name: Faker::Name.name, tags: ['junior'])

    @post = Post.new(user_id: @user.id)
    @post.tag_list = TAG_LIST
    @post.category_list = CATEGORY_LIST
    @post.save!

    @post_two = Post.new(user_id: @user.id)
    @post_two.tag_list = ['php', 'java', 'scala']
    @post_two.save!
  end

  # .with_all_tags, default parser

  test 'responds to .with_all_tags' do
    assert_respond_to Post, :with_all_tags
  end

  test '.with_all_tags is able to find by tag' do
    assert_predicate Post.with_all_tags(TAG_LIST), :present?
    assert_predicate Post.with_all_tags(TAG_LIST.split(', ').first), :present?
    assert_predicate Post.with_all_tags(TAG_LIST.split(', ').last), :present?
    assert_equal @post, Post.with_all_tags(TAG_LIST).first
  end

  test '.with_all_tags returns a not empty scope for empty tags' do
    refute_empty Post.with_all_tags('')
  end

  test '.with_all_tags returns an empty scope for unused tags' do
    assert_empty Post.with_all_tags([TAG_LIST.split(', ').first, 'PHP'])
  end

  # .with_any_tags, default parser

  test 'responds to .with_any_tags' do
    assert_respond_to Post, :with_any_tags
  end

  test '.with_any_tags is able to find by tag' do
    new_tag_list = TAG_LIST + ', go'

    assert_predicate Post.with_any_tags(new_tag_list), :present?
    assert_predicate Post.with_any_tags(new_tag_list.split(', ').first), :present?
    assert_equal @post, Post.with_any_tags(new_tag_list).first
  end

  test '.with_any_tags returns an empty scope for unused tags' do
    assert_empty Post.with_any_tags((TAG_LIST + ', go').split(', ').last)
  end

  # .without_all_tags

  test 'responds to .without_all_tags' do
    assert_respond_to Post, :without_all_tags
  end

  test '.without_all_tags returns two object if tags empty' do
    ['', nil, []].each do |tags|
      assert_equal Post.count, Post.without_all_tags(tags).size
    end
  end

  test '.without_all_tags returns post' do
    assert_equal @post, Post.without_all_tags(@post_two.tag_list.to_a).first
    assert_equal @post_two, Post.without_all_tags(@post.tag_list.to_a).first
  end

  test '.without_all_tags returns all post if posts dont include all tags' do
    assert_equal 2, Post.without_all_tags(@post_two.tag_list.to_a << '123').count
  end

  # .without_any_tags

  test 'responds to .without_any_tags' do
    assert_respond_to Post, :without_any_tags
  end

  test '.without_any_tags returns post' do
    assert_equal 1, Post.without_any_tags(@post_two.tag_list.to_a << 'Clojure').count
    assert_equal @post, Post.without_any_tags(@post_two.tag_list.to_a << 'Clojure').first
  end

  # .tagged_with

  test '.tagged_with finds a post carrying all of the given tags' do
    @post.tags << 'php'
    @post.save!

    assert_equal 1, Post.tagged_with(%w[php ruby]).count
    assert_equal @post, Post.tagged_with(%w[php ruby]).first
  end

  test '.tagged_with any finds a post carrying at least one of the given tags' do
    assert_equal 1, Post.tagged_with(%w[php cobol], any: true).count
    assert_equal @post_two, Post.tagged_with(%w[php cobol], any: true).first
  end

  test '.tagged_with exclude skips the posts carrying the given tags' do
    assert_equal 1, Post.tagged_with(%w[php], exclude: true).count
    assert_equal @post, Post.tagged_with(%w[php], exclude: true).first
  end

  test '.tagged_with any: false requires all of the given tags' do
    @post.tags << 'php'
    @post.save!

    assert_equal 1, Post.tagged_with(%w[php ruby], any: false).count
    assert_equal @post, Post.tagged_with(%w[php ruby], any: false).first
  end

  test '.tagged_with only looks at the columns listed in :on' do
    assert_empty Post.tagged_with('php', on: ['categories'])
    assert_equal 1, Post.tagged_with('ruby', on: ['tags']).count
    assert_equal @post, Post.tagged_with('ruby', on: ['tags']).first
  end

  test '.tagged_with returns the whole scope for empty tags' do
    ['', nil, []].each do |tags|
      assert_equal Post.all.sort_by(&:id), Post.tagged_with(tags, any: false).sort_by(&:id)
      assert_equal Post.all.sort_by(&:id), Post.tagged_with(tags, any: true).sort_by(&:id)
      assert_equal Post.all.sort_by(&:id), Post.tagged_with(tags, exclude: true, any: true).sort_by(&:id)
      assert_equal Post.all.sort_by(&:id), Post.tagged_with(tags, exclude: true, any: false).sort_by(&:id)
    end
  end

  # Custom parser

  TAGS = 'developer | senior'

  test 'responds to .with_all_tags with a custom parser' do
    assert_respond_to User, :with_all_tags
  end

  test '.with_all_tags is able to find by tags with a custom parser' do
    assert_predicate User.with_all_tags(TAGS), :present?
    assert_predicate User.with_all_tags(TAGS.split(' | ').first), :present?
    assert_equal @user1, User.with_all_tags(TAGS).first
  end

  test '.with_all_tags returns a not empty scope for empty categories with a custom parser' do
    refute_empty User.with_all_tags('')
  end

  test '.with_all_tags returns an empty scope for unused categories with a custom parser' do
    assert_empty User.with_all_tags([TAGS.split(' | ').first, 'junior'])
  end

  test 'responds to .with_any_tags with a custom parser' do
    assert_respond_to User, :with_any_tags
  end

  test '.with_any_tags is able to find by category with a custom parser' do
    new_tags_list = TAGS + ' | backend'

    assert_predicate User.with_any_tags(new_tags_list), :present?
    assert_predicate User.with_any_tags(new_tags_list.split(' | ').first), :present?
    assert_equal @user1, User.with_any_tags(new_tags_list).first
  end

  test '.with_any_tags returns an empty scope for unused tags with a custom parser' do
    assert_empty User.with_any_tags((TAGS + ' | backend').split(' | ').last)
  end
end
