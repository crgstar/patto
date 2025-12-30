# Patto

https://patto.crgstar.com

Vue.js + Rails APIで構築されたダッシュボードアプリケーション

## 技術スタック
- **バックエンド**: Ruby 3.2.0, Rails 8.1.1 (APIモード), MySQL 8.0
- **フロントエンド**: Vue.js 3, Vite, Tailwind CSS
- **テスト**: Playwright, Vitest, minitest

## セットアップ

### 必要な環境
- Ruby 3.2.0 / Node.js 22.x / Docker & Docker Compose

### 初回セットアップ
```bash
# 依存関係のインストール
cd backend && bundle install
cd ../frontend && npm install

# 環境変数の設定
cp frontend/.env.example frontend/.env

# データベース作成
cd ../backend && bundle exec rails db:create db:migrate
```

## 起動・停止

```bash
./start.sh   # 起動（Docker → Rails → Vite）
./status.sh  # 状態確認
./stop.sh    # 停止
```

**アクセスURL**: フロントエンド http://localhost:5173 / API http://localhost:3000

## テスト

```bash
cd backend && bundle exec rails test      # バックエンド
cd frontend && npm run test               # フロントエンド単体テスト
cd frontend && npm run test:e2e           # E2Eテスト
```

## プロジェクト構成
```
patto/
├── backend/           # Rails API
├── frontend/          # Vue.js SPA
├── docs/              # デプロイ手順等
└── *.sh               # 起動・停止・状態確認スクリプト
```
