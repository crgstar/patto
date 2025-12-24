# Patto デプロイガイド

Cloudflare + ConoHa VPS でのデプロイ手順です。

## 構成概要

```
┌─────────────────────────────────────────────────────────┐
│                      Cloudflare                          │
│  ┌─────────────────────────────────────────────────────┐│
│  │         DNS + CDN + SSL + ドメイン管理              ││
│  └───────────────────────┬─────────────────────────────┘│
└──────────────────────────┼──────────────────────────────┘
                           │
         ┌─────────────────┴─────────────────┐
         │                                   │
         ▼                                   ▼
┌─────────────────────┐           ┌─────────────────────────┐
│  Cloudflare Pages   │           │     ConoHa VPS 1GB      │
│  (Vue.js)           │           │    (Rails API + MySQL)  │
│                     │   API     │                         │
│  patto.example.com  │──────────►│  api.patto.example.com  │
│                     │           │                         │
│  無料               │           │  ¥468/月               │
└─────────────────────┘           └─────────────────────────┘
```

## コスト

| サービス | 月額 | 年額 |
|---------|------|------|
| ConoHa VPS 1GB（まとめトク） | ¥468 | ¥5,616 |
| Cloudflare Pages | 無料 | 無料 |
| Cloudflare DNS | 無料 | 無料 |
| ドメイン (.com) | - | ~¥1,500 |
| Docker Hub | 無料 | 無料 |
| **合計** | **約 ¥600** | **約 ¥7,100** |

---

## 事前準備チェックリスト

- [ ] Docker Hub アカウント作成
- [ ] Cloudflare アカウント作成
- [ ] SSH キーペア作成（なければ）
- [ ] ローカルに Ruby インストール済み

---

# Step 1: ドメイン取得（Cloudflare）

## 1.1 Cloudflare アカウント作成

