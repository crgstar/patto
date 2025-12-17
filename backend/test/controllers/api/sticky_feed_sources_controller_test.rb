require "test_helper"

module Api
  class StickyFeedSourcesControllerTest < ActionDispatch::IntegrationTest
    def setup
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

      @feed_reader = FeedReader.create!(
        title: 'マイフィードリーダー',
        position: 1,
        user: @user
      )

      @other_feed_reader = FeedReader.create!(
        title: '他のユーザーのフィードリーダー',
        position: 1,
        user: @other_user
      )

      @feed_source = @user.feed_sources.create!(
        url: 'https://example.com/feed1.xml',
        title: 'Feed 1'
      )

      @feed_source2 = @user.feed_sources.create!(
        url: 'https://example.com/feed2.xml',
        title: 'Feed 2'
      )

      @other_feed_source = @other_user.feed_sources.create!(
        url: 'https://example.com/other-feed.xml',
        title: 'Other Feed'
      )

      @sticky_feed_source = @feed_reader.sticky_feed_sources.create!(
        feed_source: @feed_source,
        position: 0
      )
    end

    # 認証テスト
    test "認証なしでアクセスできないこと" do
      get api_sticky_sticky_feed_sources_path(@feed_reader)
      assert_response :unauthorized
    end

    # index アクション
    test "Stickyに紐づくフィードソース一覧を取得できること" do
      get api_sticky_sticky_feed_sources_path(@feed_reader), headers: { 'Authorization' => "Bearer #{@token}" }
      assert_response :success

      json = JSON.parse(response.body)
      assert_equal 1, json['sticky_feed_sources'].length
      assert_equal @sticky_feed_source.id, json['sticky_feed_sources'].first['id']
      assert_equal @feed_source.id, json['sticky_feed_sources'].first['feed_source_id']
    end

    test "他ユーザーのStickyのフィードソースは取得できないこと" do
      get api_sticky_sticky_feed_sources_path(@other_feed_reader), headers: { 'Authorization' => "Bearer #{@token}" }
      assert_response :not_found
    end

    # create アクション
    test "Stickyにフィードソースを追加できること" do
      assert_difference '@feed_reader.sticky_feed_sources.count', 1 do
        post api_sticky_sticky_feed_sources_path(@feed_reader),
             params: { sticky_feed_source: { feed_source_id: @feed_source2.id, position: 1 } },
             headers: { 'Authorization' => "Bearer #{@token}" }
      end

      assert_response :created
      json = JSON.parse(response.body)
      assert_equal @feed_source2.id, json['sticky_feed_source']['feed_source_id']
      assert_equal 1, json['sticky_feed_source']['position']
    end

    test "同じフィードソースを重複して追加できないこと" do
      assert_no_difference '@feed_reader.sticky_feed_sources.count' do
        post api_sticky_sticky_feed_sources_path(@feed_reader),
             params: { sticky_feed_source: { feed_source_id: @feed_source.id, position: 1 } },
             headers: { 'Authorization' => "Bearer #{@token}" }
      end

      assert_response :unprocessable_entity
      json = JSON.parse(response.body)
      assert_includes json['errors'].join, 'has already been taken'
    end

    test "他ユーザーのフィードソースを追加できないこと" do
      assert_no_difference '@feed_reader.sticky_feed_sources.count' do
        post api_sticky_sticky_feed_sources_path(@feed_reader),
             params: { sticky_feed_source: { feed_source_id: @other_feed_source.id, position: 1 } },
             headers: { 'Authorization' => "Bearer #{@token}" }
      end

      assert_response :not_found
    end

    test "他ユーザーのStickyにフィードソースを追加できないこと" do
      assert_no_difference 'StickyFeedSource.count' do
        post api_sticky_sticky_feed_sources_path(@other_feed_reader),
             params: { sticky_feed_source: { feed_source_id: @feed_source.id, position: 0 } },
             headers: { 'Authorization' => "Bearer #{@token}" }
      end

      assert_response :not_found
    end

    # destroy アクション
    test "Stickyからフィードソースを削除できること" do
      delete api_sticky_sticky_feed_source_path(@feed_reader, @sticky_feed_source),
             headers: { 'Authorization' => "Bearer #{@token}" }

      assert_response :no_content
      @sticky_feed_source.reload
      assert @sticky_feed_source.discarded?
    end

    test "他ユーザーのStickyFeedSourceを削除できないこと" do
      other_sticky_feed_source = @other_feed_reader.sticky_feed_sources.create!(
        feed_source: @other_feed_source,
        position: 0
      )

      delete api_sticky_sticky_feed_source_path(@other_feed_reader, other_sticky_feed_source),
             headers: { 'Authorization' => "Bearer #{@token}" }

      assert_response :not_found
      other_sticky_feed_source.reload
      assert_not other_sticky_feed_source.discarded?
    end

    # reorder アクション
    test "フィードソースを並び替えできること" do
      sticky_feed_source2 = @feed_reader.sticky_feed_sources.create!(
        feed_source: @feed_source2,
        position: 1
      )

      patch reorder_api_sticky_sticky_feed_sources_path(@feed_reader),
            params: {
              sticky_feed_sources: [
                { id: @sticky_feed_source.id, position: 1 },
                { id: sticky_feed_source2.id, position: 0 }
              ]
            },
            headers: { 'Authorization' => "Bearer #{@token}" }

      assert_response :ok
      @sticky_feed_source.reload
      sticky_feed_source2.reload
      assert_equal 1, @sticky_feed_source.position
      assert_equal 0, sticky_feed_source2.position
    end

    test "他ユーザーのStickyのフィードソースを並び替えできないこと" do
      patch reorder_api_sticky_sticky_feed_sources_path(@other_feed_reader),
            params: { sticky_feed_sources: [] },
            headers: { 'Authorization' => "Bearer #{@token}" }

      assert_response :not_found
    end
  end
end
