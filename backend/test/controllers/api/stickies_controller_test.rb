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
end
