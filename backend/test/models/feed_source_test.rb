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

  test "RSSフィードを取得して保存できること" do
    feed_source = @user.feed_sources.create!(
      url: 'https://example.com/rss.xml'
    )

    rss_xml = <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <rss version="2.0">
        <channel>
          <title>Test RSS Feed</title>
          <description>RSS feed for testing</description>
          <link>https://example.com</link>
          <item>
            <guid>https://example.com/article-1</guid>
            <title>Article 1</title>
            <link>https://example.com/article-1</link>
            <description>Article 1 summary</description>
            <pubDate>Mon, 16 Dec 2024 10:00:00 +0000</pubDate>
            <author>Test Author</author>
          </item>
          <item>
            <guid>https://example.com/article-2</guid>
            <title>Article 2</title>
            <link>https://example.com/article-2</link>
            <description>Article 2 summary</description>
            <pubDate>Mon, 16 Dec 2024 11:00:00 +0000</pubDate>
          </item>
        </channel>
      </rss>
    XML

    stub_request(:get, 'https://example.com/rss.xml')
      .to_return(status: 200, body: rss_xml, headers: { 'Content-Type' => 'application/rss+xml' })

    result = feed_source.fetch_and_save_items
    assert result, "RSSフィードの取得に失敗しました"

    feed_source.reload
    assert_equal 'Test RSS Feed', feed_source.title
    assert_equal 'RSS feed for testing', feed_source.description
    assert_not_nil feed_source.last_fetched_at
    assert_nil feed_source.fetch_error

    assert_equal 2, feed_source.feed_items.count, "フィードアイテムが正しく保存されていません"

    item1 = feed_source.feed_items.find_by(guid: 'https://example.com/article-1')
    assert_not_nil item1, "Article 1が保存されていません"
    assert_equal 'Article 1', item1.title
    assert_equal 'https://example.com/article-1', item1.url
    assert_equal 'Article 1 summary', item1.description
    assert_equal 'Test Author', item1.author
  end

  test "Atomフィードを取得して保存できること" do
    feed_source = @user.feed_sources.create!(
      url: 'https://example.com/atom.xml'
    )

    atom_xml = <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <feed xmlns="http://www.w3.org/2005/Atom">
        <title>Test Atom Feed</title>
        <subtitle>Atom feed for testing</subtitle>
        <link href="https://example.com"/>
        <updated>2024-12-16T10:00:00Z</updated>
        <entry>
          <id>https://example.com/entry-1</id>
          <title>Entry 1</title>
          <link href="https://example.com/entry-1"/>
          <summary>Entry 1 summary</summary>
          <content>Entry 1 content</content>
          <published>2024-12-16T10:00:00Z</published>
          <author>
            <name>Test Author</name>
          </author>
        </entry>
      </feed>
    XML

    stub_request(:get, 'https://example.com/atom.xml')
      .to_return(status: 200, body: atom_xml, headers: { 'Content-Type' => 'application/atom+xml' })

    result = feed_source.fetch_and_save_items
    assert result, "Atomフィードの取得に失敗しました"

    feed_source.reload
    assert_equal 'Test Atom Feed', feed_source.title
    assert_equal 'Atom feed for testing', feed_source.description

    assert_equal 1, feed_source.feed_items.count
    item1 = feed_source.feed_items.first
    assert_equal 'Entry 1', item1.title
    assert_equal 'Entry 1 content', item1.content
  end

  test "フィード取得失敗時にエラーを記録すること" do
    feed_source = @user.feed_sources.create!(
      url: 'https://example.com/notfound.xml'
    )

    stub_request(:get, 'https://example.com/notfound.xml')
      .to_return(status: 404)

    result = feed_source.fetch_and_save_items
    assert_not result, "エラーが発生しているのにtrueが返されました"

    feed_source.reload
    assert_not_nil feed_source.last_fetched_at
    assert_not_nil feed_source.fetch_error
    assert_includes feed_source.fetch_error, "HTTP 404"
  end

  test "無効なフィード形式でエラーを記録すること" do
    feed_source = @user.feed_sources.create!(
      url: 'https://example.com/invalid.xml'
    )

    stub_request(:get, 'https://example.com/invalid.xml')
      .to_return(status: 200, body: '<html>Not a feed</html>')

    result = feed_source.fetch_and_save_items
    assert_not result, "無効なフィード形式なのにtrueが返されました"

    feed_source.reload
    assert_not_nil feed_source.fetch_error
    # パースできない場合、Feedjiraはnilを返すかNoParserAvailable例外を投げる
    assert feed_source.fetch_error.include?("Unsupported feed format") || feed_source.fetch_error.include?("Failed to parse feed")
  end

  test "重複したエントリは作成されないこと" do
    feed_source = @user.feed_sources.create!(
      url: 'https://example.com/rss.xml'
    )

    rss_xml = <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <rss version="2.0">
        <channel>
          <title>Test Feed</title>
          <item>
            <guid>unique-id-1</guid>
            <title>Article 1</title>
            <link>https://example.com/article-1</link>
          </item>
        </channel>
      </rss>
    XML

    stub_request(:get, 'https://example.com/rss.xml')
      .to_return(status: 200, body: rss_xml)

    # 1回目の取得
    feed_source.fetch_and_save_items
    assert_equal 1, feed_source.feed_items.count

    # 2回目の取得（同じフィード）
    feed_source.fetch_and_save_items
    assert_equal 1, feed_source.feed_items.count, "重複したエントリが作成されました"
  end
end
