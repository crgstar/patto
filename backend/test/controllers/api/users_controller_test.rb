require "test_helper"

class Api::UsersControllerTest < ActionDispatch::IntegrationTest
  test "should create user with valid params" do
    assert_difference('User.count', 1) do
      post api_signup_url, params: {
        user: {
          email: 'newuser@example.com',
          password: 'password123',
          password_confirmation: 'password123'
        }
      }, as: :json
    end

    assert_response :created
    json_response = JSON.parse(response.body)
    assert_not_nil json_response['token']
    assert_equal 'newuser@example.com', json_response['user']['email']
  end

  test "should not create user with invalid email" do
    assert_no_difference('User.count') do
      post api_signup_url, params: {
        user: {
          email: 'invalid-email',
          password: 'password123',
          password_confirmation: 'password123'
        }
      }, as: :json
    end

    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert json_response['errors'].present?
  end

  test "should not create user with short password" do
    assert_no_difference('User.count') do
      post api_signup_url, params: {
        user: {
          email: 'test@example.com',
          password: '12345',
          password_confirmation: '12345'
        }
      }, as: :json
    end

    assert_response :unprocessable_entity
  end

  test "should not create user with mismatched password confirmation" do
    assert_no_difference('User.count') do
      post api_signup_url, params: {
        user: {
          email: 'test@example.com',
          password: 'password123',
          password_confirmation: 'different'
        }
      }, as: :json
    end

    assert_response :unprocessable_entity
  end
end
