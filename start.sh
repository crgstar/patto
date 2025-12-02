#!/bin/bash

# TODO管理アプリ - 起動スクリプト

set -e

echo "🚀 TODO管理アプリを起動しています..."
echo ""

# プロジェクトのルートディレクトリに移動
cd "$(dirname "$0")"

# MySQLコンテナを起動
echo "📦 MySQLコンテナを起動中..."
docker compose up -d mysql
echo "✅ MySQLコンテナを起動しました"
echo ""

# MySQLの起動を待つ
echo "⏳ MySQLの起動を待っています..."
sleep 5
echo "✅ MySQLが起動しました"
echo ""

# Railsサーバーを起動
echo "🛤️  Railsサーバーを起動中..."
cd backend
bundle exec rails server -b 0.0.0.0 -p 3000 > ../logs/rails.log 2>&1 &
RAILS_PID=$!
echo $RAILS_PID > ../logs/rails.pid
cd ..
echo "✅ Railsサーバーを起動しました (PID: $RAILS_PID, ポート: 3000)"
echo ""

# Viteサーバーを起動
echo "⚡ Viteサーバーを起動中..."
cd frontend
npm run dev > ../logs/vite.log 2>&1 &
VITE_PID=$!
echo $VITE_PID > ../logs/vite.pid
cd ..
echo "✅ Viteサーバーを起動しました (PID: $VITE_PID, ポート: 5173)"
echo ""

echo "🎉 すべてのサービスが起動しました！"
echo ""
echo "📍 アクセスURL:"
echo "   - フロントエンド: http://localhost:5173"
echo "   - バックエンドAPI: http://localhost:3000"
echo "   - MySQL: localhost:3306"
echo ""
echo "🛑 停止するには: ./stop.sh を実行してください"
