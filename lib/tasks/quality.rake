MUTATION_TARGETS = FileList["app/models/**/*.rb", "app/services/**/*.rb", "lib/**/*.rb"]
                   .exclude("app/models/application_record.rb")

desc "AIに渡す完了条件。RSpec（行カバレッジ80%以上）、evilution（生存0件）、CRAP値15未満の順に確かめる"
task :quality do
  sh "bundle exec rspec"
  sh({ "NO_COVERAGE" => "1" }, "bundle exec evilution run #{MUTATION_TARGETS.join(" ")} --jobs 4 --min-score 1.0 --no-progress")
  Rake::Task[:crap_metrics].invoke("15")
end
