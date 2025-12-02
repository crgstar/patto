# Patto

Vue.js + Rails APIで構築されたダッシュボードアプリケーション

## 技術スタック

### バックエンド
- Ruby 3.2.0
- Rails 8.1.1 (APIモード)
- MySQL 8.0

### フロントエンド
- Vue.js 3
- Vite
- Tailwind CSS v3

### テスト
- Playwright (E2Eテスト)
- Vitest (単体テスト)
- minitest (Rails)

## セットアップ

### 必要な環境
- Ruby 3.2.0
- Node.js 22.x
- Docker & Docker Compose
- MySQL 8.0 (Dockerで起動)

### 初回セットアップ

1. リポジトリをクローン

2. バックエンドの依存関係をインストール
```bash
cd backend
bundle install
```

3. フロントエンドの依存関係をインストール
```bash
cd ../frontend
npm install
```

## 起動方法

プロジェクトルートで以下のコマンドを実行：

```bash
./start.sh
```

### アクセスURL
- **フロントエンド**: http://localhost:5173
- **バックエンドAPI**: http://localhost:3000
- **MySQL**: localhost:3306

## 停止方法

```bash
./stop.sh
```

## データベース

### データベースの作成
```bash
cd backend
bundle exec rails db:create
```

### マイグレーション実行
```bash
bundle exec rails db:migrate
```

### シードデータ投入
```bash
bundle exec rails db:seed
```

## テスト実行

### バックエンドテスト
```bash
cd backend
bundle exec rails test
```

### フロントエンドテスト

単体テスト:
```bash
cd frontend
npm run test
```

E2Eテスト:
```bash
npm run test:e2e
```

## プロジェクト構成

```
/home/dev/projects/patto/
├── backend/          # Railsアプリケーション
│   ├── app/
│   ├── config/
│   ├── db/
│   └── ...
├── frontend/         # Vue.jsアプリケーション
│   ├── src/
│   ├── public/
│   └── ...
├── logs/            # アプリケーションログ
├── docker-compose.yml
├── start.sh         # 起動スクリプト
├── stop.sh          # 停止スクリプト
└── README.md
```