1. [Cloudflare](https://dash.cloudflare.com/sign-up) でアカウント作成
2. メール認証を完了

## 1.2 ドメイン購入

1. [Cloudflare Dashboard](https://dash.cloudflare.com/) にログイン
2. 左メニュー **Domain Registration** → **Register Domains**
3. 希望のドメインを検索（例: `patto.com`, `mypatto.dev`）
4. カートに追加して購入（クレジットカード）

```
おすすめ TLD:
  .com   ~$10.11/年 (~¥1,500)
  .dev   ~$12.00/年 (~¥1,800)  ※HTTPS強制
  .app   ~$14.00/年 (~¥2,100)  ※HTTPS強制
```

## 1.3 DNS設定（後で使う）

ドメイン購入後、DNS設定画面をブックマークしておく：
**Dashboard** → **あなたのドメイン** → **DNS** → **Records**

---

# Step 2: ConoHa VPS 契約

## 2.1 アカウント作成

1. [ConoHa](https://www.conoha.jp/) にアクセス
2. **今すぐお申し込み** → アカウント作成
3. 電話/SMS認証、支払い方法登録

## 2.2 VPS 作成

1. **VPS** → **サーバー追加**
2. 以下の設定で作成：

| 項目 | 設定値 |
|------|--------|
| リージョン | 東京 |
| サービス | VPS |
| 料金タイプ | まとめトク（1GB: ¥468/月） |
| イメージ | **Ubuntu 24.04** |
| rootパスワード | 強力なパスワードを設定 |
| SSH Key | **追加する**（下記参照） |

## 2.3 SSH キーの登録

### ローカルで SSH キー作成（まだない場合）

```bash
# キー生成
ssh-keygen -t ed25519 -C "your-email@example.com"

# 公開鍵を表示
cat ~/.ssh/id_ed25519.pub
```

### ConoHa に公開鍵を登録

1. VPS作成画面で **SSH Key** → **キーを追加**
2. 公開鍵（`ssh-ed25519 AAAA...`）を貼り付け
3. 名前をつけて保存

## 2.4 サーバー情報をメモ

作成完了後、以下をメモ：

```
サーバーIP: xxx.xxx.xxx.xxx
```

## 2.5 SSH 接続確認

```bash
ssh root@YOUR_SERVER_IP
```

接続できれば OK。`exit` で抜ける。

---

# Step 3: サーバー初期設定

SSH でサーバーに接続して実行：

```bash
ssh root@YOUR_SERVER_IP
```

## 3.1 Docker インストール

```bash
# Docker インストール（公式スクリプト）
curl -fsSL https://get.docker.com | sh

# 確認
docker --version
# Docker version 27.x.x が表示されればOK
```

## 3.2 デプロイ専用ユーザー作成

セキュリティのため、root ではなく専用ユーザーでデプロイします。

```bash
# deploy ユーザー作成
adduser deploy --disabled-password --gecos ""

# SSH キー設定（root と同じ鍵を使用）
mkdir -p /home/deploy/.ssh
cp ~/.ssh/authorized_keys /home/deploy/.ssh/
chown -R deploy:deploy /home/deploy/.ssh
chmod 700 /home/deploy/.ssh
chmod 600 /home/deploy/.ssh/authorized_keys

# Docker グループに追加（sudo なしで docker 実行可能に）
usermod -aG docker deploy
```

## 3.3 ファイアウォール設定

```bash
# ufw 有効化
ufw allow OpenSSH
ufw allow 80
ufw allow 443
ufw enable

# 確認
ufw status
```

## 3.4 接続確認

サーバーから exit して、deploy ユーザーで接続確認：

```bash
exit

# deploy ユーザーで接続テスト
ssh deploy@YOUR_SERVER_IP

# Docker が使えることを確認
docker ps

# 確認できたら exit
exit
```

**これ以降は `deploy` ユーザーで接続します。**

---

# Step 4: Docker Hub 設定

## 4.1 アカウント作成

1. [Docker Hub](https://hub.docker.com/) でアカウント作成
2. メール認証を完了

## 4.2 アクセストークン取得

1. **Account Settings** → **Security** → **Access Tokens**
2. **New Access Token** をクリック
3. 名前: `patto-deploy`
4. 権限: **Read, Write, Delete**
5. 生成されたトークンをメモ（一度しか表示されない！）

```
トークン例: dckr_pat_xxxxxxxxxxxxxxxxxxxx
```

---

# Step 5: Kamal 設定

## 5.1 deploy.yml の編集

`backend/config/deploy.yml` を編集：

```bash
cd backend
vim config/deploy.yml
```

以下を自分の情報に置き換え：

```yaml
# Docker Hub ユーザー名
image: YOUR_DOCKERHUB_USERNAME/patto

# サーバーIP（2箇所）
servers:
  web:
    hosts:
      - YOUR_SERVER_IP  # ← ConoHa の IP

# ドメイン
proxy:
  host: api.your-domain.com  # ← 購入したドメイン

# 同じくサーバーIP
accessories:
  mysql:
    host: YOUR_SERVER_IP  # ← ConoHa の IP

# メールアドレス（SSL証明書用）
traefik:
  args:
    certificatesResolvers.letsencrypt.acme.email: your-email@example.com
```

## 5.2 シークレット設定

```bash
# シークレットファイルをコピー
cp .kamal/secrets.example .kamal/secrets

# 編集
vim .kamal/secrets
```

内容を設定：

```bash
# Docker Hub トークン（Step 4.2 で取得）
KAMAL_REGISTRY_PASSWORD=dckr_pat_xxxxxxxxxxxx

# Rails Master Key
# 確認: cat config/master.key
RAILS_MASTER_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# DB パスワード（以下で生成）
# openssl rand -hex 24
BACKEND_DATABASE_PASSWORD=生成したパスワード
MYSQL_ROOT_PASSWORD=生成したパスワード
```

パスワード生成：

```bash
# 安全なパスワードを生成
openssl rand -hex 24
```

---

# Step 6: DNS 設定

## 6.1 Cloudflare DNS にレコード追加

[Cloudflare Dashboard](https://dash.cloudflare.com/) → あなたのドメイン → **DNS** → **Records**

### API サーバー用（Aレコード）

| 項目 | 値 |
|------|-----|
| Type | A |
| Name | api |
| IPv4 address | YOUR_SERVER_IP |
| Proxy status | **OFF（DNS only）** ← 重要！グレーの雲 |
| TTL | Auto |

### フロントエンド用（後で設定）

Cloudflare Pages 設定後に追加します。

---

# Step 7: 初回デプロイ

## 7.1 Kamal インストール

ローカルで実行：

```bash
gem install kamal
```

## 7.2 デプロイ実行

```bash
cd backend

# 初回セットアップ（サーバー準備 + デプロイ）
kamal setup
```

所要時間: 5-10分

### よくあるエラーと対処

**SSH接続エラー:**
```bash
# known_hosts に追加
ssh-keyscan -H YOUR_SERVER_IP >> ~/.ssh/known_hosts
```

**Docker ログインエラー:**
→ Docker Hub トークンを確認

## 7.3 データベース作成

デプロイ完了後、追加DBを作成：

```bash
# MySQL に接続
kamal accessory exec mysql --interactive 'mysql -u root -p'
```

パスワード入力後、以下のSQLを実行：

```sql
CREATE DATABASE backend_production_cache;
CREATE DATABASE backend_production_queue;
CREATE DATABASE backend_production_cable;
GRANT ALL PRIVILEGES ON backend_production_cache.* TO 'backend'@'%';
GRANT ALL PRIVILEGES ON backend_production_queue.* TO 'backend'@'%';
GRANT ALL PRIVILEGES ON backend_production_cable.* TO 'backend'@'%';
FLUSH PRIVILEGES;
exit;
```

## 7.4 マイグレーション

```bash
kamal app exec 'bin/rails db:migrate'
```

## 7.5 動作確認

ブラウザで確認：

```
https://api.your-domain.com/up
```

`OK` が表示されれば成功！

---

# Step 8: Cloudflare Pages 設定

## 8.1 プロジェクト作成

1. [Cloudflare Dashboard](https://dash.cloudflare.com/) → **Workers & Pages**
2. **Create** → **Pages** → **Connect to Git**
3. GitHub を連携してリポジトリを選択

## 8.2 ビルド設定

| 項目 | 値 |
|------|-----|
| Project name | patto |
| Production branch | main |
| Framework preset | None |
| Build command | `cd frontend && npm ci && npm run build` |
| Build output directory | `frontend/dist` |
| Root directory | `/` (空のまま) |

## 8.3 環境変数

**Settings** → **Environment variables** → **Add variable**

| Variable name | Value |
|---------------|-------|
| `VITE_API_URL` | `https://api.your-domain.com/api` |

**Save** をクリック

## 8.4 カスタムドメイン設定

1. **Custom domains** → **Set up a custom domain**
2. `your-domain.com` を入力
3. Cloudflare DNS に自動でレコードが追加される
4. `www.your-domain.com` も追加（任意）

## 8.5 デプロイ

1. **Deployments** → **Retry deployment** または
2. GitHub に push すると自動デプロイ

## 8.6 動作確認

```
https://your-domain.com
```

アプリが表示されれば完了！

---

# Step 9: GitHub Actions 設定（自動デプロイ）

## 9.1 リポジトリ Secrets 設定

GitHub → リポジトリ → **Settings** → **Secrets and variables** → **Actions**

### Secrets（機密情報）

| Name | Value |
|------|-------|
| `DOCKERHUB_USERNAME` | Docker Hub ユーザー名 |
| `DOCKERHUB_TOKEN` | Docker Hub アクセストークン |
| `SSH_PRIVATE_KEY` | deploy ユーザー用 SSH 秘密鍵 (`cat ~/.ssh/id_ed25519`) |
| `SERVER_IP` | ConoHa VPS の IP |
| `RAILS_MASTER_KEY` | Rails Master Key |
| `BACKEND_DATABASE_PASSWORD` | DB パスワード |
| `MYSQL_ROOT_PASSWORD` | MySQL root パスワード |
| `CLOUDFLARE_API_TOKEN` | Cloudflare API トークン |
| `CLOUDFLARE_ACCOUNT_ID` | Cloudflare アカウント ID |

**注意**: `SSH_PRIVATE_KEY` は deploy ユーザーでサーバーに接続できる秘密鍵です。

### Variables（公開情報）

| Name | Value |
|------|-------|
| `VITE_API_URL` | `https://api.your-domain.com/api` |

## 9.2 Cloudflare API トークン取得

1. [Cloudflare API Tokens](https://dash.cloudflare.com/profile/api-tokens)
2. **Create Token**
3. **Custom token** → **Get started**
4. 権限設定：
   - Account / Cloudflare Pages / Edit
5. トークンを保存

## 9.3 Cloudflare Account ID 取得

Dashboard 右サイドバー → **Account ID** をコピー

---

# 運用コマンド一覧

## デプロイ

```bash
cd backend
kamal deploy          # 通常デプロイ
kamal deploy --skip-push  # ビルド済みイメージを使用
```

## ログ確認

```bash
kamal app logs        # 最新ログ
kamal app logs -f     # リアルタイム
kamal app logs -n 100 # 直近100行
```

## Rails コンソール

```bash
kamal app exec --interactive 'bin/rails console'
```

## MySQL 接続

```bash
kamal accessory exec mysql --interactive 'mysql -u backend -p backend_production'
```

## ロールバック

```bash
kamal rollback        # 1つ前のバージョンに戻す
```

## 再起動

```bash
kamal app boot        # Rails 再起動
kamal accessory reboot mysql  # MySQL 再起動
kamal traefik reboot  # Traefik 再起動
```

## サーバー状態確認

```bash
kamal app details     # アプリ状態
kamal accessory details mysql  # MySQL 状態
```

---

# バックアップ

## 手動バックアップ

```bash
# MySQL ダンプ
kamal accessory exec mysql 'mysqldump -u backend -p backend_production' > backup_$(date +%Y%m%d).sql
```

## 自動バックアップ（サーバー上で設定）

```bash
ssh deploy@YOUR_SERVER_IP

# バックアップディレクトリ作成
mkdir -p ~/backups/mysql

# cron 設定
crontab -e
```

以下を追加（毎日3時にバックアップ）：

```cron
0 3 * * * docker exec patto-mysql mysqldump -u backend -pYOUR_DB_PASSWORD backend_production | gzip > ~/backups/mysql/$(date +\%Y\%m\%d).sql.gz
# 7日より古いバックアップを削除
0 4 * * * find ~/backups/mysql -mtime +7 -delete
```

---

# トラブルシューティング

## デプロイが失敗する

```bash
# 詳細ログ
kamal deploy --verbose

# Docker ビルドのみテスト
cd backend
docker build -t test .
```

## SSL 証明書エラー

```bash
# Traefik ログ確認
ssh deploy@YOUR_SERVER_IP
docker logs traefik

# DNS 設定を確認
# api.your-domain.com の Proxy が OFF になっているか
```

## コンテナが起動しない

```bash
# サーバーで確認
ssh deploy@YOUR_SERVER_IP
docker ps -a
docker logs patto-web
```

## DB 接続エラー

```bash
# ネットワーク確認
kamal accessory exec mysql 'mysql -u backend -p -e "SELECT 1"'

# 環境変数確認
kamal app exec 'env | grep DB'
```

---

# 完了チェックリスト

- [ ] ドメイン取得完了
- [ ] ConoHa VPS 作成完了
- [ ] Docker インストール完了
- [ ] Kamal 初回デプロイ成功
- [ ] API 動作確認 (`/up`)
- [ ] Cloudflare Pages デプロイ成功
- [ ] フロントエンド動作確認
- [ ] GitHub Actions 設定完了（任意）
- [ ] バックアップ設定完了（任意）

---

# サポート

問題が発生した場合：

1. このドキュメントのトラブルシューティングを確認
2. [Kamal 公式ドキュメント](https://kamal-deploy.org/docs/)
3. [ConoHa サポート](https://support.conoha.jp/)
4. [Cloudflare ドキュメント](https://developers.cloudflare.com/)
