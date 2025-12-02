#!/bin/bash

# TODO管理アプリ - 停止スクリプト

set -e

echo "🛑 TODO管理アプリを停止しています..."
echo ""

# プロジェクトのルートディレクトリに移動
cd "$(dirname "$0")"

# Viteサーバーを停止
if [ -f logs/vite.pid ]; then
  VITE_PID=$(cat logs/vite.pid)
  if ps -p $VITE_PID > /dev/null 2>&1; then
    echo "⚡ Viteサーバーを停止中... (PID: $VITE_PID)"
    kill $VITE_PID 2>/dev/null || true
    rm logs/vite.pid
    echo "✅ Viteサーバーを停止しました"
  else
    echo "ℹ️  Viteサーバーは既に停止しています"
    rm logs/vite.pid 2>/dev/null || true
  fi
else
  echo "ℹ️  ViteサーバーのPIDファイルが見つかりません"
fi
echo ""

# Railsサーバーを停止
if [ -f logs/rails.pid ]; then
  RAILS_PID=$(cat logs/rails.pid)
  if ps -p $RAILS_PID > /dev/null 2>&1; then
    echo "🛤️  Railsサーバーを停止中... (PID: $RAILS_PID)"
    kill $RAILS_PID 2>/dev/null || true
    rm logs/rails.pid
    echo "✅ Railsサーバーを停止しました"
  else
    echo "ℹ️  Railsサーバーは既に停止しています"
    rm logs/rails.pid 2>/dev/null || true
  fi
else
  echo "ℹ️  RailsサーバーのPIDファイルが見つかりません"
fi
echo ""

# MySQLコンテナを停止（オプション）
read -p "MySQLコンテナも停止しますか？ (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo "📦 MySQLコンテナを停止中..."
  docker compose down
  echo "✅ MySQLコンテナを停止しました"
else
  echo "ℹ️  MySQLコンテナは起動したままにします"
fi
echo ""

echo "✅ アプリケーションを停止しました"
