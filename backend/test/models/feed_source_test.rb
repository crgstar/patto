require "test_helper"

class FeedSourceTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email: 'test@example.com',
      password: 'password123',
      password_confirmation: 'password123'
    )
  end

  test "有効な属性で保存できること" do
    feed_source = @user.feed_sources.build(
      url: 'https://example.com/feed.xml',
      title: 'テストフィード'
    )
    assert feed_source.save, "有効な属性でFeedSourceが保存できませんでした"
  end

  test "urlなしで保存できないこと" do
    feed_source = @user.feed_sources.build(
      url: nil,
      title: 'テストフィード'
    )
    assert_not feed_source.save, "urlなしでFeedSourceが保存できてしまいました"
    assert_includes feed_source.errors[:url], "can't be blank"
  end

  test "userなしで保存できないこと" do
    feed_source = FeedSource.new(
      url: 'https://example.com/feed.xml',
      title: 'テストフィード'
    )
    assert_not feed_source.save, "userなしでFeedSourceが保存できてしまいました"
    assert_includes feed_source.errors[:user], "must exist"
  end

  test "URLが2048文字を超える場合保存できないこと" do
    long_url = 'https://example.com/' + 'a' * 2050
    feed_source = @user.feed_sources.build(
      url: long_url,
      title: 'テストフィード'
    )
    assert_not feed_source.save, "2048文字を超えるURLでFeedSourceが保存できてしまいました"
    assert_includes feed_source.errors[:url], "is too long (maximum is 2048 characters)"
  end

  test "無効なURL形式で保存できないこと" do
    feed_source = @user.feed_sources.build(
      url: 'invalid-url',
      title: 'テストフィード'
    )
    assert_not feed_source.save, "無効なURL形式でFeedSourceが保存できてしまいました"
    assert_includes feed_source.errors[:url], "is invalid"
  end

  test "http URLで保存できること" do
    feed_source = @user.feed_sources.build(
      url: 'http://example.com/feed.xml',
      title: 'テストフィード'
    )
    assert feed_source.save, "http URLでFeedSourceが保存できませんでした"
  end

  test "https URLで保存できること" do
    feed_source = @user.feed_sources.build(
      url: 'https://example.com/feed.xml',
      title: 'テストフィード'
    )
    assert feed_source.save, "https URLでFeedSourceが保存できませんでした"
  end

  test "ftp URLで保存できないこと" do
    feed_source = @user.feed_sources.build(
      url: 'ftp://example.com/feed.xml',
      title: 'テストフィード'
    )
    assert_not feed_source.save, "ftp URLでFeedSourceが保存できてしまいました"
    assert_includes feed_source.errors[:url], "is invalid"
  end

  test "同じユーザーが同じURLを重複登録できないこと" do
    url = 'https://example.com/feed.xml'
    @user.feed_sources.create!(url: url, title: 'フィード1')

    duplicate = @user.feed_sources.build(url: url, title: 'フィード2')
    assert_not duplicate.save, "同じユーザーが同じURLを重複登録できてしまいました"
    assert_includes duplicate.errors[:url], "has already been taken"
  end

  test "異なるユーザーは同じURLを登録できること" do
    url = 'https://example.com/feed.xml'
    @user.feed_sources.create!(url: url, title: 'ユーザー1のフィード')

    user2 = User.create!(
      email: 'test2@example.com',
      password: 'password123',
      password_confirmation: 'password123'
    )
    feed_source2 = user2.feed_sources.build(url: url, title: 'ユーザー2のフィード')
    assert feed_source2.save, "異なるユーザーが同じURLを登録できませんでした"
  end

  test "論理削除が機能すること" do
    feed_source = @user.feed_sources.create!(
      url: 'https://example.com/feed.xml',
      title: 'テストフィード'
    )
    feed_source.discard
    assert feed_source.discarded?, "FeedSourceが論理削除されていません"
    assert_not_nil feed_source.discarded_at, "discarded_atが設定されていません"
  end

  test "default_scopeで削除済みが除外されること" do
    feed_source1 = @user.feed_sources.create!(url: 'https://example.com/feed1.xml', title: 'フィード1')
    feed_source2 = @user.feed_sources.create!(url: 'https://example.com/feed2.xml', title: 'フィード2')
    feed_source1.discard

    feed_sources = @user.feed_sources.reload
    assert_equal 1, feed_sources.count, "削除済みFeedSourceが除外されていません"
    assert_equal feed_source2.id, feed_sources.first.id, "削除されていないFeedSourceが取得できていません"
  end

  test "sticky_feed_sourcesアソシエーションが機能すること" do
    feed_source = @user.feed_sources.create!(
      url: 'https://example.com/feed.xml',
      title: 'テストフィード'
    )
    assert_respond_to feed_source, :sticky_feed_sources, "sticky_feed_sourcesアソシエーションが存在しません"
  end

  test "stickiesアソシエーションが機能すること" do
    feed_source = @user.feed_sources.create!(
      url: 'https://example.com/feed.xml',
      title: 'テストフィード'
    )
    assert_respond_to feed_source, :stickies, "stickiesアソシエーションが存在しません"
  end

  test "feed_itemsアソシエーションが機能すること" do
    feed_source = @user.feed_sources.create!(
      url: 'https://example.com/feed.xml',
      title: 'テストフィード'
    )
    assert_respond_to feed_source, :feed_items, "feed_itemsアソシエーションが存在しません"
  end
end
