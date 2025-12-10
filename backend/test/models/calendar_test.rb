require "test_helper"

class CalendarTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email: 'test@example.com',
      password: 'password123',
      password_confirmation: 'password123'
    )
  end

  # STI継承の確認
  test "should be a subclass of Sticky" do
    assert Calendar < Sticky
  end

  test "should save calendar with valid attributes" do
    calendar = Calendar.new(
      title: 'My Calendar',
      position: 1,
      user: @user
    )
    assert calendar.save
    assert_equal 'Calendar', calendar.type
  end

  test "should not save calendar without user" do
    calendar = Calendar.new(
      title: 'My Calendar',
      position: 1
    )
    assert_not calendar.save
  end

  test "should save calendar without title" do
    calendar = Calendar.new(
      position: 1,
      user: @user
    )
    assert calendar.save
  end

  test "should save calendar without content" do
    calendar = Calendar.new(
      title: 'My Calendar',
      position: 1,
      user: @user
    )
    assert calendar.save
  end

  test "should belong to user" do
    calendar = Calendar.create!(
      title: 'My Calendar',
      position: 1,
      user: @user
    )
    assert_equal @user, calendar.user
  end

  test "should discard calendar" do
    calendar = Calendar.create!(
      title: 'My Calendar',
      position: 1,
      user: @user
    )

    calendar.discard
    assert calendar.discarded?
    assert_not_nil calendar.discarded_at
  end

  test "should not include discarded calendars in default scope" do
    calendar1 = Calendar.create!(title: 'Active Calendar', position: 1, user: @user)
    calendar2 = Calendar.create!(title: 'To be discarded', position: 2, user: @user)

    calendar2.discard

    assert_equal 1, Calendar.count
    assert_equal [calendar1], Calendar.all.to_a
  end

  test "should undiscard calendar" do
    calendar = Calendar.create!(
      title: 'My Calendar',
      position: 1,
      user: @user
    )

    calendar.discard
    assert calendar.discarded?

    calendar.undiscard
    assert_not calendar.discarded?
    assert_nil calendar.discarded_at
  end

  # 座標関連のテスト
  test "should have default coordinates when not specified" do
    calendar = Calendar.create!(
      title: 'My Calendar',
      user: @user
    )

    assert_equal 0, calendar.x
    assert_equal 0, calendar.y
    assert_equal 1, calendar.width
    assert_equal 1, calendar.height
  end

  test "should save calendar with valid coordinates" do
    calendar = Calendar.new(
      title: 'My Calendar',
      x: 5,
      y: 10,
      width: 2,
      height: 3,
      user: @user
    )
    assert calendar.save
    assert_equal 5, calendar.x
    assert_equal 10, calendar.y
    assert_equal 2, calendar.width
    assert_equal 3, calendar.height
  end

  test "should not save calendar with negative x" do
    calendar = Calendar.new(
      title: 'My Calendar',
      x: -1,
      y: 0,
      width: 1,
      height: 1,
      user: @user
    )
    assert_not calendar.save
    assert_includes calendar.errors[:x], "must be greater than or equal to 0"
  end

  test "should not save calendar with zero width" do
    calendar = Calendar.new(
      title: 'My Calendar',
      x: 0,
      y: 0,
      width: 0,
      height: 1,
      user: @user
    )
    assert_not calendar.save
    assert_includes calendar.errors[:width], "must be greater than 0"
  end

  test "should auto position calendar when coordinates not specified" do
    # 最初のカレンダーを作成（y=0になる）
    first_calendar = Calendar.create!(
      title: 'First Calendar',
      user: @user
    )
    assert_equal 0, first_calendar.x
    assert_equal 0, first_calendar.y

    # 2番目のカレンダーを作成（y=1になる）
    second_calendar = Calendar.create!(
      title: 'Second Calendar',
      user: @user
    )
    assert_equal 0, second_calendar.x
    assert_equal 1, second_calendar.y
  end

  test "should not auto position when coordinates are specified" do
    calendar = Calendar.create!(
      title: 'My Calendar',
      x: 5,
      y: 10,
      width: 2,
      height: 3,
      user: @user
    )

    assert_equal 5, calendar.x
    assert_equal 10, calendar.y
    assert_equal 2, calendar.width
    assert_equal 3, calendar.height
  end

  # Sticky と Calendar の混在テスト
  test "should work alongside regular stickies" do
    sticky = Sticky.create!(type: 'Sticky', title: 'Regular Sticky', user: @user)
    calendar = Calendar.create!(title: 'My Calendar', user: @user)

    assert_equal 2, Sticky.count
    assert_equal 1, Calendar.count
    assert_includes Sticky.all, calendar
  end
end
