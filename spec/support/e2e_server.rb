require "json"
require "net/http"
require "socket"

module E2EServer
  BOOT_TIMEOUT = 30
  STOP_TIMEOUT = 15
  LOG_PATH = Rails.root.join("log/e2e_server.log")

  class << self
    attr_reader :base_uri

    def start
      port = free_port
      @base_uri = URI("http://127.0.0.1:#{port}")
      @pid = Process.spawn(server_env, "bin/rails", "server", "-e", "test", "-b", "127.0.0.1", "-p", port.to_s,
                           chdir: Rails.root.to_s, out: LOG_PATH.to_s, err: LOG_PATH.to_s)
      wait_until_ready
    end

    def stop
      return unless @pid

      Process.kill("TERM", @pid)
      # TERMで止まらないときだけKILLする。KILLするとサーバー側のカバレッジは書かれない。
      Process.kill("KILL", @pid) unless wait_for_exit(STOP_TIMEOUT)
      @pid = nil
    end

    private

    # 空きポートをOSに選ばせてから閉じる。閉じてから起動までの間に取られる可能性は残る。
    def free_port
      server = TCPServer.new("127.0.0.1", 0)
      server.addr[1]
    ensure
      server&.close
    end

    def server_env
      return {} if ENV["NO_COVERAGE"]

      { "RUBYOPT" => "#{ENV["RUBYOPT"]} -r#{File.expand_path("e2e_coverage.rb", __dir__)}" }
    end

    def wait_until_ready
      deadline = monotonic + BOOT_TIMEOUT
      until ready?
        raise "E2Eサーバーが終了しました\n#{log_tail}" if exited?
        raise "E2Eサーバーが#{BOOT_TIMEOUT}秒以内に起動しませんでした\n#{log_tail}" if monotonic > deadline

        sleep 0.2
      end
    end

    def ready?
      Net::HTTP.get_response(base_uri + "/up").code == "200"
    rescue SystemCallError, Net::OpenTimeout, EOFError
      false
    end

    def exited?
      Process.waitpid(@pid, Process::WNOHANG)
    end

    def wait_for_exit(timeout)
      deadline = monotonic + timeout
      until Process.waitpid(@pid, Process::WNOHANG)
        return false if monotonic > deadline

        sleep 0.1
      end
      true
    end

    def log_tail
      File.exist?(LOG_PATH) ? File.readlines(LOG_PATH).last(20).join : ""
    end

    def monotonic = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  end

  module Helpers
    def e2e_get(path)
      request(Net::HTTP::Get.new(E2EServer.base_uri + path))
    end

    def e2e_post(path, body = {})
      req = Net::HTTP::Post.new(E2EServer.base_uri + path, "Content-Type" => "application/json")
      req.body = JSON.generate(body)
      request(req)
    end

    private

    def request(req)
      res = Net::HTTP.start(req.uri.host, req.uri.port) { it.request(req) }
      [ res.code.to_i, parse(res.body) ]
    end

    # /up はHTMLを返すため、JSONでない本文はnilにする。
    def parse(body)
      JSON.parse(body.to_s)
    rescue JSON::ParserError
      nil
    end
  end
end

# このファイルはE2Eのspecからだけ読み込むので、E2Eを含まない実行ではサーバーを起動しない。
RSpec.configure do |config|
  config.include E2EServer::Helpers, type: :e2e
  config.before(:suite) { E2EServer.start }
  config.after(:suite) { E2EServer.stop }
end
