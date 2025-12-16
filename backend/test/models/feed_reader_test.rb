require "test_helper"

class FeedReaderTest < ActiveSupport::TestCase
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

  test "type: 'FeedReader'で保存できること" do
    feed_reader = @user.stickies.build(
      type: 'FeedReader',
      title: 'テストフィードリーダー',
      content: '',
      x: 0,
      y: 0,
      width: 2,
      height: 2,
      position: 1
    )
    assert feed_reader.save, "FeedReaderが保存できませんでした"
    assert_equal 'FeedReader', feed_reader.type
  end

  test "Stickyの機能を継承していること - 座標" do
    feed_reader = FeedReader.create!(
      title: 'テストフィードリーダー',
      x: 5,
      y: 10,
      width: 3,
      height: 4,
      position: 1,
      user: @user
    )
    assert_equal 5, feed_reader.x
    assert_equal 10, feed_reader.y
    assert_equal 3, feed_reader.width
    assert_equal 4, feed_reader.height
  end

  test "Stickyの機能を継承していること - 論理削除" do
    feed_reader = FeedReader.create!(
      title: 'テストフィードリーダー',
      position: 1,
      user: @user
    )
    feed_reader.discard
    assert feed_reader.discarded?, "FeedReaderが論理削除されていません"
    assert_not_nil feed_reader.discarded_at
  end

  test "sticky_feed_sourcesの関連が機能すること" do
    feed_reader = FeedReader.create!(
      title: 'テストフィードリーダー',
      position: 1,
      user: @user
    )

    sfs1 = feed_reader.sticky_feed_sources.create!(feed_source: @feed_source, position: 0)

    feed_source2 = @user.feed_sources.create!(
      url: 'https://example.com/feed2.xml',
      title: 'テストフィード2'
    )
    sfs2 = feed_reader.sticky_feed_sources.create!(feed_source: feed_source2, position: 1)

    assert_equal 2, feed_reader.sticky_feed_sources.count
    assert_includes feed_reader.sticky_feed_sources, sfs1
    assert_includes feed_reader.sticky_feed_sources, sfs2
  end

  test "sticky_feed_sourcesがpositionで順序付けられること" do
    feed_reader = FeedReader.create!(
      title: 'テストフィードリーダー',
      position: 1,
      user: @user
    )

    feed_source2 = @user.feed_sources.create!(
      url: 'https://example.com/feed2.xml',
      title: 'テストフィード2'
    )
    feed_source3 = @user.feed_sources.create!(
      url: 'https://example.com/feed3.xml',
      title: 'テストフィード3'
    )

    sfs3 = feed_reader.sticky_feed_sources.create!(feed_source: feed_source3, position: 2)
    sfs1 = feed_reader.sticky_feed_sources.create!(feed_source: @feed_source, position: 0)
    sfs2 = feed_reader.sticky_feed_sources.create!(feed_source: feed_source2, position: 1)

    sticky_feed_sources = feed_reader.sticky_feed_sources.reload
    assert_equal [sfs1.id, sfs2.id, sfs3.id], sticky_feed_sources.map(&:id)
  end

  test "feed_sourcesの関連が機能すること" do
    feed_reader = FeedReader.create!(
      title: 'テストフィードリーダー',
      position: 1,
      user: @user
    )

    feed_reader.sticky_feed_sources.create!(feed_source: @feed_source, position: 0)

    feed_source2 = @user.feed_sources.create!(
      url: 'https://example.com/feed2.xml',
      title: 'テストフィード2'
    )
    feed_reader.sticky_feed_sources.create!(feed_source: feed_source2, position: 1)

    assert_equal 2, feed_reader.feed_sources.count
    assert_includes feed_reader.feed_sources, @feed_source
    assert_includes feed_reader.feed_sources, feed_source2
  end

  test "feed_itemsの関連が機能すること" do
    feed_reader = FeedReader.create!(
      title: 'テストフィードリーダー',
      position: 1,
      user: @user
    )

    feed_reader.sticky_feed_sources.create!(feed_source: @feed_source, position: 0)

    item1 = @feed_source.feed_items.create!(
      guid: 'guid-1',
      title: '記事1',
      url: 'https://example.com/1',
      published_at: Time.current
    )
    item2 = @feed_source.feed_items.create!(
      guid: 'guid-2',
      title: '記事2',
      url: 'https://example.com/2',
      published_at: Time.current
    )

    assert_equal 2, feed_reader.feed_items.count
    assert_includes feed_reader.feed_items, item1
    assert_includes feed_reader.feed_items, item2
  end

  test "unread_items_countが未読記事数を正しく返すこと" do
    feed_reader = FeedReader.create!(
      title: 'テストフィードリーダー',
      position: 1,
      user: @user
    )

    feed_reader.sticky_feed_sources.create!(feed_source: @feed_source, position: 0)

    item1 = @feed_source.feed_items.create!(
      guid: 'guid-1',
      title: '記事1',
      url: 'https://example.com/1',
      published_at: Time.current
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
      published_at: Time.current
    )

    # 初期状態では全て未読
    assert_equal 3, feed_reader.unread_items_count(@user)

    # 1つを既読にする
    item1.mark_as_read_by(@user)
    assert_equal 2, feed_reader.unread_items_count(@user)

    # もう1つを既読にする
    item2.mark_as_read_by(@user)
    assert_equal 1, feed_reader.unread_items_count(@user)

    # 全て既読にする
    item3.mark_as_read_by(@user)
    assert_equal 0, feed_reader.unread_items_count(@user)
  end

  test "FeedReaderが削除されるとsticky_feed_sourcesも削除されること" do
    feed_reader = FeedReader.create!(
      title: 'テストフィードリーダー',
      position: 1,
      user: @user
    )

    sfs1 = feed_reader.sticky_feed_sources.create!(feed_source: @feed_source, position: 0)

    feed_reader.discard

    # 論理削除されているので、default_scopeでは取得できない
    assert_equal 0, StickyFeedSource.where(id: sfs1.id).count
    # unscopedで確認すると論理削除されている
    assert_equal 1, StickyFeedSource.unscoped.where(id: sfs1.id).discarded.count
  end
end
