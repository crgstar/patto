require "test_helper"

class FeedItemTest < ActiveSupport::TestCase
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
  end

  test "有効な属性で保存できること" do
    feed_item = @feed_source.feed_items.build(
      guid: 'unique-guid-1',
      title: 'テスト記事',
      url: 'https://example.com/article1',
      description: '記事の説明',
      published_at: Time.current
    )
    assert feed_item.save, "有効な属性でFeedItemが保存できませんでした"
  end

  test "guidなしで保存できないこと" do
    feed_item = @feed_source.feed_items.build(
      guid: nil,
      title: 'テスト記事',
      url: 'https://example.com/article1'
    )
    assert_not feed_item.save, "guidなしでFeedItemが保存できてしまいました"
    assert_includes feed_item.errors[:guid], "can't be blank"
  end

  test "titleなしで保存できないこと" do
    feed_item = @feed_source.feed_items.build(
      guid: 'unique-guid-1',
      title: nil,
      url: 'https://example.com/article1'
    )
    assert_not feed_item.save, "titleなしでFeedItemが保存できてしまいました"
    assert_includes feed_item.errors[:title], "can't be blank"
  end

  test "urlなしで保存できないこと" do
    feed_item = @feed_source.feed_items.build(
      guid: 'unique-guid-1',
      title: 'テスト記事',
      url: nil
    )
    assert_not feed_item.save, "urlなしでFeedItemが保存できてしまいました"
    assert_includes feed_item.errors[:url], "can't be blank"
  end

  test "feed_sourceなしで保存できないこと" do
    feed_item = FeedItem.new(
      guid: 'unique-guid-1',
      title: 'テスト記事',
      url: 'https://example.com/article1'
    )
    assert_not feed_item.save, "feed_sourceなしでFeedItemが保存できてしまいました"
    assert_includes feed_item.errors[:feed_source], "must exist"
  end

  test "titleが500文字を超える場合保存できないこと" do
    long_title = 'a' * 501
    feed_item = @feed_source.feed_items.build(
      guid: 'unique-guid-1',
      title: long_title,
      url: 'https://example.com/article1'
    )
    assert_not feed_item.save, "500文字を超えるtitleでFeedItemが保存できてしまいました"
    assert_includes feed_item.errors[:title], "is too long (maximum is 500 characters)"
  end

  test "urlが2048文字を超える場合保存できないこと" do
    long_url = 'https://example.com/' + 'a' * 2050
    feed_item = @feed_source.feed_items.build(
      guid: 'unique-guid-1',
      title: 'テスト記事',
      url: long_url
    )
    assert_not feed_item.save, "2048文字を超えるurlでFeedItemが保存できてしまいました"
    assert_includes feed_item.errors[:url], "is too long (maximum is 2048 characters)"
  end

  test "同じfeed_sourceに同じguidを重複登録できないこと" do
    guid = 'unique-guid-1'
    @feed_source.feed_items.create!(
      guid: guid,
      title: '記事1',
      url: 'https://example.com/article1'
    )

    duplicate = @feed_source.feed_items.build(
      guid: guid,
      title: '記事2',
      url: 'https://example.com/article2'
    )
    assert_not duplicate.save, "同じfeed_sourceに同じguidを重複登録できてしまいました"
    assert_includes duplicate.errors[:guid], "has already been taken"
  end

  test "異なるfeed_sourceには同じguidを登録できること" do
    guid = 'unique-guid-1'
    @feed_source.feed_items.create!(
      guid: guid,
      title: '記事1',
      url: 'https://example.com/article1'
    )

    feed_source2 = @user.feed_sources.create!(
      url: 'https://example.com/feed2.xml',
      title: '別のフィード'
    )
    feed_item2 = feed_source2.feed_items.build(
      guid: guid,
      title: '記事2',
      url: 'https://example.com/article2'
    )
    assert feed_item2.save, "異なるfeed_sourceに同じguidを登録できませんでした"
  end

  test "論理削除が機能すること" do
    feed_item = @feed_source.feed_items.create!(
      guid: 'unique-guid-1',
      title: 'テスト記事',
      url: 'https://example.com/article1'
    )
    feed_item.discard
    assert feed_item.discarded?, "FeedItemが論理削除されていません"
    assert_not_nil feed_item.discarded_at, "discarded_atが設定されていません"
  end

  test "default_scopeで削除済みが除外されること" do
    item1 = @feed_source.feed_items.create!(guid: 'guid-1', title: '記事1', url: 'https://example.com/1')
    item2 = @feed_source.feed_items.create!(guid: 'guid-2', title: '記事2', url: 'https://example.com/2')
    item1.discard

    feed_items = @feed_source.feed_items.reload
    assert_equal 1, feed_items.count, "削除済みFeedItemが除外されていません"
    assert_equal item2.id, feed_items.first.id, "削除されていないFeedItemが取得できていません"
  end

  test "default_scopeでpublished_atで降順ソートされること" do
    item1 = @feed_source.feed_items.create!(
      guid: 'guid-1',
      title: '記事1',
      url: 'https://example.com/1',
      published_at: 1.day.ago
    )
    item2 = @feed_source.feed_items.create!(
      guid: 'guid-2',
      title: '記事2',
      url: 'https://example.com/2',
      published_at: Time.current
    )
    item3 = @feed_source.feed_items.create!(
      guid: 'guid-3',
      title: '記事3',
      url: 'https://example.com/3',
      published_at: 2.days.ago
    )

    feed_items = @feed_source.feed_items.reload
    assert_equal [item2.id, item1.id, item3.id], feed_items.map(&:id), "published_atで降順ソートされていません"
  end

  test "read_by?メソッドが未読の場合falseを返すこと" do
    feed_item = @feed_source.feed_items.create!(
      guid: 'unique-guid-1',
      title: 'テスト記事',
      url: 'https://example.com/article1'
    )
    assert_equal false, feed_item.read_by?(@user), "未読の記事でread_by?がfalseを返しませんでした"
  end

  test "read_by?メソッドが既読の場合trueを返すこと" do
    feed_item = @feed_source.feed_items.create!(
      guid: 'unique-guid-1',
      title: 'テスト記事',
      url: 'https://example.com/article1'
    )
    feed_item.mark_as_read_by(@user)
    assert_equal true, feed_item.read_by?(@user), "既読の記事でread_by?がtrueを返しませんでした"
  end

  test "mark_as_read_byメソッドが記事を既読にすること" do
    feed_item = @feed_source.feed_items.create!(
      guid: 'unique-guid-1',
      title: 'テスト記事',
      url: 'https://example.com/article1'
    )

    assert_equal false, feed_item.read_by?(@user), "初期状態で未読ではありません"

    feed_item.mark_as_read_by(@user)

    assert_equal true, feed_item.read_by?(@user), "mark_as_read_by後に既読になっていません"

    user_feed_item = feed_item.user_feed_items.find_by(user: @user)
    assert_not_nil user_feed_item, "UserFeedItemが作成されていません"
    assert_equal true, user_feed_item.read, "UserFeedItemのreadがtrueではありません"
    assert_not_nil user_feed_item.read_at, "read_atが設定されていません"
  end

  test "mark_as_unread_byメソッドが記事を未読にすること" do
    feed_item = @feed_source.feed_items.create!(
      guid: 'unique-guid-1',
      title: 'テスト記事',
      url: 'https://example.com/article1'
    )

    feed_item.mark_as_read_by(@user)
    assert_equal true, feed_item.read_by?(@user), "既読にできていません"

    feed_item.mark_as_unread_by(@user)
    assert_equal false, feed_item.read_by?(@user), "mark_as_unread_by後に未読になっていません"

    user_feed_item = feed_item.user_feed_items.find_by(user: @user)
    assert_not_nil user_feed_item, "UserFeedItemが存在しません"
    assert_equal false, user_feed_item.read, "UserFeedItemのreadがfalseではありません"
    assert_nil user_feed_item.read_at, "read_atがnilではありません"
  end

  test "user_feed_itemsアソシエーションが機能すること" do
    feed_item = @feed_source.feed_items.create!(
      guid: 'unique-guid-1',
      title: 'テスト記事',
      url: 'https://example.com/article1'
    )
    assert_respond_to feed_item, :user_feed_items, "user_feed_itemsアソシエーションが存在しません"
  end
end
