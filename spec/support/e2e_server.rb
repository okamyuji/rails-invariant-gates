require "json"
require "net/http"
require "rbconfig"
require "socket"

module E2EServer
  BOOT_TIMEOUT = 30
  STOP_TIMEOUT = 15
  READ_TIMEOUT = 10
  LOG_PATH = Rails.root.join("log/e2e_server.log")

  class Unavailable < StandardError; end

  class << self
    attr_reader :base_uri

    def start
      port = free_port
      @base_uri = URI("http://127.0.0.1:#{port}")
      # out と err に同じパスを別々に渡すと、2つの出力が互いを上書きして起動失敗の行が消える。
      @pid = Process.spawn(RbConfig.ruby, *coverage_args, "bin/rails", "server", "-e", "test",
                           "-b", "127.0.0.1", "-p", port.to_s,
                           chdir: Rails.root.to_s, [ :out, :err ] => [ LOG_PATH.to_s, "w" ])
      wait_until_ready
    end

    def stop
      return unless @pid

      Process.kill("TERM", @pid)
      # TERMで止まらないときだけKILLする。KILLするとサーバー側のカバレッジは書かれない。
      Process.kill("KILL", @pid) unless wait_for_exit(STOP_TIMEOUT)
      @pid = nil
    end

    def log
      File.exist?(LOG_PATH) ? File.read(LOG_PATH) : ""
    end

    private

    # 空きポートをOSに選ばせてから閉じる。閉じてから起動までの間に取られる可能性は残る。
    def free_port
      server = TCPServer.new("127.0.0.1", 0)
      server.addr[1]
    ensure
      server&.close
    end

    # RUBYOPT は空白で区切られるため、パスに空白があっても壊れないよう -r を引数で渡す。
    def coverage_args
      ENV["NO_COVERAGE"] ? [] : [ "-r", File.expand_path("e2e_coverage.rb", __dir__) ]
    end

    def wait_until_ready
      deadline = monotonic + BOOT_TIMEOUT
      until ready?
        raise Unavailable, "E2Eサーバーが終了しました\n#{log}" if exited?
        raise Unavailable, "E2Eサーバーが#{BOOT_TIMEOUT}秒以内に起動しませんでした\n#{log}" if monotonic > deadline

        sleep 0.2
      end
    end

    def ready?
      Net::HTTP.get_response(base_uri + "/up").code == "200"
    rescue SystemCallError, Net::OpenTimeout, EOFError
      false
    end

    # waitpid で回収した子プロセスにはシグナルを送れないため、stop が何もしないようにする。
    def exited?
      return false unless Process.waitpid(@pid, Process::WNOHANG)

      @pid = nil
      true
    end

    def wait_for_exit(timeout)
      deadline = monotonic + timeout
      until Process.waitpid(@pid, Process::WNOHANG)
        return false if monotonic > deadline

        sleep 0.1
      end
      true
    end

    def monotonic = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  end

  module Helpers
    def e2e_get(path)
      request(Net::HTTP::Get.new(E2EServer.base_uri + path))
    end

    # body に文字列を渡すと、そのまま送る（壊れたJSONを送る例のため）。
    def e2e_post(path, body = {})
      req = Net::HTTP::Post.new(E2EServer.base_uri + path, "Content-Type" => "application/json")
      req.body = body.is_a?(String) ? body : JSON.generate(body)
      request(req)
    end

    private

    # 既定の60秒待ちと冪等な要求の自動再試行では、応答しないサーバーで1例が2分止まる。
    def request(req)
      res = Net::HTTP.start(req.uri.host, req.uri.port,
                            read_timeout: E2EServer::READ_TIMEOUT, max_retries: 0) { it.request(req) }
      [ res.code.to_i, parse(res.body) ]
    rescue SystemCallError, EOFError, Net::ReadTimeout => e
      raise E2EServer::Unavailable, "E2Eサーバーへの要求が失敗しました（#{e.class}）\n#{E2EServer.log}"
    end

    # /up はHTMLを返すため、JSONでない本文はnilにする。
    def parse(body)
      JSON.parse(body.to_s)
    rescue JSON::ParserError
      nil
    end
  end
end

RSpec.configure do |config|
  config.include E2EServer::Helpers, type: :e2e
  # E2Eの例が1つも定義されていなければ起動しない。タグで除外した例も「定義済み」に数えられる。
  config.when_first_matching_example_defined(type: :e2e) do
    config.before(:suite) { E2EServer.start }
    config.after(:suite) { E2EServer.stop }
  end
end
