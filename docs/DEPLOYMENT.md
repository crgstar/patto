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
| セキュリティグループ | ssh と web を設定 |

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

## 2.5 サーバー情報をメモ

作成完了後、以下をメモ：

```
サーバーIP: xxx.xxx.xxx.xxx
```

## 2.6 SSH 接続確認

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

# MySQLデータ用ディレクトリを作成（Kamal用）
mkdir -p /home/deploy/patto-mysql/mysql_data
chown -R deploy:deploy /home/deploy/patto-mysql
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

# サーバーIP
servers:
  web:
    hosts:
      - YOUR_SERVER_IP  # ← ConoHa の IP

# ドメイン（API用）
proxy:
  ssl: true
  host: api.patto.your-domain.com  # ← 購入したドメイン

# フロントエンドURL
env:
  clear:
    FRONTEND_URL: https://patto.your-domain.com

# MySQL のサーバーIP
accessories:
  mysql:
    host: YOUR_SERVER_IP  # ← ConoHa の IP
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

## 7.3 マイグレーション確認（初回は自動実行済み）

初回デプロイ時は `db:prepare` が自動実行されますが、確認のため：

```bash
# マイグレーション状態を確認
kamal app exec 'bin/rails db:migrate:status'
```

2回目以降のデプロイでマイグレーションを追加した場合は手動実行：

```bash
kamal app exec 'bin/rails db:migrate'
```

## 7.4 動作確認

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
| Root directory | `frontend` |
| Build command | `npm run build` |
| Build output directory | `dist` |

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

# Step 9: GitHub Actions 設定（バックエンド自動デプロイ）

このステップでは、Rails API バックエンドの自動デプロイを設定します。

> **Note**: フロントエンド（Vue.js）は Step 8 で Cloudflare Pages と GitHub を連携済みのため、自動デプロイされます。GitHub Actions の設定は不要です。

## 9.1 必要な情報を準備

以下の情報を手元に用意してください：

### Docker Hub 情報

| 項目 | 取得方法 |
|------|---------|
| `DOCKERHUB_USERNAME` | Docker Hub のユーザー名 |
| `DOCKERHUB_TOKEN` | [Docker Hub](https://hub.docker.com/) → Account Settings → Security → Access Tokens → New Access Token<br>（権限: Read, Write, Delete） |

### SSH 接続情報

| 項目 | 取得方法 |
|------|---------|
| `SSH_PRIVATE_KEY` | `cat ~/.ssh/id_ed25519` を実行して秘密鍵全体をコピー<br>（`-----BEGIN OPENSSH PRIVATE KEY-----` で始まる） |
| `SERVER_IP` | ConoHa VPS の IP アドレス |

### Rails 環境変数

| 項目 | 取得方法 |
|------|---------|
| `RAILS_MASTER_KEY` | `cat backend/config/master.key` |
| `BACKEND_DATABASE_PASSWORD` | `backend/.kamal/secrets` ファイルの値 |
| `MYSQL_ROOT_PASSWORD` | `backend/.kamal/secrets` ファイルの値 |

## 9.2 GitHub Secrets を設定

1. GitHub リポジトリページを開く
2. **Settings** → **Secrets and variables** → **Actions**
3. **Secrets** タブで **New repository secret** をクリック
4. 以下の **7 個**の Secrets を追加：

| Name | Value | 説明 |
|------|-------|------|
| `DOCKERHUB_USERNAME` | Docker Hub ユーザー名 | Docker イメージのプッシュに使用 |
| `DOCKERHUB_TOKEN` | Docker Hub アクセストークン | Docker Hub への認証 |
| `SSH_PRIVATE_KEY` | SSH 秘密鍵（全体） | VPS への接続に使用 |
| `SERVER_IP` | ConoHa VPS の IP | デプロイ先サーバー |
| `RAILS_MASTER_KEY` | Rails Master Key | credentials.yml.enc の復号化 |
| `BACKEND_DATABASE_PASSWORD` | DB パスワード | Rails の DB 接続（MySQL ユーザー "backend" のパスワード） |
| `MYSQL_ROOT_PASSWORD` | MySQL root パスワード | MySQL コンテナの起動 |

> **Note**: `MYSQL_PASSWORD` は `BACKEND_DATABASE_PASSWORD` と同じ値が自動的に使用されるため、追加で設定する必要はありません。

**重要な注意点:**
- `SSH_PRIVATE_KEY` は改行を含む秘密鍵全体をコピーしてください
- 秘密鍵は `-----BEGIN OPENSSH PRIVATE KEY-----` で始まり `-----END OPENSSH PRIVATE KEY-----` で終わります

## 9.3 GitHub Actions ワークフローファイルを作成

`.github/workflows/deploy-backend.yml` を作成します（次のセクションで詳細説明）。

## 9.4 動作確認

### 初回デプロイテスト

1. ワークフローファイルを main ブランチに push
2. GitHub リポジトリの **Actions** タブを開く
3. ワークフローが自動実行されることを確認
4. すべてのステップが成功（✅）になることを確認

### API 動作確認

```bash
curl https://api.your-domain.com/up
# "OK" が返ってくればデプロイ成功
```

## 9.5 トラブルシューティング

**SSH 接続エラー**
```
✗ SSH 接続に失敗しました
```
→ `SSH_PRIVATE_KEY` が正しくコピーされているか確認してください

**Docker ログインエラー**
```
✗ Docker Hub にログインできません
```
→ `DOCKERHUB_TOKEN` が正しいか、権限に "Write" が含まれているか確認してください

**Kamal エラー**
```
✗ Kamal デプロイに失敗しました
```
→ ローカルで `kamal deploy` が成功するか確認してください

## 9.6 運用

### 自動デプロイのトリガー

- `main` ブランチに push
- `backend/` ディレクトリ以下のファイルが変更された時

### 手動デプロイ

GitHub の **Actions** タブ → **Deploy Backend to VPS** → **Run workflow**

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
kamal proxy reboot    # Proxy 再起動
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
# kamal-proxy ログ確認
ssh deploy@YOUR_SERVER_IP
docker logs kamal-proxy

# DNS 設定を確認
# api.patto.your-domain.com の Proxy が OFF になっているか
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
