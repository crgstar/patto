require "test_helper"

class Api::SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      email: 'test@example.com',
      password: 'password123',
      password_confirmation: 'password123'
    )
  end

  test "should login with valid credentials" do
    post api_login_url, params: {
      email: 'test@example.com',
      password: 'password123'
    }, as: :json

    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_not_nil json_response['token']
    assert_equal 'test@example.com', json_response['user']['email']
  end

  test "should not login with invalid email" do
    post api_login_url, params: {
      email: 'wrong@example.com',
      password: 'password123'
    }, as: :json

    assert_response :unauthorized
    json_response = JSON.parse(response.body)
    assert_equal 'Invalid email or password', json_response['error']
  end

  test "should not login with invalid password" do
    post api_login_url, params: {
      email: 'test@example.com',
      password: 'wrongpassword'
    }, as: :json

    assert_response :unauthorized
    json_response = JSON.parse(response.body)
    assert_equal 'Invalid email or password', json_response['error']
  end

  test "should logout successfully" do
    delete api_logout_url, as: :json

    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Logged out successfully', json_response['message']
  end
end
