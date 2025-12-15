require "test_helper"

class ChecklistTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email: 'test@example.com',
      password: 'password123',
      password_confirmation: 'password123'
    )
  end

  test "type: 'Checklist'で保存できること" do
    checklist = @user.stickies.build(
      type: 'Checklist',
      title: 'テストチェックリスト',
      content: '',
      x: 0,
      y: 0,
      width: 2,
      height: 2,
      position: 1
    )
    assert checklist.save, "Checklistが保存できませんでした"
    assert_equal 'Checklist', checklist.type
  end

  test "Stickyの機能を継承していること - 座標" do
    checklist = Checklist.create!(
      title: 'テストチェックリスト',
      x: 5,
      y: 10,
      width: 3,
      height: 4,
      position: 1,
      user: @user
    )
    assert_equal 5, checklist.x
    assert_equal 10, checklist.y
    assert_equal 3, checklist.width
    assert_equal 4, checklist.height
  end

  test "Stickyの機能を継承していること - 論理削除" do
    checklist = Checklist.create!(
      title: 'テストチェックリスト',
      position: 1,
      user: @user
    )
    checklist.discard
    assert checklist.discarded?, "Checklistが論理削除されていません"
    assert_not_nil checklist.discarded_at
  end

  test "checklist_itemsの関連が機能すること" do
    checklist = Checklist.create!(
      title: 'テストチェックリスト',
      position: 1,
      user: @user
    )

    item1 = checklist.checklist_items.create!(content: 'アイテム1', position: 0)
    item2 = checklist.checklist_items.create!(content: 'アイテム2', position: 1)

    assert_equal 2, checklist.checklist_items.count
    assert_includes checklist.checklist_items, item1
    assert_includes checklist.checklist_items, item2
  end

  test "checklist_itemsがpositionで順序付けられること" do
    checklist = Checklist.create!(
      title: 'テストチェックリスト',
      position: 1,
      user: @user
    )

    item3 = checklist.checklist_items.create!(content: 'アイテム3', position: 2)
    item1 = checklist.checklist_items.create!(content: 'アイテム1', position: 0)
    item2 = checklist.checklist_items.create!(content: 'アイテム2', position: 1)

    items = checklist.checklist_items.reload
    assert_equal [item1.id, item2.id, item3.id], items.map(&:id)
  end

  test "completed_countが正しく動作すること" do
    checklist = Checklist.create!(
      title: 'テストチェックリスト',
      position: 1,
      user: @user
    )

    item1 = checklist.checklist_items.create!(content: 'アイテム1', position: 0, checked: true)
    item2 = checklist.checklist_items.create!(content: 'アイテム2', position: 1, checked: false)
    item3 = checklist.checklist_items.create!(content: 'アイテム3', position: 2, checked: true)

    assert_equal 2, checklist.completed_count
  end

  test "total_countが正しく動作すること" do
    checklist = Checklist.create!(
      title: 'テストチェックリスト',
      position: 1,
      user: @user
    )

    checklist.checklist_items.create!(content: 'アイテム1', position: 0)
    checklist.checklist_items.create!(content: 'アイテム2', position: 1)
    checklist.checklist_items.create!(content: 'アイテム3', position: 2)

    assert_equal 3, checklist.total_count
  end

  test "completion_percentageが正しく動作すること - アイテムがある場合" do
    checklist = Checklist.create!(
      title: 'テストチェックリスト',
      position: 1,
      user: @user
    )

    checklist.checklist_items.create!(content: 'アイテム1', position: 0, checked: true)
    checklist.checklist_items.create!(content: 'アイテム2', position: 1, checked: false)
    checklist.checklist_items.create!(content: 'アイテム3', position: 2, checked: true)
    checklist.checklist_items.create!(content: 'アイテム4', position: 3, checked: true)

    # 3/4 = 75%
    assert_equal 75, checklist.completion_percentage
  end

  test "completion_percentageが正しく動作すること - アイテムがない場合" do
    checklist = Checklist.create!(
      title: 'テストチェックリスト',
      position: 1,
      user: @user
    )

    assert_equal 0, checklist.completion_percentage
  end

  test "Checklistが削除されるとchecklist_itemsも削除されること" do
    checklist = Checklist.create!(
      title: 'テストチェックリスト',
      position: 1,
      user: @user
    )

    item1 = checklist.checklist_items.create!(content: 'アイテム1', position: 0)
    item2 = checklist.checklist_items.create!(content: 'アイテム2', position: 1)

    checklist.discard

    # 論理削除されているので、default_scopeでは取得できない
    assert_equal 0, ChecklistItem.where(id: [item1.id, item2.id]).count
    # unscopedで確認すると論理削除されている
    assert_equal 2, ChecklistItem.unscoped.where(id: [item1.id, item2.id]).discarded.count
  end
end
