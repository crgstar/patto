# GitHub Actions 強化ガイド

今後実装を検討するGitHub Actions機能の詳細ガイドです。

## 📚 目次

1. [コードカバレッジ](#1-コードカバレッジ)
2. [RuboCop（コード品質）](#2-rubocopコード品質)
3. [Lighthouse CI（パフォーマンス計測）](#3-lighthouse-ciパフォーマンス計測)
4. [PR自動ラベル付け](#4-pr自動ラベル付け)
5. [Bundle Size Analysis](#5-bundle-size-analysis)
6. [Visual Regression Testing](#6-visual-regression-testing)

---

## 1. コードカバレッジ

### 目的
- テストカバレッジの可視化
- PR毎にカバレッジの変化を確認
- 未テスト部分の把握

### 実装方法

#### フロントエンド（Vitest + Coveralls）

**1. Coverallsアカウント設定**
1. [Coveralls.io](https://coveralls.io/) にGitHubアカウントでログイン
2. リポジトリを追加
3. リポジトリトークンを取得（公開リポジトリは不要）

**2. GitHub Secretsに追加（プライベートリポジトリのみ）**
- `COVERALLS_REPO_TOKEN`: Coverallsのリポジトリトークン

**3. `.github/workflows/deploy-frontend.yml` 修正**

`test` ジョブに以下を追加：

```yaml
test:
  name: Run Frontend Tests
  runs-on: ubuntu-latest

  steps:
    - name: Checkout repository
      uses: actions/checkout@v4

    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: ${{ env.NODE_VERSION }}
        cache: 'npm'
        cache-dependency-path: frontend/package-lock.json

    - name: Install dependencies
      working-directory: ./frontend
      run: npm ci

    # 通常のテスト実行をカバレッジ付きに変更
    - name: Run tests with coverage
      working-directory: ./frontend
      run: npm run test:coverage

    # Coverallsにアップロード
    - name: Upload coverage to Coveralls
      uses: coverallsapp/github-action@v2
      with:
        github-token: ${{ secrets.GITHUB_TOKEN }}
        path-to-lcov: ./frontend/coverage/lcov.info
        base-path: frontend
        flag-name: frontend
```

**4. vitest.config.js でカバレッジ設定確認**

`frontend/vitest.config.js` に以下が含まれていることを確認：

```javascript
export default defineConfig({
  test: {
    coverage: {
      provider: 'v8',
      reporter: ['text', 'lcov', 'html'],
      exclude: [
        'node_modules/',
        'dist/',
        'tests/',
        '**/*.spec.js',
        '**/*.test.js',
      ],
    },
  },
});
```

**5. 必要なパッケージインストール**

```bash
cd frontend
npm install --save-dev @vitest/coverage-v8
```

#### バックエンド（SimpleCov + Coveralls）

**1. Gemfile に追加**

```ruby
group :test do
  gem 'simplecov', require: false
  gem 'simplecov-lcov', require: false
end
```

**2. test/test_helper.rb に追加**

ファイルの**最初**に以下を追加：

```ruby
require 'simplecov'
require 'simplecov-lcov'

SimpleCov::Formatter::LcovFormatter.config.report_with_single_file = true
SimpleCov.formatters = SimpleCov::Formatter::MultiFormatter.new([
  SimpleCov::Formatter::HTMLFormatter,
  SimpleCov::Formatter::LcovFormatter
])

SimpleCov.start 'rails' do
  add_filter '/test/'
  add_filter '/config/'
  add_filter '/vendor/'

  add_group 'Models', 'app/models'
  add_group 'Controllers', 'app/controllers'
  add_group 'Mailers', 'app/mailers'
  add_group 'Jobs', 'app/jobs'
end
```

**3. `.github/workflows/deploy-backend.yml` 修正**

`test` ジョブに以下を追加：

```yaml
- name: Upload coverage to Coveralls
  uses: coverallsapp/github-action@v2
  with:
    github-token: ${{ secrets.GITHUB_TOKEN }}
    path-to-lcov: ./backend/coverage/lcov/patto.lcov
    base-path: backend
    flag-name: backend
```

**4. .gitignore に追加**

```
# Coverage
coverage/
```

### 期待される効果
- PRレビュー時にカバレッジの変化が一目で分かる
- カバレッジ目標（例：80%以上）の設定と追跡
- テストが不足している箇所の特定

---

## 2. RuboCop（コード品質）

### 目的
- Rubyコードの静的解析
- コードスタイルの統一
- 潜在的なバグの早期発見

### 実装方法

**1. Gemfile に追加**

```ruby
group :development, :test do
  gem 'rubocop', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-performance', require: false
end
```

**2. .rubocop.yml 作成**

`backend/.rubocop.yml`:

```yaml
require:
  - rubocop-rails
  - rubocop-performance

AllCops:
  NewCops: enable
  TargetRubyVersion: 3.2
  Exclude:
    - 'bin/**/*'
    - 'db/schema.rb'
    - 'db/migrate/**/*'
    - 'node_modules/**/*'
    - 'vendor/**/*'
    - 'tmp/**/*'

# 日本語コメントを許可
Style/AsciiComments:
  Enabled: false

# ドキュメントコメント必須を無効化
Style/Documentation:
  Enabled: false

# メソッド長の制限を緩和
Metrics/MethodLength:
  Max: 20

# クラス長の制限を緩和
Metrics/ClassLength:
  Max: 150

# ブロック長の制限を緩和
Metrics/BlockLength:
  Exclude:
    - 'config/**/*'
    - 'spec/**/*'
    - 'test/**/*'
```

**3. package.json にスクリプト追加**

`backend/package.json`（存在しない場合は作成）または `Rakefile`:

```ruby
# Rakefile に追加
task :rubocop do
  sh 'bundle exec rubocop'
end

task :rubocop_auto_correct do
  sh 'bundle exec rubocop -A'
end
```

**4. GitHub Actions ワークフロー作成**

`.github/workflows/backend-lint.yml`:

```yaml
name: Backend Lint (RuboCop)

on:
  push:
    branches:
      - main
    paths:
      - 'backend/**/*.rb'
      - 'backend/.rubocop.yml'
      - '.github/workflows/backend-lint.yml'
  pull_request:
    branches:
      - main
    paths:
      - 'backend/**/*.rb'
      - 'backend/.rubocop.yml'
      - '.github/workflows/backend-lint.yml'

env:
  RUBY_VERSION: '3.2.0'

jobs:
  rubocop:
    name: RuboCop
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: ${{ env.RUBY_VERSION }}
          bundler-cache: true
          working-directory: backend

      - name: Run RuboCop
        working-directory: ./backend
        run: bundle exec rubocop --format github
```

**5. 初回セットアップ**

```bash
cd backend
bundle install
bundle exec rubocop --auto-gen-config  # 現在のコードベースに合わせた設定を生成
```

### 期待される効果
- コードスタイルの自動チェック
- PRレビュー時の指摘事項削減
- コード品質の向上

---

## 3. Lighthouse CI（パフォーマンス計測）

### 目的
- フロントエンドのパフォーマンス計測
- SEO、アクセシビリティのスコア計測
- PRごとのパフォーマンス変化追跡

### 実装方法

**1. 必要なパッケージインストール**

```bash
cd frontend
npm install --save-dev @lhci/cli
```

**2. lighthouserc.js 設定ファイル作成**

`frontend/lighthouserc.js`:

```javascript
module.exports = {
  ci: {
    collect: {
      startServerCommand: 'npm run preview',
      startServerReadyPattern: 'Local:',
      url: ['http://localhost:4173'],
      numberOfRuns: 3,
    },
    assert: {
      preset: 'lighthouse:recommended',
      assertions: {
        'categories:performance': ['error', { minScore: 0.8 }],
        'categories:accessibility': ['error', { minScore: 0.9 }],
        'categories:best-practices': ['error', { minScore: 0.9 }],
        'categories:seo': ['error', { minScore: 0.9 }],
      },
    },
    upload: {
      target: 'temporary-public-storage',
    },
  },
};
```

**3. package.json にスクリプト追加**

```json
{
  "scripts": {
    "lhci": "lhci autorun"
  }
}
```

**4. GitHub Actions ワークフロー作成**

`.github/workflows/lighthouse.yml`:

```yaml
name: Lighthouse CI

on:
  pull_request:
    branches:
      - main
    paths:
      - 'frontend/**'

env:
  NODE_VERSION: '20'

jobs:
  lighthouse:
    name: Lighthouse Performance Check
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'
          cache-dependency-path: frontend/package-lock.json

      - name: Install dependencies
        working-directory: ./frontend
        run: npm ci

      - name: Build
        working-directory: ./frontend
        run: npm run build

      - name: Run Lighthouse CI
        working-directory: ./frontend
        run: npm run lhci

      - name: Comment PR with Lighthouse results
        uses: actions/github-script@v7
        if: github.event_name == 'pull_request'
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
          script: |
            // Lighthouse結果のコメント投稿ロジック
            // 実装は省略（lighthouserc.jsのupload設定でURLが取得できる）
```

### 期待される効果
- パフォーマンス劣化の早期検出
- アクセシビリティ問題の発見
- SEOスコアの維持

---

## 4. PR自動ラベル付け

### 目的
- PRの種類に応じた自動ラベル付け
- PR管理の効率化
- フィルタリングの容易化

### 実装方法

**1. .github/labeler.yml 作成**

```yaml
# フロントエンド
frontend:
  - changed-files:
    - any-glob-to-any-file: 'frontend/**/*'

# バックエンド
backend:
  - changed-files:
    - any-glob-to-any-file: 'backend/**/*'

# ドキュメント
documentation:
  - changed-files:
    - any-glob-to-any-file: 'docs/**/*'
    - any-glob-to-any-file: '**/*.md'

# GitHub Actions
github-actions:
  - changed-files:
    - any-glob-to-any-file: '.github/**/*'

# 依存関係
dependencies:
  - changed-files:
    - any-glob-to-any-file: '**/package.json'
    - any-glob-to-any-file: '**/package-lock.json'
    - any-glob-to-any-file: '**/Gemfile'
    - any-glob-to-any-file: '**/Gemfile.lock'

# テスト
test:
  - changed-files:
    - any-glob-to-any-file: '**/*.test.js'
    - any-glob-to-any-file: '**/*.spec.js'
    - any-glob-to-any-file: 'backend/test/**/*'

# 設定ファイル
config:
  - changed-files:
    - any-glob-to-any-file: '**/*.config.js'
    - any-glob-to-any-file: '**/*.config.ts'
    - any-glob-to-any-file: 'backend/config/**/*'
```

**2. GitHub Actions ワークフロー作成**

`.github/workflows/labeler.yml`:

```yaml
name: PR Labeler

on:
  pull_request:
    types: [opened, synchronize, reopened]

permissions:
  contents: read
  pull-requests: write

jobs:
  label:
    name: Auto Label PR
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Run Labeler
        uses: actions/labeler@v5
        with:
          repo-token: ${{ secrets.GITHUB_TOKEN }}
          configuration-path: .github/labeler.yml
```

**3. GitHubリポジトリでラベル作成**

Settings > Labels で以下のラベルを作成：
- `frontend` (色: #61dafb)
- `backend` (色: #cc0000)
- `documentation` (色: #0075ca)
- `github-actions` (色: #2088ff)
- `dependencies` (色: #0366d6)
- `test` (色: #d4c5f9)
- `config` (色: #ededed)

### 期待される効果
- PR分類の自動化
- レビュー担当者の割り当て容易化
- 変更範囲の可視化

---

## 5. Bundle Size Analysis

### 目的
- JavaScriptバンドルサイズの変化追跡
- PRごとのサイズ増加を可視化
- パフォーマンス劣化の防止

### 実装方法

**1. 必要なパッケージインストール**

```bash
cd frontend
npm install --save-dev @bundle-analyzer/rollup-plugin
```

**2. vite.config.js に設定追加**

```javascript
import { defineConfig } from 'vite';
import vue from '@vitejs/plugin-vue';
import path from 'path';
import { analyzer } from '@bundle-analyzer/rollup-plugin';

export default defineConfig(({ mode }) => ({
  plugins: [
    vue(),
    // 本番ビルド時のみバンドル分析を有効化
    mode === 'production' && analyzer({
      analyzerMode: 'json',
      fileName: 'bundle-stats.json',
    }),
  ].filter(Boolean),
  // ... 他の設定
}));
```

**3. GitHub Actions ワークフロー作成**

`.github/workflows/bundle-size.yml`:

```yaml
name: Bundle Size Analysis

on:
  pull_request:
    branches:
      - main
    paths:
      - 'frontend/**'

env:
  NODE_VERSION: '20'

jobs:
  analyze:
    name: Analyze Bundle Size
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'
          cache-dependency-path: frontend/package-lock.json

      - name: Install dependencies
        working-directory: ./frontend
        run: npm ci

      - name: Build
        working-directory: ./frontend
        run: npm run build

      - name: Analyze bundle
        uses: github/webpack-bundle-size-compare-action@v1
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
          current-stats-json-path: ./frontend/dist/bundle-stats.json
          base-stats-json-path: ./frontend/dist/bundle-stats.json
```

**4. 代替案：bundlewatch を使用**

より簡単な方法として `bundlewatch` を使用：

```bash
npm install --save-dev bundlewatch
```

`package.json`:

```json
{
  "bundlewatch": {
    "files": [
      {
        "path": "./dist/assets/*.js",
        "maxSize": "500kb"
      }
    ]
  }
}
```

### 期待される効果
- バンドルサイズの肥大化防止
- 不要な依存関係の検出
- パフォーマンス維持

---

## 6. Visual Regression Testing

### 目的
- UIの視覚的変化を自動検出
- デザイン崩れの早期発見
- スクリーンショット比較による品質保証

### 実装方法

#### オプション1: Percy（推奨・簡単）

**1. Percyアカウント設定**
1. [Percy.io](https://percy.io/) でアカウント作成
2. プロジェクトを作成
3. トークンを取得

**2. GitHub Secretsに追加**
- `PERCY_TOKEN`: Percyのプロジェクトトークン

**3. 必要なパッケージインストール**

```bash
cd frontend
npm install --save-dev @percy/cli @percy/playwright
```

**4. Playwrightテストにスクリーンショット追加**

`frontend/tests/e2e/example.spec.js`:

```javascript
import { test } from '@playwright/test';
import percySnapshot from '@percy/playwright';

test('Visual regression test', async ({ page }) => {
  await page.goto('http://localhost:5173');

  // Percyスナップショット
  await percySnapshot(page, 'Homepage');

  // ログイン後
  await page.fill('[name="email"]', 'test@example.com');
  await page.fill('[name="password"]', 'password123');
  await page.click('button[type="submit"]');

  await percySnapshot(page, 'Dashboard after login');
});
```

**5. GitHub Actions ワークフロー**

`.github/workflows/visual-regression.yml`:

```yaml
name: Visual Regression Testing

on:
  pull_request:
    branches:
      - main
    paths:
      - 'frontend/**'

env:
  NODE_VERSION: '20'

jobs:
  percy:
    name: Percy Visual Tests
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'
          cache-dependency-path: frontend/package-lock.json

      - name: Install dependencies
        working-directory: ./frontend
        run: npm ci

      - name: Install Playwright browsers
        working-directory: ./frontend
        run: npx playwright install chromium

      - name: Build
        working-directory: ./frontend
        run: npm run build

      - name: Run Percy tests
        working-directory: ./frontend
        env:
          PERCY_TOKEN: ${{ secrets.PERCY_TOKEN }}
        run: npx percy exec -- npx playwright test
```

#### オプション2: Playwright Screenshot Comparison（無料・自前）

**1. Playwrightのスクリーンショット機能を使用**

`frontend/tests/e2e/visual.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

test('Homepage visual regression', async ({ page }) => {
  await page.goto('http://localhost:5173');

  // スクリーンショット比較
  await expect(page).toHaveScreenshot('homepage.png', {
    maxDiffPixels: 100,
  });
});

test('Dashboard visual regression', async ({ page }) => {
  await page.goto('http://localhost:5173');
  await page.fill('[name="email"]', 'test@example.com');
  await page.fill('[name="password"]', 'password123');
  await page.click('button[type="submit"]');

  await expect(page).toHaveScreenshot('dashboard.png', {
    maxDiffPixels: 100,
  });
});
```

**2. GitHub Actions でスクリーンショット比較**

既存の `.github/workflows/deploy-frontend.yml` に追加するか、
別ワークフローとして作成。

```yaml
- name: Run visual regression tests
  working-directory: ./frontend
  run: npx playwright test visual.spec.js

- name: Upload test results
  if: always()
  uses: actions/upload-artifact@v4
  with:
    name: visual-test-results
    path: |
      frontend/test-results/
      frontend/playwright-report/
```

**3. ベースラインスクリーンショットの管理**

初回実行時：
```bash
npx playwright test --update-snapshots
git add tests/e2e/*.png-snapshots/
git commit -m "Add baseline screenshots"
```

### 期待される効果
- デザイン崩れの自動検出
- クロスブラウザ互換性の確認
- リファクタリング時の安心感

---

## 🎯 実装優先順位の推奨

1. **コードカバレッジ** - 品質の定量化
2. **RuboCop** - コード品質の向上
3. **PR自動ラベル付け** - 運用効率化
4. **Lighthouse CI** - パフォーマンス維持
5. **Bundle Size Analysis** - パフォーマンス最適化
6. **Visual Regression Testing** - UI品質保証

---

## 📝 実装時の注意点

### 共通
- GitHub Actionsの実行時間制限に注意（無料枠: 2,000分/月）
- 各ワークフローは独立して実行できるように設計
- 失敗時の通知設定を検討

### セキュリティ
- シークレット情報は必ずGitHub Secretsを使用
- 外部サービスのトークンは最小権限で設定
- Dependabotの自動マージは慎重に設定

### パフォーマンス
- 並列実行を活用してCI時間を短縮
- キャッシュを積極的に活用
- 不要なワークフローは無効化

---

## 🔗 参考リンク

- [GitHub Actions ドキュメント](https://docs.github.com/ja/actions)
- [Coveralls](https://coveralls.io/)
- [RuboCop](https://rubocop.org/)
- [Lighthouse CI](https://github.com/GoogleChrome/lighthouse-ci)
- [Percy.io](https://percy.io/)
- [Playwright](https://playwright.dev/)
