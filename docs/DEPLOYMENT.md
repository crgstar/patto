# Patto デプロイガイド

本番環境へのデプロイ手順を説明します。

## アーキテクチャ

```
┌───────────────────────────────────────────────────────────┐
│                      Cloudflare                            │
│  ┌─────────────────────────────────────────────────────┐  │
│  │              DNS + CDN + SSL                         │  │
│  └───────────────────────┬─────────────────────────────┘  │
└──────────────────────────┼────────────────────────────────┘
                           │
         ┌─────────────────┴─────────────────┐
         │                                   │
         ▼                                   ▼
┌─────────────────────┐           ┌─────────────────────────┐
│  Cloudflare Pages   │           │    Hetzner VPS          │
│  (Vue.js)           │           │    (Rails API + MySQL)  │
│                     │   API     │                         │
│  patto.example.com  │──────────►│  api.patto.example.com  │
│                     │           │                         │
│  無料               │           │  €4.5/月〜              │
└─────────────────────┘           └─────────────────────────┘
```

## 前提条件

- [ ] Docker Hub アカウント
- [ ] Cloudflare アカウント
- [ ] VPS（Hetzner, DigitalOcean など）
- [ ] ドメイン名
- [ ] SSH キーペア

---

## 1. VPS の初期設定

### 1.1 サーバーの準備（Hetzner の場合）

