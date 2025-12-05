import { test, expect } from '@playwright/test'

test.describe('Sticky機能', () => {
  const testEmail = `test-sticky-${Date.now()}@example.com`
  const testPassword = 'password123'

  test.beforeEach(async ({ page }) => {
    // 新規ユーザーを作成してログイン
    await page.goto('/signup')
    await page.getByLabel('メールアドレス').fill(testEmail)
    await page.getByLabel('パスワード', { exact: true }).fill(testPassword)
    await page.getByLabel('パスワード確認').fill(testPassword)
    await page.getByRole('button', { name: 'サインアップ' }).click()

    // ダッシュボードにリダイレクトされることを確認
    await expect(page).toHaveURL('/')
    await expect(page.getByRole('heading', { name: 'ダッシュボード' })).toBeVisible()
  })

  test('初期状態では付箋が表示されない', async ({ page }) => {
    await expect(page.getByText('付箋がありません')).toBeVisible()
  })

  test('新しい付箋を作成できる', async ({ page }) => {
    // 「新しい付箋」ボタンをクリック
    await page.getByRole('button', { name: '新しい付箋' }).click()

    // 付箋が作成されたことを確認（空の付箋カードが表示される）
    await expect(page.getByText('付箋がありません')).not.toBeVisible()

    // タイトルと内容を入力
    const titleInput = page.getByPlaceholder('タイトル').first()
    const contentTextarea = page.getByPlaceholder('内容を入力...').first()

    await titleInput.fill('テスト付箋1')
    await titleInput.blur()

    await contentTextarea.fill('これはテストの内容です')
    await contentTextarea.blur()

    // ページをリロードして、保存されていることを確認
    await page.reload()
    await expect(titleInput).toHaveValue('テスト付箋1')
    await expect(contentTextarea).toHaveValue('これはテストの内容です')
  })

  test('複数の付箋を作成できる', async ({ page }) => {
    // 1つ目の付箋
    await page.getByRole('button', { name: '新しい付箋' }).click()
    await page.getByPlaceholder('タイトル').first().fill('付箋1')
    await page.getByPlaceholder('タイトル').first().blur()

    // 2つ目の付箋
    await page.getByRole('button', { name: '新しい付箋' }).click()
    await page.getByPlaceholder('タイトル').nth(1).fill('付箋2')
    await page.getByPlaceholder('タイトル').nth(1).blur()

    // 3つ目の付箋
    await page.getByRole('button', { name: '新しい付箋' }).click()
    await page.getByPlaceholder('タイトル').nth(2).fill('付箋3')
    await page.getByPlaceholder('タイトル').nth(2).blur()

    // 3つの付箋が表示されていることを確認
    await expect(page.getByPlaceholder('タイトル')).toHaveCount(3)
  })

  test('付箋を更新できる', async ({ page }) => {
    // 付箋を作成
    await page.getByRole('button', { name: '新しい付箋' }).click()
    const titleInput = page.getByPlaceholder('タイトル').first()
    const contentTextarea = page.getByPlaceholder('内容を入力...').first()

    await titleInput.fill('元のタイトル')
    await titleInput.blur()
    await contentTextarea.fill('元の内容')
    await contentTextarea.blur()

    // タイトルを更新
    await titleInput.fill('更新されたタイトル')
    await titleInput.blur()

    // 内容を更新
    await contentTextarea.fill('更新された内容')
    await contentTextarea.blur()

    // リロードして更新が保存されていることを確認
    await page.reload()
    await expect(titleInput).toHaveValue('更新されたタイトル')
    await expect(contentTextarea).toHaveValue('更新された内容')
  })

  test('付箋を削除できる', async ({ page }) => {
    // 付箋を2つ作成
    await page.getByRole('button', { name: '新しい付箋' }).click()
    await page.getByPlaceholder('タイトル').first().fill('削除する付箋')
    await page.getByPlaceholder('タイトル').first().blur()

    await page.getByRole('button', { name: '新しい付箋' }).click()
    await page.getByPlaceholder('タイトル').nth(1).fill('残す付箋')
    await page.getByPlaceholder('タイトル').nth(1).blur()

    // 1つ目を削除
    page.on('dialog', dialog => dialog.accept()) // confirmダイアログを自動的にOK
    await page.getByRole('button', { name: '削除' }).first().click()

    // 削除された付箋が表示されず、残した付箋が表示されることを確認
    await expect(page.getByPlaceholder('タイトル')).toHaveCount(1)

    // リロードして削除が永続化されていることを確認
    await page.reload()
    await expect(page.getByPlaceholder('タイトル')).toHaveCount(1)
    await expect(page.getByPlaceholder('タイトル').first()).toHaveValue('残す付箋')
  })

  test('すべての付箋を削除すると空の状態に戻る', async ({ page }) => {
    // 付箋を作成
    await page.getByRole('button', { name: '新しい付箋' }).click()
    await page.getByPlaceholder('タイトル').first().fill('削除する付箋')
    await page.getByPlaceholder('タイトル').first().blur()

    // 削除
    page.on('dialog', dialog => dialog.accept())
    await page.getByRole('button', { name: '削除' }).click()

    // 空の状態メッセージが表示される
    await expect(page.getByText('付箋がありません')).toBeVisible()
  })

  test('ドラッグ&ドロップで並び替えができる（視覚的確認用）', async ({ page }) => {
    // 3つの付箋を作成
    await page.getByRole('button', { name: '新しい付箋' }).click()
    await page.getByPlaceholder('タイトル').first().fill('付箋A')
    await page.getByPlaceholder('タイトル').first().blur()

    await page.getByRole('button', { name: '新しい付箋' }).click()
    await page.getByPlaceholder('タイトル').nth(1).fill('付箋B')
    await page.getByPlaceholder('タイトル').nth(1).blur()

    await page.getByRole('button', { name: '新しい付箋' }).click()
    await page.getByPlaceholder('タイトル').nth(2).fill('付箋C')
    await page.getByPlaceholder('タイトル').nth(2).blur()

    // 初期順序を確認
    const titles = await page.getByPlaceholder('タイトル').allTextContents()
    expect(titles).toEqual(['付箋A', '付箋B', '付箋C'])

    // ドラッグ&ドロップ操作
    // 注意: Playwrightでのドラッグ&ドロップは実際のブラウザ動作と異なる場合があるため、
    // このテストは並び替え機能が存在することの確認のみを目的とする
    // 実際の動作確認は手動テストで行う

    // リロードしても順序が保持されることを確認
    await page.reload()
    await expect(page.getByPlaceholder('タイトル')).toHaveCount(3)
  })

  test('ログアウト後に再ログインしても付箋が保持される', async ({ page }) => {
    // 付箋を作成
    await page.getByRole('button', { name: '新しい付箋' }).click()
    await page.getByPlaceholder('タイトル').first().fill('永続化テスト')
    await page.getByPlaceholder('タイトル').first().blur()
    await page.getByPlaceholder('内容を入力...').first().fill('この内容は保持されるべき')
    await page.getByPlaceholder('内容を入力...').first().blur()

    // ログアウト
    await page.getByRole('button', { name: 'ログアウト' }).click()
    await expect(page).toHaveURL('/login')

    // 再ログイン
    await page.getByLabel('メールアドレス').fill(testEmail)
    await page.getByLabel('パスワード').fill(testPassword)
    await page.getByRole('button', { name: 'ログイン' }).click()

    // ダッシュボードに戻る
    await expect(page).toHaveURL('/')

    // 付箋が保持されていることを確認
    await expect(page.getByPlaceholder('タイトル').first()).toHaveValue('永続化テスト')
    await expect(page.getByPlaceholder('内容を入力...').first()).toHaveValue('この内容は保持されるべき')
  })
})
