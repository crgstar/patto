require "test_helper"

class StickyFeedSourceTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email: 'test@example.com',
      password: 'password123',
      password_confirmation: 'password123'
    )
    @sticky = @user.stickies.create!(
      type: 'FeedReader',
      title: 'テストフィードリーダー',
      content: '',
      x: 0,
      y: 0,
      width: 2,
      height: 2,
      position: 1
    )
    @feed_source = @user.feed_sources.create!(
      url: 'https://example.com/feed.xml',
      title: 'テストフィード'
    )
  end

  test "有効な属性で保存できること" do
    sticky_feed_source = @sticky.sticky_feed_sources.build(
      feed_source: @feed_source,
      position: 0
    )
    assert sticky_feed_source.save, "有効な属性でStickyFeedSourceが保存できませんでした"
  end

  test "stickyなしで保存できないこと" do
    sticky_feed_source = StickyFeedSource.new(
      feed_source: @feed_source,
      position: 0
    )
    assert_not sticky_feed_source.save, "stickyなしでStickyFeedSourceが保存できてしまいました"
    assert_includes sticky_feed_source.errors[:sticky], "must exist"
  end

  test "feed_sourceなしで保存できないこと" do
    sticky_feed_source = @sticky.sticky_feed_sources.build(
      feed_source: nil,
      position: 0
    )
    assert_not sticky_feed_source.save, "feed_sourceなしでStickyFeedSourceが保存できてしまいました"
    assert_includes sticky_feed_source.errors[:feed_source], "must exist"
  end

  test "同じStickyに同じfeed_sourceを重複追加できないこと" do
    @sticky.sticky_feed_sources.create!(
      feed_source: @feed_source,
      position: 0
    )

    duplicate = @sticky.sticky_feed_sources.build(
      feed_source: @feed_source,
      position: 1
    )
    assert_not duplicate.save, "同じStickyに同じfeed_sourceを重複追加できてしまいました"
    assert_includes duplicate.errors[:feed_source_id], "has already been taken"
  end

  test "異なるStickyには同じfeed_sourceを追加できること" do
    @sticky.sticky_feed_sources.create!(
      feed_source: @feed_source,
      position: 0
    )

    sticky2 = @user.stickies.create!(
      type: 'FeedReader',
      title: '別のフィードリーダー',
      content: '',
      x: 0,
      y: 0,
      width: 2,
      height: 2,
      position: 2
    )
    sticky_feed_source2 = sticky2.sticky_feed_sources.build(
      feed_source: @feed_source,
      position: 0
    )
    assert sticky_feed_source2.save, "異なるStickyに同じfeed_sourceを追加できませんでした"
  end

  test "positionのデフォルトが0であること" do
    sticky_feed_source = @sticky.sticky_feed_sources.create!(feed_source: @feed_source)
    assert_equal 0, sticky_feed_source.position, "positionのデフォルトが0ではありません"
  end

  test "positionが負の値の場合保存できないこと" do
    sticky_feed_source = @sticky.sticky_feed_sources.build(
      feed_source: @feed_source,
      position: -1
    )
    assert_not sticky_feed_source.save, "positionが負の値でも保存できてしまいました"
    assert_includes sticky_feed_source.errors[:position], "must be greater than or equal to 0"
  end

  test "論理削除が機能すること" do
    sticky_feed_source = @sticky.sticky_feed_sources.create!(
      feed_source: @feed_source,
      position: 0
    )
    sticky_feed_source.discard
    assert sticky_feed_source.discarded?, "StickyFeedSourceが論理削除されていません"
    assert_not_nil sticky_feed_source.discarded_at, "discarded_atが設定されていません"
  end

  test "default_scopeで削除済みが除外されること" do
    feed_source2 = @user.feed_sources.create!(
      url: 'https://example.com/feed2.xml',
      title: 'テストフィード2'
    )

    sfs1 = @sticky.sticky_feed_sources.create!(feed_source: @feed_source, position: 0)
    sfs2 = @sticky.sticky_feed_sources.create!(feed_source: feed_source2, position: 1)
    sfs1.discard

    sticky_feed_sources = @sticky.sticky_feed_sources.reload
    assert_equal 1, sticky_feed_sources.count, "削除済みStickyFeedSourceが除外されていません"
    assert_equal sfs2.id, sticky_feed_sources.first.id, "削除されていないStickyFeedSourceが取得できていません"
  end

  test "default_scopeでpositionで昇順ソートされること" do
    feed_source2 = @user.feed_sources.create!(
      url: 'https://example.com/feed2.xml',
      title: 'テストフィード2'
    )
    feed_source3 = @user.feed_sources.create!(
      url: 'https://example.com/feed3.xml',
      title: 'テストフィード3'
    )

    sfs3 = @sticky.sticky_feed_sources.create!(feed_source: feed_source3, position: 2)
    sfs1 = @sticky.sticky_feed_sources.create!(feed_source: @feed_source, position: 0)
    sfs2 = @sticky.sticky_feed_sources.create!(feed_source: feed_source2, position: 1)

    sticky_feed_sources = @sticky.sticky_feed_sources.reload
    assert_equal [sfs1.id, sfs2.id, sfs3.id], sticky_feed_sources.map(&:id), "positionで昇順ソートされていません"
  end
end
