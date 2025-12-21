#!/bin/bash

# プロジェクトのルートディレクトリに移動
cd "$(dirname "$0")"

# MySQL
echo "📦 MySQL Container:"
if docker compose ps mysql 2>/dev/null | grep -q "Up"; then
  echo "  ✅ 稼働中"
else
  echo "  ❌ 停止中"
fi
echo ""

# Rails
echo "🛤️  Rails Server:"
if [ -f logs/rails.pid ]; then
  RAILS_PID=$(cat logs/rails.pid)
  if ps -p $RAILS_PID > /dev/null 2>&1; then
    echo "  ✅ 稼働中 (PID: $RAILS_PID, ポート: 3000)"
  else
    echo "  ✅ 稼働中 (PIDファイルは存在するがプロセスなし)"
  fi
else
  echo "  ❌ 停止中"
fi
echo ""

# Vite
echo "⚡ Vite Server:"
if [ -f logs/vite.pid ]; then
  VITE_PID=$(cat logs/vite.pid)
  if ps -p $VITE_PID > /dev/null 2>&1; then
    echo "  ✅ 稼働中 (PID: $VITE_PID, ポート: 5173)"
  else
    echo "  ✅ 稼働中 (PIDファイルは存在するがプロセスなし)"
  fi
else
  echo "  ❌ 停止中"
fi
echo ""
