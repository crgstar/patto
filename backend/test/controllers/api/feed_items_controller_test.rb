require "test_helper"

class Api::FeedItemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      email: 'test@example.com',
      password: 'password123',
      password_confirmation: 'password123'
    )

    @other_user = User.create!(
      email: 'other@example.com',
      password: 'password123',
      password_confirmation: 'password123'
    )

    @token = JWT.encode(
      { user_id: @user.id, exp: 24.hours.from_now.to_i },
      Rails.application.credentials.secret_key_base || ENV['SECRET_KEY_BASE']
    )

    # FeedReaderの作成
    @feed_reader = FeedReader.create!(
      title: 'テストフィードリーダー',
      position: 1,
      user: @user
    )

    @other_feed_reader = FeedReader.create!(
      title: '他のユーザーのフィードリーダー',
      position: 1,
      user: @other_user
    )

    # FeedSourceの作成
    @feed_source = FeedSource.create!(
      url: 'https://example.com/feed.rss',
      title: 'テストフィード',
      user: @user
    )

    @other_feed_source = FeedSource.create!(
      url: 'https://other.example.com/feed.rss',
      title: '他のユーザーのフィード',
      user: @other_user
    )

    # StickyFeedSourceの紐付け
    @sticky_feed_source = StickyFeedSource.create!(
      sticky: @feed_reader,
      feed_source: @feed_source,
      position: 0
    )

    # FeedItemの作成
    @feed_item1 = FeedItem.create!(
      feed_source: @feed_source,
      guid: 'item-1',
      title: 'テスト記事1',
      url: 'https://example.com/article1',
      description: 'テスト記事1の説明',
      published_at: 2.days.ago
    )

    @feed_item2 = FeedItem.create!(
      feed_source: @feed_source,
      guid: 'item-2',
      title: 'テスト記事2',
      url: 'https://example.com/article2',
      description: 'テスト記事2の説明',
      published_at: 1.day.ago
    )

    @feed_item3 = FeedItem.create!(
      feed_source: @feed_source,
      guid: 'item-3',
      title: 'テスト記事3',
      url: 'https://example.com/article3',
      description: 'テスト記事3の説明',
      published_at: Time.current
    )
  end

  # 認証テスト
  test "should not get feed items without token" do
    get api_sticky_feed_items_url(@feed_reader), as: :json

    assert_response :unauthorized
  end

  # Index tests
  test "should get feed items with valid token" do
    get api_sticky_feed_items_url(@feed_reader),
        headers: { 'Authorization' => "Bearer #{@token}" },
        as: :json

    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 3, json_response['feed_items'].length
    # published_atの降順で返されることを確認
    assert_equal 'テスト記事3', json_response['feed_items'][0]['title']
    assert_equal 'テスト記事2', json_response['feed_items'][1]['title']
    assert_equal 'テスト記事1', json_response['feed_items'][2]['title']

    # feed_source情報が含まれることを確認
    assert_not_nil json_response['feed_items'][0]['feed_source']
    assert_equal 'example.com', json_response['feed_items'][0]['feed_source']['domain']
  end

  test "should not get feed items for other user's feed reader" do
    get api_sticky_feed_items_url(@other_feed_reader),
        headers: { 'Authorization' => "Bearer #{@token}" },
        as: :json

    assert_response :not_found
  end

  test "should filter unread feed items" do
    # 1つを既読にする
    @feed_item1.mark_as_read_by(@user)

    get api_sticky_feed_items_url(@feed_reader, filter: 'unread'),
        headers: { 'Authorization' => "Bearer #{@token}" },
        as: :json

    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 2, json_response['feed_items'].length
    assert_not_includes json_response['feed_items'].map { |i| i['id'] }, @feed_item1.id
  end

  test "should filter read feed items" do
    # 1つを既読にする
    @feed_item1.mark_as_read_by(@user)

    get api_sticky_feed_items_url(@feed_reader, filter: 'read'),
        headers: { 'Authorization' => "Bearer #{@token}" },
        as: :json

    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 1, json_response['feed_items'].length
    assert_equal @feed_item1.id, json_response['feed_items'][0]['id']
  end

  test "should include read status in feed items response" do
    # 1つを既読にする
    @feed_item1.mark_as_read_by(@user)

    get api_sticky_feed_items_url(@feed_reader),
        headers: { 'Authorization' => "Bearer #{@token}" },
        as: :json

    assert_response :ok
    json_response = JSON.parse(response.body)

    read_item = json_response['feed_items'].find { |i| i['id'] == @feed_item1.id }
    unread_item = json_response['feed_items'].find { |i| i['id'] == @feed_item2.id }

    assert_equal true, read_item['read']
    assert_equal false, unread_item['read']
  end

  # Mark as read tests
  test "should mark feed item as read" do
    assert_equal false, @feed_item1.read_by?(@user)

    post mark_as_read_api_sticky_feed_item_url(@feed_reader, @feed_item1),
         headers: { 'Authorization' => "Bearer #{@token}" },
         as: :json

    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal true, json_response['feed_item']['read']

    assert_equal true, @feed_item1.read_by?(@user)
  end

  test "should not mark feed item as read for other user's feed reader" do
    post mark_as_read_api_sticky_feed_item_url(@other_feed_reader, @feed_item1),
         headers: { 'Authorization' => "Bearer #{@token}" },
         as: :json

    assert_response :not_found
  end

  test "should not mark non-existent feed item as read" do
    post mark_as_read_api_sticky_feed_item_url(@feed_reader, id: 99999),
         headers: { 'Authorization' => "Bearer #{@token}" },
         as: :json

    assert_response :not_found
  end

  # Mark as unread tests
  test "should mark feed item as unread" do
    @feed_item1.mark_as_read_by(@user)
    assert_equal true, @feed_item1.read_by?(@user)

    post mark_as_unread_api_sticky_feed_item_url(@feed_reader, @feed_item1),
         headers: { 'Authorization' => "Bearer #{@token}" },
         as: :json

    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal false, json_response['feed_item']['read']

    assert_equal false, @feed_item1.read_by?(@user)
  end

  test "should not mark feed item as unread for other user's feed reader" do
    post mark_as_unread_api_sticky_feed_item_url(@other_feed_reader, @feed_item1),
         headers: { 'Authorization' => "Bearer #{@token}" },
         as: :json

    assert_response :not_found
  end

  # Mark all as read tests
  test "should mark all feed items as read" do
    assert_equal false, @feed_item1.read_by?(@user)
    assert_equal false, @feed_item2.read_by?(@user)
    assert_equal false, @feed_item3.read_by?(@user)

    post mark_all_as_read_api_sticky_feed_items_url(@feed_reader),
         headers: { 'Authorization' => "Bearer #{@token}" },
         as: :json

    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'すべての記事を既読にしました', json_response['message']

    assert_equal true, @feed_item1.read_by?(@user)
    assert_equal true, @feed_item2.read_by?(@user)
    assert_equal true, @feed_item3.read_by?(@user)
  end

  test "should not mark all feed items as read for other user's feed reader" do
    post mark_all_as_read_api_sticky_feed_items_url(@other_feed_reader),
         headers: { 'Authorization' => "Bearer #{@token}" },
         as: :json

    assert_response :not_found
  end

  # Refresh all tests
  test "should refresh all feed sources" do
    # WebMockでHTTPリクエストをモック
    stub_request(:get, @feed_source.url)
      .to_return(
        status: 200,
        body: <<~RSS
          <?xml version="1.0" encoding="UTF-8"?>
          <rss version="2.0">
            <channel>
              <title>テストフィード</title>
              <description>テストフィードの説明</description>
              <item>
                <guid>new-item-1</guid>
                <title>新しい記事1</title>
                <link>https://example.com/new-article1</link>
                <description>新しい記事1の説明</description>
                <pubDate>#{Time.current.rfc2822}</pubDate>
              </item>
            </channel>
          </rss>
        RSS
      )

    post api_sticky_refresh_all_url(@feed_reader),
         headers: { 'Authorization' => "Bearer #{@token}" },
         as: :json

    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'フィードを更新しました', json_response['message']
  end

  test "should not refresh all feed sources for other user's feed reader" do
    post api_sticky_refresh_all_url(@other_feed_reader),
         headers: { 'Authorization' => "Bearer #{@token}" },
         as: :json

    assert_response :not_found
  end

  # Feed source filtering tests
  test "should filter feed items by feed_source_id" do
    # 別のフィードソースを作成
    @feed_source2 = FeedSource.create!(
      url: 'https://example2.com/feed.rss',
      title: 'テストフィード2',
      user: @user
    )

    # feed_readerに追加
    StickyFeedSource.create!(
      sticky: @feed_reader,
      feed_source: @feed_source2,
      position: 1
    )

    # feed_source2に紐づくアイテムを作成
    @feed_item_source2 = FeedItem.create!(
      feed_source: @feed_source2,
      guid: 'item-source2-1',
      title: 'フィード2の記事',
      url: 'https://example2.com/article1',
      description: 'フィード2の記事説明',
      published_at: Time.current
    )

    # feed_source_idでフィルタ
    get api_sticky_feed_items_url(@feed_reader, feed_source_id: @feed_source.id),
        headers: { 'Authorization' => "Bearer #{@token}" },
        as: :json

    assert_response :ok
    json_response = JSON.parse(response.body)

    # @feed_sourceのアイテムのみが返される
    assert_equal 3, json_response['feed_items'].length
    json_response['feed_items'].each do |item|
      assert_equal @feed_source.id, item['feed_source']['id']
    end
  end

  test "should combine feed_source_id filter with read/unread filter" do
    # 別のフィードソースを作成
    @feed_source2 = FeedSource.create!(
      url: 'https://example3.com/feed.rss',
      title: 'テストフィード3',
      user: @user
    )

    StickyFeedSource.create!(
      sticky: @feed_reader,
      feed_source: @feed_source2,
      position: 1
    )

    @feed_item_source2 = FeedItem.create!(
      feed_source: @feed_source2,
      guid: 'item-source2-2',
      title: 'フィード3の記事',
      url: 'https://example3.com/article1',
      description: 'フィード3の記事説明',
      published_at: Time.current
    )

    # feed_source1のアイテムを1つ既読にする
    @feed_item1.mark_as_read_by(@user)

    # feed_source_idとunreadフィルタを併用
    get api_sticky_feed_items_url(@feed_reader, feed_source_id: @feed_source.id, filter: 'unread'),
        headers: { 'Authorization' => "Bearer #{@token}" },
        as: :json

    assert_response :ok
    json_response = JSON.parse(response.body)

    # @feed_sourceの未読アイテムのみが返される（2件）
    assert_equal 2, json_response['feed_items'].length
    json_response['feed_items'].each do |item|
      assert_equal @feed_source.id, item['feed_source']['id']
      assert_equal false, item['read']
    end

    # 既読アイテムは含まれない
    assert_not_includes json_response['feed_items'].map { |i| i['id'] }, @feed_item1.id
  end

  test "should return empty array for non-existent feed_source_id" do
    get api_sticky_feed_items_url(@feed_reader, feed_source_id: 99999),
        headers: { 'Authorization' => "Bearer #{@token}" },
        as: :json

    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 0, json_response['feed_items'].length
  end

  test "should not return feed items for other user's feed_source" do
    # 他のユーザーのfeed_source_idでフィルタ
    get api_sticky_feed_items_url(@feed_reader, feed_source_id: @other_feed_source.id),
        headers: { 'Authorization' => "Bearer #{@token}" },
        as: :json

    assert_response :ok
    json_response = JSON.parse(response.body)
    # FeedReaderに紐づいていないので0件
    assert_equal 0, json_response['feed_items'].length
  end
end
