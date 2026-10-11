# evilution の JSON レポートから件数と生き残った差分だけを表示する。
# 使い方: ruby script/survivors.rb tmp/report.json
require "json"

report = JSON.parse(File.read(ARGV.fetch(0)))
summary = report.fetch("summary")
puts summary.slice("total", "killed", "survived", "errors", "score").map { |k, v| "#{k}=#{v}" }.join(" ")
report.fetch("survived").each do |mutation|
  puts "- #{mutation["operator"]} #{mutation["file"]}:#{mutation["line"]}"
  puts mutation["diff"].lines.map { |line| "    #{line}" }.join
end
