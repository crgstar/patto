require "test_helper"

module Api
  class FeedSourcesControllerTest < ActionDispatch::IntegrationTest
    def setup
      @user = User.create!(
        email: 'test@example.com',
        password: 'password123',
        password_confirmation: 'password123'
      )

      @token = JWT.encode(
        { user_id: @user.id, exp: 24.hours.from_now.to_i },
        Rails.application.credentials.secret_key_base || ENV['SECRET_KEY_BASE']
      )
      @headers = { 'Authorization' => "Bearer #{@token}" }

      @feed_source = @user.feed_sources.create!(
        url: 'https://example.com/feed.xml',
        title: 'Test Feed'
      )
    end

    # 認証テスト
    test "認証なしでアクセスできないこと" do
      get api_feed_sources_path
      assert_response :unauthorized
    end

    # index アクション
    test "自分のフィードソース一覧を取得できること" do
      get api_feed_sources_path, headers: @headers
      assert_response :success

      json = JSON.parse(response.body)
      assert_equal 1, json['feed_sources'].length
      assert_equal @feed_source.id, json['feed_sources'].first['id']
      assert_equal 'Test Feed', json['feed_sources'].first['title']
    end

    test "他ユーザーのフィードソースは表示されないこと" do
      other_user = User.create!(
        email: 'other@example.com',
        password: 'password123',
        password_confirmation: 'password123'
      )
      other_user.feed_sources.create!(
        url: 'https://example.com/other-feed.xml',
        title: 'Other Feed'
      )

      get api_feed_sources_path, headers: @headers
      assert_response :success

      json = JSON.parse(response.body)
      assert_equal 1, json['feed_sources'].length
    end

    # create アクション
    test "フィードソースを作成できること" do
      assert_difference '@user.feed_sources.count', 1 do
        post api_feed_sources_path,
             params: { feed_source: { url: 'https://example.com/new-feed.xml', title: 'New Feed' } },
             headers: @headers
      end

      assert_response :created
      json = JSON.parse(response.body)
      assert_equal 'New Feed', json['feed_source']['title']
      assert_equal 'https://example.com/new-feed.xml', json['feed_source']['url']
    end

    test "無効なURLでフィードソースを作成できないこと" do
      assert_no_difference '@user.feed_sources.count' do
        post api_feed_sources_path,
             params: { feed_source: { url: 'invalid-url', title: 'Invalid Feed' } },
             headers: @headers
      end

      assert_response :unprocessable_entity
      json = JSON.parse(response.body)
      assert_includes json['errors'], 'Url is invalid'
    end

    test "URLなしでフィードソースを作成できないこと" do
      assert_no_difference '@user.feed_sources.count' do
        post api_feed_sources_path,
             params: { feed_source: { title: 'No URL Feed' } },
             headers: @headers
      end

      assert_response :unprocessable_entity
    end

    # update アクション
    test "自分のフィードソースを更新できること" do
      patch api_feed_source_path(@feed_source),
            params: { feed_source: { title: 'Updated Title' } },
            headers: @headers

      assert_response :success
      json = JSON.parse(response.body)
      assert_equal 'Updated Title', json['feed_source']['title']

      @feed_source.reload
      assert_equal 'Updated Title', @feed_source.title
    end

    test "他ユーザーのフィードソースを更新できないこと" do
      other_user = User.create!(
        email: 'other@example.com',
        password: 'password123',
        password_confirmation: 'password123'
      )
      other_feed_source = other_user.feed_sources.create!(
        url: 'https://example.com/other-feed.xml',
        title: 'Other Feed'
      )

      patch api_feed_source_path(other_feed_source),
            params: { feed_source: { title: 'Hacked Title' } },
            headers: @headers

      assert_response :not_found
    end

    # destroy アクション
    test "自分のフィードソースを削除できること" do
      delete api_feed_source_path(@feed_source), headers: @headers
      assert_response :no_content

      @feed_source.reload
      assert @feed_source.discarded?
    end

    test "他ユーザーのフィードソースを削除できないこと" do
      other_user = User.create!(
        email: 'other@example.com',
        password: 'password123',
        password_confirmation: 'password123'
      )
      other_feed_source = other_user.feed_sources.create!(
        url: 'https://example.com/other-feed.xml',
        title: 'Other Feed'
      )

      delete api_feed_source_path(other_feed_source), headers: @headers
      assert_response :not_found

      other_feed_source.reload
      assert_not other_feed_source.discarded?
    end

    # refresh アクション
    test "フィードを手動で更新できること" do
      rss_xml = <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <rss version="2.0">
          <channel>
            <title>Refreshed Feed</title>
            <description>Refreshed description</description>
            <item>
              <guid>item-1</guid>
              <title>Item 1</title>
              <link>https://example.com/item-1</link>
            </item>
          </channel>
        </rss>
      XML

      stub_request(:get, @feed_source.url)
        .to_return(status: 200, body: rss_xml)

      post refresh_api_feed_source_path(@feed_source), headers: @headers
      assert_response :success

      json = JSON.parse(response.body)
      assert_equal 'Refreshed Feed', json['feed_source']['title']

      @feed_source.reload
      assert_equal 'Refreshed Feed', @feed_source.title
      assert_equal 1, @feed_source.feed_items.count
    end

    test "フィード更新失敗時にエラーを返すこと" do
      stub_request(:get, @feed_source.url)
        .to_return(status: 404)

      post refresh_api_feed_source_path(@feed_source), headers: @headers
      assert_response :unprocessable_entity

      json = JSON.parse(response.body)
      assert_includes json['error'], 'Failed to refresh feed'
    end
  end
end
