require "test_helper"

class Api::StickiesControllerTest < ActionDispatch::IntegrationTest
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

    @sticky = Sticky.create!(
      type: 'Sticky',
      title: 'Test Sticky',
      content: 'Test content',
      position: 1,
      user: @user
    )

    @other_sticky = Sticky.create!(
      type: 'Sticky',
      title: 'Other Sticky',
      content: 'Other content',
      position: 1,
      user: @other_user
    )
  end

  # Index tests
  test "should get index with valid token" do
    get api_stickies_url,
        headers: { 'Authorization' => "Bearer #{@token}" },
        as: :json

    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 1, json_response['stickies'].length
    assert_equal @sticky.id, json_response['stickies'][0]['id']
  end

  test "should not get index without token" do
    get api_stickies_url, as: :json

    assert_response :unauthorized
  end

  test "should not include discarded stickies in index" do
    @sticky.discard

    get api_stickies_url,
        headers: { 'Authorization' => "Bearer #{@token}" },
        as: :json

    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 0, json_response['stickies'].length
  end

  # Create tests
  test "should create sticky with valid params" do
    assert_difference('Sticky.count', 1) do
      post api_stickies_url,
           headers: { 'Authorization' => "Bearer #{@token}" },
           params: {
             sticky: {
               type: 'Sticky',
               title: 'New Sticky',
               content: 'New content',
               position: 2
             }
           },
           as: :json
    end

    assert_response :created
    json_response = JSON.parse(response.body)
    assert_equal 'New Sticky', json_response['sticky']['title']
    assert_equal @user.id, json_response['sticky']['user_id']
  end

  test "should not create sticky without token" do
    assert_no_difference('Sticky.count') do
      post api_stickies_url,
           params: {
             sticky: {
               type: 'Sticky',
               title: 'New Sticky'
             }
           },
           as: :json
    end

    assert_response :unauthorized
  end

  test "should not create sticky without type" do
    assert_no_difference('Sticky.count') do
      post api_stickies_url,
           headers: { 'Authorization' => "Bearer #{@token}" },
           params: {
             sticky: {
               title: 'New Sticky',
               content: 'New content'
             }
           },
           as: :json
    end

    assert_response :unprocessable_entity
  end

  # Update tests
  test "should update sticky with valid params" do
    patch api_sticky_url(@sticky),
          headers: { 'Authorization' => "Bearer #{@token}" },
          params: {
            sticky: {
              title: 'Updated Title',
              content: 'Updated content'
            }
          },
          as: :json

    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Updated Title', json_response['sticky']['title']
    assert_equal 'Updated content', json_response['sticky']['content']
  end

  test "should not update other user's sticky" do
    patch api_sticky_url(@other_sticky),
          headers: { 'Authorization' => "Bearer #{@token}" },
          params: {
            sticky: {
              title: 'Hacked Title'
            }
          },
          as: :json

    assert_response :not_found
  end

  test "should not update sticky without token" do
    patch api_sticky_url(@sticky),
          params: {
            sticky: {
              title: 'Updated Title'
            }
          },
          as: :json

    assert_response :unauthorized
  end

  # Delete tests
  test "should discard sticky" do
    assert_no_difference('Sticky.unscoped.count') do
      delete api_sticky_url(@sticky),
             headers: { 'Authorization' => "Bearer #{@token}" },
             as: :json
    end

    assert_response :no_content
    @sticky.reload
    assert @sticky.discarded?
  end

  test "should not delete other user's sticky" do
    delete api_sticky_url(@other_sticky),
           headers: { 'Authorization' => "Bearer #{@token}" },
           as: :json

    assert_response :not_found
  end

  test "should not delete sticky without token" do
    delete api_sticky_url(@sticky), as: :json

    assert_response :unauthorized
  end

  # Reorder tests
  test "should reorder stickies" do
    sticky2 = Sticky.create!(
      type: 'Sticky',
      title: 'Second Sticky',
      position: 2,
      user: @user
    )

    patch reorder_api_stickies_url,
          headers: { 'Authorization' => "Bearer #{@token}" },
          params: {
            stickies: [
              { id: sticky2.id, position: 1 },
              { id: @sticky.id, position: 2 }
            ]
          },
          as: :json

    assert_response :ok
    @sticky.reload
    sticky2.reload
    assert_equal 2, @sticky.position
    assert_equal 1, sticky2.position
  end

  test "should not reorder other user's stickies" do
    patch reorder_api_stickies_url,
          headers: { 'Authorization' => "Bearer #{@token}" },
          params: {
            stickies: [
              { id: @other_sticky.id, position: 5 }
            ]
          },
          as: :json

    assert_response :ok
    @other_sticky.reload
    assert_equal 1, @other_sticky.position  # Should not change
  end

  test "should not reorder without token" do
    patch reorder_api_stickies_url,
          params: {
            stickies: [
              { id: @sticky.id, position: 5 }
            ]
          },
          as: :json

    assert_response :unauthorized
  end

  # 座標関連のテスト
  test "should create sticky with coordinates" do
    post api_stickies_url,
         headers: { 'Authorization' => "Bearer #{@token}" },
         params: {
           sticky: {
             type: 'Sticky',
             title: 'Test Sticky',
             content: 'Test content',
             x: 5,
             y: 10,
             width: 2,
             height: 3
           }
         },
         as: :json

    assert_response :created
    json_response = JSON.parse(response.body)

    assert_equal 5, json_response['sticky']['x']
    assert_equal 10, json_response['sticky']['y']
    assert_equal 2, json_response['sticky']['width']
    assert_equal 3, json_response['sticky']['height']
  end

  test "should create sticky with auto positioning when coordinates not specified" do
    post api_stickies_url,
         headers: { 'Authorization' => "Bearer #{@token}" },
         params: {
           sticky: {
             type: 'Sticky',
             title: 'Test Sticky',
             content: 'Test content'
           }
         },
         as: :json

    assert_response :created
    json_response = JSON.parse(response.body)

    assert_not_nil json_response['sticky']['x']
    assert_not_nil json_response['sticky']['y']
    assert_equal 1, json_response['sticky']['width']
    assert_equal 1, json_response['sticky']['height']
  end

  test "should include coordinates in index response" do
    @sticky.update!(x: 3, y: 7, width: 2, height: 2)

    get api_stickies_url,
        headers: { 'Authorization' => "Bearer #{@token}" },
        as: :json

    assert_response :ok
    json_response = JSON.parse(response.body)
    sticky_data = json_response['stickies'].first

    assert_equal 3, sticky_data['x']
    assert_equal 7, sticky_data['y']
    assert_equal 2, sticky_data['width']
    assert_equal 2, sticky_data['height']
  end

  test "should update sticky coordinates" do
    patch api_sticky_url(@sticky),
          headers: { 'Authorization' => "Bearer #{@token}" },
          params: {
            sticky: {
              x: 5,
              y: 10,
              width: 3,
              height: 2
            }
          },
          as: :json

    assert_response :ok
    json_response = JSON.parse(response.body)

    assert_equal 5, json_response['sticky']['x']
    assert_equal 10, json_response['sticky']['y']
    assert_equal 3, json_response['sticky']['width']
    assert_equal 2, json_response['sticky']['height']
  end

  test "should reorder stickies with coordinates" do
    sticky2 = Sticky.create!(
      type: 'Sticky',
      title: 'Second Sticky',
      x: 0,
      y: 1,
      user: @user
    )

    patch reorder_api_stickies_url,
          headers: { 'Authorization' => "Bearer #{@token}" },
          params: {
            stickies: [
              { id: @sticky.id, x: 5, y: 10, w: 2, h: 3 },
              { id: sticky2.id, x: 7, y: 12, w: 1, h: 2 }
            ]
          },
          as: :json

    assert_response :ok

    @sticky.reload
    sticky2.reload

    assert_equal 5, @sticky.x
    assert_equal 10, @sticky.y
    assert_equal 2, @sticky.width
    assert_equal 3, @sticky.height

    assert_equal 7, sticky2.x
    assert_equal 12, sticky2.y
    assert_equal 1, sticky2.width
    assert_equal 2, sticky2.height
  end

  # Calendar (STI) tests
  test "should create calendar with type Calendar" do
    assert_difference('Calendar.count', 1) do
      post api_stickies_url,
           headers: { 'Authorization' => "Bearer #{@token}" },
           params: {
             sticky: {
               type: 'Calendar',
               title: 'My Calendar',
               position: 2
             }
           },
           as: :json
    end

    assert_response :created
    json_response = JSON.parse(response.body)
    assert_equal 'My Calendar', json_response['sticky']['title']
    assert_equal 'Calendar', json_response['sticky']['type']
    assert_equal @user.id, json_response['sticky']['user_id']
  end

  test "should update calendar" do
    calendar = Calendar.create!(
      title: 'Original Calendar',
      position: 1,
      user: @user
    )

    patch api_sticky_url(calendar),
          headers: { 'Authorization' => "Bearer #{@token}" },
          params: {
            sticky: {
              title: 'Updated Calendar',
              x: 5,
              y: 10
            }
          },
          as: :json

    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Updated Calendar', json_response['sticky']['title']
    assert_equal 'Calendar', json_response['sticky']['type']
    assert_equal 5, json_response['sticky']['x']
    assert_equal 10, json_response['sticky']['y']
  end

  test "should discard calendar" do
    calendar = Calendar.create!(
      title: 'Test Calendar',
      position: 1,
      user: @user
    )

    assert_no_difference('Sticky.unscoped.count') do
      delete api_sticky_url(calendar),
             headers: { 'Authorization' => "Bearer #{@token}" },
             as: :json
    end

    assert_response :no_content
    calendar.reload
    assert calendar.discarded?
  end

  test "should include both stickies and calendars in index" do
    calendar = Calendar.create!(
      title: 'Test Calendar',
      position: 2,
      user: @user
    )

    get api_stickies_url,
        headers: { 'Authorization' => "Bearer #{@token}" },
        as: :json

    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 2, json_response['stickies'].length

    types = json_response['stickies'].map { |s| s['type'] }.sort
    assert_equal ['Calendar', 'Sticky'], types
  end

  test "should reorder both stickies and calendars together" do
    calendar = Calendar.create!(
      title: 'Test Calendar',
      position: 2,
      user: @user
    )

    patch reorder_api_stickies_url,
          headers: { 'Authorization' => "Bearer #{@token}" },
          params: {
            stickies: [
              { id: calendar.id, position: 1, x: 0, y: 0 },
              { id: @sticky.id, position: 2, x: 0, y: 1 }
            ]
          },
          as: :json

    assert_response :ok
    @sticky.reload
    calendar.reload
    assert_equal 2, @sticky.position
    assert_equal 1, calendar.position
  end
end
