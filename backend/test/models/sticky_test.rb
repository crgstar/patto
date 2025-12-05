require "test_helper"

class StickyTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email: 'test@example.com',
      password: 'password123',
      password_confirmation: 'password123'
    )
  end

  test "should save sticky with valid attributes" do
    sticky = Sticky.new(
      type: 'Sticky',
      title: 'Test Sticky',
      content: 'This is a test sticky',
      position: 1,
      user: @user
    )
    assert sticky.save
  end

  test "should not save sticky without user" do
    sticky = Sticky.new(
      type: 'Sticky',
      title: 'Test Sticky',
      content: 'This is a test sticky',
      position: 1
    )
    assert_not sticky.save
  end

  test "should not save sticky without type" do
    sticky = Sticky.new(
      title: 'Test Sticky',
      content: 'This is a test sticky',
      position: 1,
      user: @user
    )
    assert_not sticky.save
  end

  test "should save sticky without title" do
    sticky = Sticky.new(
      type: 'Sticky',
      content: 'This is a test sticky',
      position: 1,
      user: @user
    )
    assert sticky.save
  end

  test "should save sticky without content" do
    sticky = Sticky.new(
      type: 'Sticky',
      title: 'Test Sticky',
      position: 1,
      user: @user
    )
    assert sticky.save
  end

  test "should save sticky without position (defaults to 0)" do
    sticky = Sticky.new(
      type: 'Sticky',
      title: 'Test Sticky',
      content: 'This is a test sticky',
      user: @user
    )
    assert sticky.save
    assert_equal 0, sticky.position
  end

  test "should belong to user" do
    sticky = Sticky.create!(
      type: 'Sticky',
      title: 'Test Sticky',
      content: 'This is a test sticky',
      position: 1,
      user: @user
    )
    assert_equal @user, sticky.user
  end

  test "should order stickies by position" do
    sticky1 = Sticky.create!(type: 'Sticky', title: 'First', position: 2, user: @user)
    sticky2 = Sticky.create!(type: 'Sticky', title: 'Second', position: 1, user: @user)
    sticky3 = Sticky.create!(type: 'Sticky', title: 'Third', position: 3, user: @user)

    stickies = Sticky.all
    assert_equal [sticky2, sticky1, sticky3], stickies.to_a
  end

  test "should discard sticky" do
    sticky = Sticky.create!(
      type: 'Sticky',
      title: 'Test Sticky',
      content: 'This is a test sticky',
      position: 1,
      user: @user
    )

    sticky.discard
    assert sticky.discarded?
    assert_not_nil sticky.discarded_at
  end

  test "should not include discarded stickies in default scope" do
    sticky1 = Sticky.create!(type: 'Sticky', title: 'Active', position: 1, user: @user)
    sticky2 = Sticky.create!(type: 'Sticky', title: 'To be discarded', position: 2, user: @user)

    sticky2.discard

    assert_equal 1, Sticky.count
    assert_equal [sticky1], Sticky.all.to_a
  end

  test "should find discarded stickies with unscoped" do
    sticky1 = Sticky.create!(type: 'Sticky', title: 'Active', position: 1, user: @user)
    sticky2 = Sticky.create!(type: 'Sticky', title: 'Discarded', position: 2, user: @user)

    sticky2.discard

    assert_equal 1, Sticky.count
    assert_equal 2, Sticky.unscoped.count
    assert_equal 1, Sticky.unscoped.where.not(discarded_at: nil).count
  end

  test "should undiscard sticky" do
    sticky = Sticky.create!(
      type: 'Sticky',
      title: 'Test Sticky',
      position: 1,
      user: @user
    )

    sticky.discard
    assert sticky.discarded?

    sticky.undiscard
    assert_not sticky.discarded?
    assert_nil sticky.discarded_at
  end
end
