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
      # フィード作成時に自動取得を試みるが、ここでは404を返して失敗させる
      stub_request(:get, 'https://example.com/new-feed.xml')
        .to_return(status: 404)

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

    # 削除済みフィードソースの再登録テスト
    test "削除済みフィードソースを再登録できること" do
      @feed_source.discard
      assert @feed_source.discarded?

      # フィード作成時に自動取得を試みるが、ここでは404を返して失敗させる
      stub_request(:get, @feed_source.url)
        .to_return(status: 404)

      assert_no_difference '@user.feed_sources.with_discarded.count' do
        post api_feed_sources_path,
             params: { feed_source: { url: @feed_source.url, title: 'Restored Feed' } },
             headers: @headers
      end

      assert_response :created
      json = JSON.parse(response.body)
      assert_equal 'Restored Feed', json['feed_source']['title']

      @feed_source.reload
      assert_not @feed_source.discarded?
    end

    test "削除済みフィードソースを再登録時にパラメータが更新されること" do
      @feed_source.update!(title: 'Original', description: 'Original Description')
      @feed_source.discard

      # フィード作成時に自動取得を試みるが、ここでは404を返して失敗させる
      stub_request(:get, @feed_source.url)
        .to_return(status: 404)

      post api_feed_sources_path,
           params: { feed_source: { url: @feed_source.url, title: 'New Title', description: 'New Description' } },
           headers: @headers

      assert_response :created

      @feed_source.reload
      assert_not @feed_source.discarded?
      assert_equal 'New Title', @feed_source.title
      assert_equal 'New Description', @feed_source.description
    end

    test "削除済みでないフィードソースは重複登録できないこと" do
      stub_request(:get, @feed_source.url)
        .to_return(status: 404)

      assert_no_difference '@user.feed_sources.count' do
        post api_feed_sources_path,
             params: { feed_source: { url: @feed_source.url } },
             headers: @headers
      end

      assert_response :unprocessable_entity
      json = JSON.parse(response.body)
      assert_includes json['errors'].join, 'has already been taken'
    end

    test "フィードソース作成時に自動的にフィードデータを取得すること" do
      rss_xml = <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <rss version="2.0">
          <channel>
            <title>Auto Fetched Feed</title>
            <description>This feed was automatically fetched</description>
            <item>
              <guid>auto-item-1</guid>
              <title>Auto Item 1</title>
              <link>https://example.com/auto-item-1</link>
            </item>
          </channel>
        </rss>
      XML

      stub_request(:get, 'https://example.com/auto-feed.xml')
        .to_return(status: 200, body: rss_xml)

      assert_difference '@user.feed_sources.count', 1 do
        post api_feed_sources_path,
             params: { feed_source: { url: 'https://example.com/auto-feed.xml', title: 'Original Title' } },
             headers: @headers
      end

      assert_response :created
      json = JSON.parse(response.body)
      # フィードから取得したタイトルで上書きされる
      assert_equal 'Auto Fetched Feed', json['feed_source']['title']
      assert_equal 'This feed was automatically fetched', json['feed_source']['description']

      # フィードアイテムも保存されていることを確認
      feed_source = @user.feed_sources.find(json['feed_source']['id'])
      assert_equal 1, feed_source.feed_items.count
      assert_equal 'Auto Item 1', feed_source.feed_items.first.title
    end
  end
end
