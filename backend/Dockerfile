# syntax=docker/dockerfile:1
# check=error=true

# このDockerfileは本番環境用です（開発環境用ではありません）
# Kamalで使用するか、手動でビルド・実行してください：
# docker build -t backend .
# docker run -d -p 80:80 -e RAILS_MASTER_KEY=<config/master.keyの値> --name backend backend

# コンテナ化された開発環境については、Dev Containersを参照してください：
# https://guides.rubyonrails.org/getting_started_with_devcontainer.html

# RUBY_VERSIONが.ruby-versionのRubyバージョンと一致することを確認してください
ARG RUBY_VERSION=3.2.0
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

# Railsアプリケーションのディレクトリ
WORKDIR /rails

# 基本パッケージのインストール
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl default-mysql-client libjemalloc2 libvips && \
    ln -s /usr/lib/$(uname -m)-linux-gnu/libjemalloc.so.2 /usr/local/lib/libjemalloc.so && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# 本番環境の環境変数を設定し、メモリ使用量とレイテンシを削減するためにjemallocを有効化
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development" \
    LD_PRELOAD="/usr/local/lib/libjemalloc.so"

# 最終イメージのサイズを削減するための使い捨てビルドステージ
FROM base AS build

# gemのビルドに必要なパッケージをインストール
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential default-libmysqlclient-dev git libyaml-dev pkg-config && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# アプリケーションのgemをインストール
COPY Gemfile Gemfile.lock ./

RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    # QEMUのバグを回避するため、並列コンパイルを無効化（-j 1）
    # https://github.com/rails/bootsnap/issues/495
    bundle exec bootsnap precompile -j 1 --gemfile

# アプリケーションコードをコピー
COPY . .

# 起動時間を短縮するためにbootsnapコードをプリコンパイル
# QEMUのバグを回避するため、並列コンパイルを無効化（-j 1）
# https://github.com/rails/bootsnap/issues/495
RUN bundle exec bootsnap precompile -j 1 app/ lib/

# 最終的なアプリケーションイメージステージ
FROM base

# セキュリティのため、非rootユーザーでランタイムファイルを実行・所有
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash
USER 1000:1000

# ビルドされた成果物をコピー：gems、アプリケーション
COPY --chown=rails:rails --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --chown=rails:rails --from=build /rails /rails

# エントリーポイントでデータベースを準備
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# デフォルトでThruster経由でサーバーを起動（実行時に上書き可能）
EXPOSE 80
CMD ["./bin/thrust", "./bin/rails", "server"]
