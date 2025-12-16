require "test_helper"

class Api::ChecklistItemsControllerTest < ActionDispatch::IntegrationTest
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

    @checklist = Checklist.create!(
      title: 'テストチェックリスト',
      position: 1,
      user: @user
    )

    @other_checklist = Checklist.create!(
      title: '他のユーザーのチェックリスト',
      position: 1,
      user: @other_user
    )

    @checklist_item = @checklist.checklist_items.create!(
      content: 'テストアイテム',
      position: 0,
      checked: false
    )
  end

  # 認証テスト
  test "should not create checklist item without token" do
    post api_sticky_checklist_items_url(@checklist),
         params: { checklist_item: { content: '新規アイテム', position: 1 } },
         as: :json

    assert_response :unauthorized
  end

  # Create tests
  test "should create checklist item with valid token and params" do
    assert_difference('@checklist.checklist_items.count', 1) do
      post api_sticky_checklist_items_url(@checklist),
           headers: { 'Authorization' => "Bearer #{@token}" },
           params: { checklist_item: { content: '新規アイテム', position: 1, checked: false } },
           as: :json
    end

    assert_response :created
    json_response = JSON.parse(response.body)
    assert_equal '新規アイテム', json_response['checklist_item']['content']
    assert_equal 1, json_response['checklist_item']['position']
    assert_equal false, json_response['checklist_item']['checked']
  end

  test "should not create checklist item without content" do
    assert_no_difference('@checklist.checklist_items.count') do
      post api_sticky_checklist_items_url(@checklist),
           headers: { 'Authorization' => "Bearer #{@token}" },
           params: { checklist_item: { position: 1, checked: false } },
           as: :json
    end

    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_includes json_response['errors'].join, "can't be blank"
  end

  test "should not create checklist item for other user's checklist" do
    assert_no_difference('ChecklistItem.count') do
      post api_sticky_checklist_items_url(@other_checklist),
           headers: { 'Authorization' => "Bearer #{@token}" },
           params: { checklist_item: { content: '不正なアイテム', position: 1 } },
           as: :json
    end

    assert_response :not_found
  end

  # Update tests
  test "should update checklist item checked status" do
    patch api_sticky_checklist_item_url(@checklist, @checklist_item),
          headers: { 'Authorization' => "Bearer #{@token}" },
          params: { checklist_item: { checked: true } },
          as: :json

    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal true, json_response['checklist_item']['checked']
    @checklist_item.reload
    assert_equal true, @checklist_item.checked
  end

  test "should update checklist item content" do
    patch api_sticky_checklist_item_url(@checklist, @checklist_item),
          headers: { 'Authorization' => "Bearer #{@token}" },
          params: { checklist_item: { content: '更新されたアイテム' } },
          as: :json

    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal '更新されたアイテム', json_response['checklist_item']['content']
    @checklist_item.reload
    assert_equal '更新されたアイテム', @checklist_item.content
  end

  test "should update checklist item position" do
    patch api_sticky_checklist_item_url(@checklist, @checklist_item),
          headers: { 'Authorization' => "Bearer #{@token}" },
          params: { checklist_item: { position: 5 } },
          as: :json

    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 5, json_response['checklist_item']['position']
    @checklist_item.reload
    assert_equal 5, @checklist_item.position
  end

  test "should not update checklist item with invalid content" do
    patch api_sticky_checklist_item_url(@checklist, @checklist_item),
          headers: { 'Authorization' => "Bearer #{@token}" },
          params: { checklist_item: { content: '' } },
          as: :json

    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_includes json_response['errors'].join, "can't be blank"
  end

  test "should not update other user's checklist item" do
    other_item = @other_checklist.checklist_items.create!(
      content: '他のユーザーのアイテム',
      position: 0
    )

    patch api_sticky_checklist_item_url(@other_checklist, other_item),
          headers: { 'Authorization' => "Bearer #{@token}" },
          params: { checklist_item: { content: '不正な更新' } },
          as: :json

    assert_response :not_found
  end

  # Destroy tests
  test "should destroy checklist item (soft delete)" do
    assert_no_difference('ChecklistItem.unscoped.count') do
      delete api_sticky_checklist_item_url(@checklist, @checklist_item),
             headers: { 'Authorization' => "Bearer #{@token}" },
             as: :json
    end

    assert_response :no_content
    @checklist_item.reload
    assert @checklist_item.discarded?
    assert_not_nil @checklist_item.discarded_at
  end

  test "should not destroy other user's checklist item" do
    other_item = @other_checklist.checklist_items.create!(
      content: '他のユーザーのアイテム',
      position: 0
    )

    delete api_sticky_checklist_item_url(@other_checklist, other_item),
           headers: { 'Authorization' => "Bearer #{@token}" },
           as: :json

    assert_response :not_found
    other_item.reload
    assert_not other_item.discarded?
  end

  test "should not find checklist item that doesn't exist" do
    patch api_sticky_checklist_item_url(@checklist, id: 99999),
          headers: { 'Authorization' => "Bearer #{@token}" },
          params: { checklist_item: { content: 'テスト' } },
          as: :json

    assert_response :not_found
  end

  # Reorder tests
  test "should reorder checklist items" do
    item1 = @checklist.checklist_items.create!(content: 'アイテム1', position: 0)
    item2 = @checklist.checklist_items.create!(content: 'アイテム2', position: 1)
    item3 = @checklist.checklist_items.create!(content: 'アイテム3', position: 2)

    patch reorder_api_sticky_checklist_items_url(@checklist),
          headers: { 'Authorization' => "Bearer #{@token}" },
          params: {
            checklist_items: [
              { id: item3.id, position: 0 },
              { id: item1.id, position: 1 },
              { id: item2.id, position: 2 }
            ]
          },
          as: :json

    assert_response :ok

    item1.reload
    item2.reload
    item3.reload

    assert_equal 1, item1.position
    assert_equal 2, item2.position
    assert_equal 0, item3.position
  end

  test "should not reorder checklist items without token" do
    patch reorder_api_sticky_checklist_items_url(@checklist),
          params: { checklist_items: [] },
          as: :json

    assert_response :unauthorized
  end

  test "should not reorder other user's checklist items" do
    patch reorder_api_sticky_checklist_items_url(@other_checklist),
          headers: { 'Authorization' => "Bearer #{@token}" },
          params: { checklist_items: [] },
          as: :json

    assert_response :not_found
  end

  test "should not reorder with invalid item ids" do
    patch reorder_api_sticky_checklist_items_url(@checklist),
          headers: { 'Authorization' => "Bearer #{@token}" },
          params: {
            checklist_items: [
              { id: 99999, position: 0 }
            ]
          },
          as: :json

    assert_response :unprocessable_entity
  end

  test "should not reorder with invalid position" do
    item1 = @checklist.checklist_items.create!(content: 'アイテム1', position: 0)

    patch reorder_api_sticky_checklist_items_url(@checklist),
          headers: { 'Authorization' => "Bearer #{@token}" },
          params: {
            checklist_items: [
              { id: item1.id, position: -1 }
            ]
          },
          as: :json

    assert_response :unprocessable_entity
  end
end
