# Patto

Vue.js + Rails APIで構築されたダッシュボードアプリケーション

## 技術スタック

### バックエンド
- Ruby 3.2.0
- Rails 8.1.1 (APIモード)
- MySQL 8.0
- JWT認証

### フロントエンド
- Vue.js 3
- Vite
- Tailwind CSS v3
- Pinia (状態管理)
- Vue Router 4
- Axios

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
```bash
cd /home/dev/projects/patto
```

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

このスクリプトは以下を自動的に実行します：
- MySQLコンテナの起動
- Railsサーバーの起動（ポート3000）
- Viteサーバーの起動（ポート5173）

### アクセスURL
- **フロントエンド**: http://localhost:5173
- **バックエンドAPI**: http://localhost:3000
- **MySQL**: localhost:3306

## 停止方法

```bash
./stop.sh
```

MySQLコンテナを停止するかどうか選択できます。

## 手動起動

個別にサービスを起動する場合：

### MySQLのみ起動
```bash
docker compose up -d mysql
```

### Railsサーバーのみ起動
```bash
cd backend
bundle exec rails server -p 3000
```

### Viteサーバーのみ起動
```bash
cd frontend
npm run dev
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

## トラブルシューティング

### ポートが既に使用されている場合

使用中のプロセスを確認：
```bash
# ポート3000の確認
lsof -i :3000

# ポート5173の確認
lsof -i :5173

# ポート3306の確認
lsof -i :3306
```

プロセスを停止：
```bash
kill -9 <PID>
```

### ログの確認

アプリケーションログ：
```bash
# Railsログ
tail -f logs/rails.log

# Viteログ
tail -f logs/vite.log
```

Dockerログ：
```bash
docker compose logs -f mysql
```

## 開発進捗

詳細は `PROGRESS.md` を参照してください。
