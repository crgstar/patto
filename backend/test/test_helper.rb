ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "webmock/minitest"

# WebMockの設定: テスト中はすべての実HTTPリクエストをブロック
WebMock.disable_net_connect!(allow_localhost: true)

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    # PARALLEL_WORKERS環境変数で制御可能（未指定時はCPU数に応じた並列実行）
    # 例: PARALLEL_WORKERS=1 bin/rails test （順次実行）
    workers_count = if ENV['PARALLEL_WORKERS']
                      ENV['PARALLEL_WORKERS'].to_i
                    else
                      :number_of_processors
                    end
    parallelize(workers: workers_count)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
