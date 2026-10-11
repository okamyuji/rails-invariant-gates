desc "specの名前に書いたIDとAGENTS.mdの契約の表の行を突き合わせ、抜けがあれば失敗する。specの中身は見ない"
task :contract_ids do
  require "json"
  require_relative "../contract_ids"

  out = "tmp/contract_ids.json"
  # dry-runでもSimpleCovが動くと、直前に取ったカバレッジの結果を上書きする。
  sh({ "NO_COVERAGE" => "1" }, "bundle exec rspec --dry-run --format json --out #{out}", out: File::NULL)
  descriptions = JSON.parse(File.read(out))["examples"].map { it["full_description"] }
  result = ContractIds.check(table: File.read("AGENTS.md"), descriptions:)

  { unnamed: "表のIDがないspec", unknown: "表にないID", uncovered: "specのない表の行" }.each do |key, label|
    result[key].each { puts "#{label}: #{it}" }
  end
  abort "specの名前のIDと契約の表の行に抜けがあります" if result.values.any?(&:any?)
  puts "specの名前のIDと契約の表の行に抜けはありません（specの中身は照合していません）"
end
