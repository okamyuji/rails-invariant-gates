# サーバーの子プロセスに RUBYOPT=-r で読ませる。RSpecプロセスの結果とマージさせるため command_name を分ける。
require "simplecov"

SimpleCov.command_name "e2e-server"
SimpleCov.start "rails" do
  enable_coverage :branch
end
