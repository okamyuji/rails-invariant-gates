desc "メソッドごとのCRAP値を一覧し、閾値以上があれば失敗する（例: bin/rails 'crap_metrics[15]'）"
task :crap_metrics, [ :threshold ] do |_task, args|
  require_relative "../crap_metrics"

  threshold = Float(args.with_defaults(threshold: "30")[:threshold])
  started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  rows = CrapMetrics.new(
    paths: Dir["app/**/*.rb", "lib/**/*.rb"].sort,
    resultset_path: "coverage/.resultset.json"
  ).rows
  offenders = CrapMetrics.report(rows, threshold:, io: $stdout)
  puts format("計算時間: %.2f秒", Process.clock_gettime(Process::CLOCK_MONOTONIC) - started)

  abort "CRAP値が#{format("%g", threshold)}以上のメソッドがあります" if offenders.any?
end
