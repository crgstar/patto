import { test, expect } from '@playwright/test'

test.describe('認証フロー', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/')
  })

  test('未認証ユーザーはログインページにリダイレクトされる', async ({ page }) => {
    await expect(page).toHaveURL('/login')
    await expect(page.getByRole('heading', { name: 'ログイン' })).toBeVisible()
  })

  test('ログインページが正しく表示される', async ({ page }) => {
    await page.goto('/login')

    await expect(page.getByRole('heading', { name: 'ログイン' })).toBeVisible()
    await expect(page.getByText('メールアドレスとパスワードを入力してください')).toBeVisible()
    await expect(page.getByLabel('メールアドレス')).toBeVisible()
    await expect(page.getByLabel('パスワード')).toBeVisible()
    await expect(page.getByRole('button', { name: 'ログイン' })).toBeVisible()
    await expect(page.getByText('アカウントをお持ちでない方は')).toBeVisible()
  })

  test('サインアップページが正しく表示される', async ({ page }) => {
    await page.goto('/signup')

    await expect(page.getByRole('heading', { name: 'サインアップ' })).toBeVisible()
    await expect(page.getByText('アカウントを作成してください')).toBeVisible()
    await expect(page.getByLabel('メールアドレス')).toBeVisible()
    await expect(page.getByLabel('パスワード', { exact: true })).toBeVisible()
    await expect(page.getByLabel('パスワード確認')).toBeVisible()
    await expect(page.getByRole('button', { name: 'サインアップ' })).toBeVisible()
    await expect(page.getByText('すでにアカウントをお持ちの方は')).toBeVisible()
  })

  test('サインアップページからログインページへ遷移できる', async ({ page }) => {
    await page.goto('/signup')
    await page.getByRole('link', { name: 'ログイン' }).click()
    await expect(page).toHaveURL('/login')
  })

  test('ログインページからサインアップページへ遷移できる', async ({ page }) => {
    await page.goto('/login')
    await page.getByRole('link', { name: 'サインアップ' }).click()
    await expect(page).toHaveURL('/signup')
  })

  test('サインアップとログインフロー', async ({ page }) => {
    const testEmail = `test-${Date.now()}@example.com`
    const testPassword = 'password123'

    // サインアップ
    await page.goto('/signup')
    await page.getByLabel('メールアドレス').fill(testEmail)
    await page.getByLabel('パスワード', { exact: true }).fill(testPassword)
    await page.getByLabel('パスワード確認').fill(testPassword)
    await page.getByRole('button', { name: 'サインアップ' }).click()

    // ダッシュボードにリダイレクトされる
    await expect(page).toHaveURL('/')
    await expect(page.getByRole('heading', { name: 'ダッシュボード' })).toBeVisible()
    await expect(page.getByText(testEmail)).toBeVisible()

    // ログアウト
    await page.getByRole('button', { name: 'ログアウト' }).click()
    await expect(page).toHaveURL('/login')

    // ログイン
    await page.getByLabel('メールアドレス').fill(testEmail)
    await page.getByLabel('パスワード').fill(testPassword)
    await page.getByRole('button', { name: 'ログイン' }).click()

    // ダッシュボードに戻る
    await expect(page).toHaveURL('/')
    await expect(page.getByRole('heading', { name: 'ダッシュボード' })).toBeVisible()
    await expect(page.getByText(testEmail)).toBeVisible()
  })

  test('不正なメールアドレスでログインに失敗する', async ({ page }) => {
    await page.goto('/login')

    await page.getByLabel('メールアドレス').fill('nonexistent@example.com')
    await page.getByLabel('パスワード').fill('wrongpassword')
    await page.getByRole('button', { name: 'ログイン' }).click()

    // エラーメッセージが表示される
    await expect(page.getByText(/ログインに失敗しました|Invalid credentials/i)).toBeVisible()
  })
})
