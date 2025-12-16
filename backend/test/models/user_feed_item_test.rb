require "test_helper"

class UserFeedItemTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email: 'test@example.com',
      password: 'password123',
      password_confirmation: 'password123'
    )
    @feed_source = @user.feed_sources.create!(
      url: 'https://example.com/feed.xml',
      title: 'テストフィード'
    )
    @feed_item = @feed_source.feed_items.create!(
      guid: 'unique-guid-1',
      title: 'テスト記事',
      url: 'https://example.com/article1'
    )
  end

  test "有効な属性で保存できること" do
    user_feed_item = UserFeedItem.new(
      user: @user,
      feed_item: @feed_item,
      read: true,
      read_at: Time.current
    )
    assert user_feed_item.save, "有効な属性でUserFeedItemが保存できませんでした"
  end

  test "userなしで保存できないこと" do
    user_feed_item = UserFeedItem.new(
      user: nil,
      feed_item: @feed_item,
      read: false
    )
    assert_not user_feed_item.save, "userなしでUserFeedItemが保存できてしまいました"
    assert_includes user_feed_item.errors[:user], "must exist"
  end

  test "feed_itemなしで保存できないこと" do
    user_feed_item = UserFeedItem.new(
      user: @user,
      feed_item: nil,
      read: false
    )
    assert_not user_feed_item.save, "feed_itemなしでUserFeedItemが保存できてしまいました"
    assert_includes user_feed_item.errors[:feed_item], "must exist"
  end

  test "同じユーザーが同じfeed_itemを重複登録できないこと" do
    UserFeedItem.create!(
      user: @user,
      feed_item: @feed_item,
      read: false
    )

    duplicate = UserFeedItem.new(
      user: @user,
      feed_item: @feed_item,
      read: true
    )
    assert_not duplicate.save, "同じユーザーが同じfeed_itemを重複登録できてしまいました"
    assert_includes duplicate.errors[:feed_item_id], "has already been taken"
  end

  test "異なるユーザーは同じfeed_itemを登録できること" do
    UserFeedItem.create!(
      user: @user,
      feed_item: @feed_item,
      read: false
    )

    user2 = User.create!(
      email: 'test2@example.com',
      password: 'password123',
      password_confirmation: 'password123'
    )
    user_feed_item2 = UserFeedItem.new(
      user: user2,
      feed_item: @feed_item,
      read: false
    )
    assert user_feed_item2.save, "異なるユーザーが同じfeed_itemを登録できませんでした"
  end

  test "readのデフォルトがfalseであること" do
    user_feed_item = UserFeedItem.create!(user: @user, feed_item: @feed_item)
    assert_equal false, user_feed_item.read, "readのデフォルトがfalseではありません"
  end

  test "starredのデフォルトがfalseであること" do
    user_feed_item = UserFeedItem.create!(user: @user, feed_item: @feed_item)
    assert_equal false, user_feed_item.starred, "starredのデフォルトがfalseではありません"
  end

  test "論理削除が機能すること" do
    user_feed_item = UserFeedItem.create!(
      user: @user,
      feed_item: @feed_item,
      read: false
    )
    user_feed_item.discard
    assert user_feed_item.discarded?, "UserFeedItemが論理削除されていません"
    assert_not_nil user_feed_item.discarded_at, "discarded_atが設定されていません"
  end

  test "default_scopeで削除済みが除外されること" do
    feed_item2 = @feed_source.feed_items.create!(
      guid: 'unique-guid-2',
      title: 'テスト記事2',
      url: 'https://example.com/article2'
    )

    ufi1 = UserFeedItem.create!(user: @user, feed_item: @feed_item)
    ufi2 = UserFeedItem.create!(user: @user, feed_item: feed_item2)
    ufi1.discard

    user_feed_items = UserFeedItem.where(user: @user).reload
    assert_equal 1, user_feed_items.count, "削除済みUserFeedItemが除外されていません"
    assert_equal ufi2.id, user_feed_items.first.id, "削除されていないUserFeedItemが取得できていません"
  end

  test "read_itemsスコープが既読のみを取得すること" do
    ufi1 = UserFeedItem.create!(user: @user, feed_item: @feed_item, read: true)

    feed_item2 = @feed_source.feed_items.create!(
      guid: 'unique-guid-2',
      title: 'テスト記事2',
      url: 'https://example.com/article2'
    )
    ufi2 = UserFeedItem.create!(user: @user, feed_item: feed_item2, read: false)

    read_items = UserFeedItem.where(user: @user).read_items
    assert_equal 1, read_items.count, "read_itemsスコープが正しく動作していません"
    assert_equal ufi1.id, read_items.first.id, "既読アイテムが取得できていません"
  end

  test "unread_itemsスコープが未読のみを取得すること" do
    ufi1 = UserFeedItem.create!(user: @user, feed_item: @feed_item, read: true)

    feed_item2 = @feed_source.feed_items.create!(
      guid: 'unique-guid-2',
      title: 'テスト記事2',
      url: 'https://example.com/article2'
    )
    ufi2 = UserFeedItem.create!(user: @user, feed_item: feed_item2, read: false)

    unread_items = UserFeedItem.where(user: @user).unread_items
    assert_equal 1, unread_items.count, "unread_itemsスコープが正しく動作していません"
    assert_equal ufi2.id, unread_items.first.id, "未読アイテムが取得できていません"
  end

  test "starred_itemsスコープがお気に入りのみを取得すること" do
    ufi1 = UserFeedItem.create!(user: @user, feed_item: @feed_item, starred: true)

    feed_item2 = @feed_source.feed_items.create!(
      guid: 'unique-guid-2',
      title: 'テスト記事2',
      url: 'https://example.com/article2'
    )
    ufi2 = UserFeedItem.create!(user: @user, feed_item: feed_item2, starred: false)

    starred_items = UserFeedItem.where(user: @user).starred_items
    assert_equal 1, starred_items.count, "starred_itemsスコープが正しく動作していません"
    assert_equal ufi1.id, starred_items.first.id, "お気に入りアイテムが取得できていません"
  end
end
