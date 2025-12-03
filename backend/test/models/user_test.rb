require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "should save user with valid attributes" do
    user = User.new(
      email: 'test@example.com',
      password: 'password123',
      password_confirmation: 'password123'
    )
    assert user.save
  end

  test "should not save user without email" do
    user = User.new(password: 'password123')
    assert_not user.save
  end

  test "should not save user with invalid email format" do
    user = User.new(
      email: 'invalid-email',
      password: 'password123'
    )
    assert_not user.save
  end

  test "should not save user with duplicate email" do
    User.create!(
      email: 'test@example.com',
      password: 'password123',
      password_confirmation: 'password123'
    )

    user = User.new(
      email: 'test@example.com',
      password: 'password456'
    )
    assert_not user.save
  end

  test "should not save user with short password" do
    user = User.new(
      email: 'test@example.com',
      password: '12345'
    )
    assert_not user.save
  end

  test "should authenticate with correct password" do
    user = User.create!(
      email: 'test@example.com',
      password: 'password123',
      password_confirmation: 'password123'
    )
    assert user.authenticate('password123')
  end

  test "should not authenticate with incorrect password" do
    user = User.create!(
      email: 'test@example.com',
      password: 'password123',
      password_confirmation: 'password123'
    )
    assert_not user.authenticate('wrongpassword')
  end
end
