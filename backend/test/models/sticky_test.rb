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

  # 座標関連のテスト
  test "should have default coordinates when not specified" do
    sticky = Sticky.create!(
      type: 'Sticky',
      title: 'Test Sticky',
      content: 'Test content',
      user: @user
    )

    assert_equal 0, sticky.x
    assert_equal 0, sticky.y
    assert_equal 1, sticky.width
    assert_equal 1, sticky.height
  end

  test "should save sticky with valid coordinates" do
    sticky = Sticky.new(
      type: 'Sticky',
      title: 'Test Sticky',
      content: 'Test content',
      x: 5,
      y: 10,
      width: 2,
      height: 3,
      user: @user
    )
    assert sticky.save
    assert_equal 5, sticky.x
    assert_equal 10, sticky.y
    assert_equal 2, sticky.width
    assert_equal 3, sticky.height
  end

  test "should not save sticky with negative x" do
    sticky = Sticky.new(
      type: 'Sticky',
      title: 'Test Sticky',
      x: -1,
      y: 0,
      width: 1,
      height: 1,
      user: @user
    )
    assert_not sticky.save
    assert_includes sticky.errors[:x], "must be greater than or equal to 0"
  end

  test "should not save sticky with negative y" do
    sticky = Sticky.new(
      type: 'Sticky',
      title: 'Test Sticky',
      x: 0,
      y: -1,
      width: 1,
      height: 1,
      user: @user
    )
    assert_not sticky.save
    assert_includes sticky.errors[:y], "must be greater than or equal to 0"
  end

  test "should not save sticky with zero width" do
    sticky = Sticky.new(
      type: 'Sticky',
      title: 'Test Sticky',
      x: 0,
      y: 0,
      width: 0,
      height: 1,
      user: @user
    )
    assert_not sticky.save
    assert_includes sticky.errors[:width], "must be greater than 0"
  end

  test "should not save sticky with negative height" do
    sticky = Sticky.new(
      type: 'Sticky',
      title: 'Test Sticky',
      x: 0,
      y: 0,
      width: 1,
      height: -1,
      user: @user
    )
    assert_not sticky.save
    assert_includes sticky.errors[:height], "must be greater than 0"
  end

  test "should auto position sticky when coordinates not specified" do
    # 最初の付箋を作成（y=0になる）
    first_sticky = Sticky.create!(
      type: 'Sticky',
      title: 'First Sticky',
      user: @user
    )
    assert_equal 0, first_sticky.x
    assert_equal 0, first_sticky.y

    # 2番目の付箋を作成（y=1になる）
    second_sticky = Sticky.create!(
      type: 'Sticky',
      title: 'Second Sticky',
      user: @user
    )
    assert_equal 0, second_sticky.x
    assert_equal 1, second_sticky.y
  end

  test "should not auto position when coordinates are specified" do
    sticky = Sticky.create!(
      type: 'Sticky',
      title: 'Test Sticky',
      x: 5,
      y: 10,
      width: 2,
      height: 3,
      user: @user
    )

    assert_equal 5, sticky.x
    assert_equal 10, sticky.y
    assert_equal 2, sticky.width
    assert_equal 3, sticky.height
  end
end
