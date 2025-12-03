require "test_helper"

class Api::CurrentUserControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      email: 'test@example.com',
      password: 'password123',
      password_confirmation: 'password123'
    )

    # JWTトークンを生成
    @token = JWT.encode(
      { user_id: @user.id, exp: 24.hours.from_now.to_i },
      Rails.application.credentials.secret_key_base || ENV['SECRET_KEY_BASE']
    )
  end

  test "should get current user with valid token" do
    get api_current_user_url,
        headers: { 'Authorization' => "Bearer #{@token}" },
        as: :json

    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'test@example.com', json_response['user']['email']
    assert_equal @user.id, json_response['user']['id']
  end

  test "should return unauthorized without token" do
    get api_current_user_url, as: :json

    assert_response :unauthorized
    json_response = JSON.parse(response.body)
    assert_equal 'Unauthorized', json_response['error']
  end

  test "should return unauthorized with invalid token" do
    get api_current_user_url,
        headers: { 'Authorization' => 'Bearer invalid_token' },
        as: :json

    assert_response :unauthorized
    json_response = JSON.parse(response.body)
    assert_equal 'Unauthorized', json_response['error']
  end
end