1. [Hetzner Cloud Console](https://console.hetzner.cloud/) でサーバー作成
   - **プラン**: CX22 (2 vCPU, 4GB RAM, €4.51/月)
   - **OS**: Ubuntu 24.04
   - **SSH Key**: 自分の公開鍵を登録

2. SSH で接続確認
```bash
ssh root@YOUR_SERVER_IP
```

### 1.2 Docker のインストール

サーバー上で実行：
```bash
# Docker インストール
curl -fsSL https://get.docker.com | sh

# Docker の起動確認
docker --version
```

---

## 2. Kamal の設定

### 2.1 設定ファイルの編集

`backend/config/deploy.yml` を編集：

```yaml
# 必須変更箇所
image: YOUR_DOCKERHUB_USERNAME/patto  # Docker Hub ユーザー名

servers:
  web:
    hosts:
      - YOUR_SERVER_IP  # VPS の IP アドレス

proxy:
  host: api.patto.example.com  # API のドメイン

accessories:
  mysql:
    host: YOUR_SERVER_IP  # VPS の IP アドレス

traefik:
  args:
    certificatesResolvers.letsencrypt.acme.email: your-email@example.com
```

### 2.2 シークレットの設定

```bash
cd backend

# secrets.example をコピー
cp .kamal/secrets.example .kamal/secrets

# シークレットを編集
vim .kamal/secrets
```

シークレットの内容：
```bash
# Docker Hub アクセストークン
# 取得先: https://hub.docker.com/settings/security
KAMAL_REGISTRY_PASSWORD=dckr_pat_xxxxxxxxxxxx

# Rails Master Key
# 既存の場合: cat config/master.key
# 新規の場合: rails credentials:edit で生成
RAILS_MASTER_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# データベースパスワード（安全なパスワードを生成）
# 生成コマンド: openssl rand -hex 32
BACKEND_DATABASE_PASSWORD=your_secure_password_here
MYSQL_ROOT_PASSWORD=your_secure_root_password_here
```

---

## 3. 初回デプロイ

### 3.1 Kamal セットアップ

```bash
cd backend

# Kamal インストール（ローカル）
gem install kamal

# 初回セットアップ（サーバー準備 + 初回デプロイ）
kamal setup
```

### 3.2 データベース作成

初回デプロイ後、追加のデータベースを作成：

```bash
# Rails コンソールに接続
kamal app exec --interactive 'bin/rails console'

# または MySQL に直接接続
kamal accessory exec mysql --interactive 'mysql -u root -p'
```

MySQL で追加データベースを作成：
```sql
CREATE DATABASE backend_production_cache;
CREATE DATABASE backend_production_queue;
CREATE DATABASE backend_production_cable;
GRANT ALL PRIVILEGES ON backend_production_cache.* TO 'backend'@'%';
GRANT ALL PRIVILEGES ON backend_production_queue.* TO 'backend'@'%';
GRANT ALL PRIVILEGES ON backend_production_cable.* TO 'backend'@'%';
FLUSH PRIVILEGES;
```

### 3.3 マイグレーション実行

```bash
kamal app exec 'bin/rails db:migrate'
```

---

## 4. Cloudflare Pages の設定

### 4.1 プロジェクト作成

1. [Cloudflare Dashboard](https://dash.cloudflare.com/) にログイン
2. **Pages** → **Create a project** → **Connect to Git**
3. リポジトリを選択
4. ビルド設定：
   - **Framework preset**: None
   - **Build command**: `cd frontend && npm ci && npm run build`
   - **Build output directory**: `frontend/dist`
   - **Root directory**: `/`

### 4.2 環境変数の設定

Cloudflare Pages の **Settings** → **Environment variables**:

| 変数名 | 値 |
|--------|-----|
| `VITE_API_URL` | `https://api.patto.example.com/api` |

### 4.3 カスタムドメインの設定

1. **Custom domains** → **Set up a custom domain**
2. `patto.example.com` を追加
3. Cloudflare DNS で自動設定

---

## 5. DNS の設定

Cloudflare DNS で以下を設定：

| タイプ | 名前 | 値 | Proxy |
|-------|------|-----|-------|
| A | api | YOUR_SERVER_IP | OFF (DNS only) |
| CNAME | patto | xxx.pages.dev | ON |

**注意**: API サーバーは Proxy OFF（グレーの雲）にする必要があります。Kamal の Traefik が SSL を処理するためです。

---

## 6. GitHub Actions の設定

### 6.1 リポジトリ Secrets の設定

GitHub リポジトリの **Settings** → **Secrets and variables** → **Actions**:

#### Repository Secrets
| 名前 | 説明 |
|------|------|
| `DOCKERHUB_USERNAME` | Docker Hub ユーザー名 |
| `DOCKERHUB_TOKEN` | Docker Hub アクセストークン |
| `SSH_PRIVATE_KEY` | サーバー接続用 SSH 秘密鍵 |
| `SERVER_IP` | VPS の IP アドレス |
| `RAILS_MASTER_KEY` | Rails Master Key |
| `BACKEND_DATABASE_PASSWORD` | DB パスワード |
| `MYSQL_ROOT_PASSWORD` | MySQL root パスワード |
| `CLOUDFLARE_API_TOKEN` | Cloudflare API トークン |
| `CLOUDFLARE_ACCOUNT_ID` | Cloudflare アカウント ID |

#### Repository Variables
| 名前 | 説明 |
|------|------|
| `VITE_API_URL` | 本番 API URL |

### 6.2 Cloudflare API トークンの取得

1. [Cloudflare API Tokens](https://dash.cloudflare.com/profile/api-tokens)
2. **Create Token** → **Edit Cloudflare Workers** テンプレート
3. 必要な権限を追加：
   - **Account** → **Cloudflare Pages** → **Edit**

---

## 7. 運用コマンド

### デプロイ
```bash
cd backend
kamal deploy
```

### ログ確認
```bash
kamal app logs
kamal app logs -f  # フォロー
```

### Rails コンソール
```bash
kamal app exec --interactive 'bin/rails console'
```

### ロールバック
```bash
kamal rollback
```

### MySQL 接続
```bash
kamal accessory exec mysql --interactive 'mysql -u backend -p backend_production'
```

### サービス再起動
```bash
kamal app boot       # アプリ再起動
kamal accessory reboot mysql  # MySQL 再起動
```

---

## 8. バックアップ

### MySQL バックアップ（手動）
```bash
kamal accessory exec mysql 'mysqldump -u backend -p backend_production' > backup.sql
```

### 自動バックアップ（cron）

サーバー上で cron 設定：
```bash
crontab -e
```

```cron
# 毎日 3:00 にバックアップ
0 3 * * * docker exec patto-mysql mysqldump -u backend -pYOUR_PASSWORD backend_production | gzip > /backups/mysql/$(date +\%Y\%m\%d).sql.gz
```

---

## 9. トラブルシューティング

### デプロイが失敗する
```bash
# 詳細ログを確認
kamal deploy --verbose

# Docker ビルドを確認
docker build -t test .
```

### コンテナが起動しない
```bash
# コンテナ状態を確認
kamal app containers

# Docker ログを確認（サーバー上で）
ssh root@YOUR_SERVER_IP
docker logs patto-web
```

### DB 接続エラー
```bash
# ネットワーク確認
kamal accessory exec mysql 'mysql -u backend -p -e "SELECT 1"'

# 環境変数確認
kamal app exec 'env | grep DB'
```

### SSL 証明書エラー
```bash
# Traefik ログ確認
ssh root@YOUR_SERVER_IP
docker logs traefik
```

---

## 10. コスト概算

| サービス | 月額 |
|---------|------|
| Hetzner CX22 | €4.51 |
| Cloudflare Pages | 無料 |
| Cloudflare DNS | 無料 |
| Docker Hub | 無料 |
| **合計** | **約 €5 ($5.50)** |
