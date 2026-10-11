require "spec_helper"
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
# E2Eはトランザクションを使わずにレコードを消すため、test以外のDBへ接続したまま進めない。
abort("specはtest環境でだけ実行します（現在: #{Rails.env}）") unless Rails.env.test?
require "rspec/rails"

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.filter_rails_from_backtrace!
end
