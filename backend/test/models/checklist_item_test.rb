require "test_helper"

class ChecklistItemTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email: 'test@example.com',
      password: 'password123',
      password_confirmation: 'password123'
    )
    @sticky = @user.stickies.create!(
      type: 'Checklist',
      title: 'テストチェックリスト',
      content: '',
      x: 0,
      y: 0,
      width: 2,
      height: 2,
      position: 1
    )
  end

  test "有効な属性で保存できること" do
    item = @sticky.checklist_items.build(
      content: 'テストアイテム',
      checked: false,
      position: 0
    )
    assert item.save, "有効な属性でChecklist itemが保存できませんでした"
  end

  test "contentなしで保存できないこと" do
    item = @sticky.checklist_items.build(
      content: nil,
      checked: false,
      position: 0
    )
    assert_not item.save, "contentなしでChecklistItemが保存できてしまいました"
    assert_includes item.errors[:content], "can't be blank"
  end

  test "stickyなしで保存できないこと" do
    item = ChecklistItem.new(
      content: 'テストアイテム',
      checked: false,
      position: 0
    )
    assert_not item.save, "stickyなしでChecklistItemが保存できてしまいました"
    assert_includes item.errors[:sticky], "must exist"
  end

  test "checkedのデフォルトがfalseであること" do
    item = @sticky.checklist_items.create!(content: 'テストアイテム', position: 0)
    assert_equal false, item.checked, "checkedのデフォルトがfalseではありません"
  end

  test "positionのデフォルトが0であること" do
    item = @sticky.checklist_items.create!(content: 'テストアイテム')
    assert_equal 0, item.position, "positionのデフォルトが0ではありません"
  end

  test "論理削除が機能すること" do
    item = @sticky.checklist_items.create!(content: 'テストアイテム', position: 0)
    item.discard
    assert item.discarded?, "アイテムが論理削除されていません"
    assert_not_nil item.discarded_at, "discarded_atが設定されていません"
  end

  test "default_scopeで削除済みが除外されること" do
    item1 = @sticky.checklist_items.create!(content: 'アイテム1', position: 0)
    item2 = @sticky.checklist_items.create!(content: 'アイテム2', position: 1)
    item1.discard

    items = @sticky.checklist_items.reload
    assert_equal 1, items.count, "削除済みアイテムが除外されていません"
    assert_equal item2.id, items.first.id, "削除されていないアイテムが取得できていません"
  end

  test "positionで昇順ソートされること" do
    item3 = @sticky.checklist_items.create!(content: 'アイテム3', position: 2)
    item1 = @sticky.checklist_items.create!(content: 'アイテム1', position: 0)
    item2 = @sticky.checklist_items.create!(content: 'アイテム2', position: 1)

    items = @sticky.checklist_items.reload
    assert_equal [item1.id, item2.id, item3.id], items.map(&:id), "positionで昇順ソートされていません"
  end

  test "toggle_checked!が機能すること" do
    item = @sticky.checklist_items.create!(content: 'テストアイテム', position: 0)

    # falseからtrueへ
    assert_equal false, item.checked
    item.toggle_checked!
    assert_equal true, item.checked

    # trueからfalseへ
    item.toggle_checked!
    assert_equal false, item.checked
  end

  test "positionが負の値の場合保存できないこと" do
    item = @sticky.checklist_items.build(
      content: 'テストアイテム',
      position: -1
    )
    assert_not item.save, "positionが負の値でも保存できてしまいました"
    assert_includes item.errors[:position], "must be greater than or equal to 0"
  end
end
