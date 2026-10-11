# rails-invariant-gates

不変条件、事前条件、事後条件を設計で決め、RSpec、ミューテーションテスト（[evilution](https://github.com/marinazzio/evilution)）、CRAP値、DB制約で実装に守らせるRailsアプリのサンプルです。

## 動かし方

動作環境はRuby 4.0.7、Rails 8.1.4、MySQL 8.4です。Rubyの版は `mise.toml` に書いてあり、ローカルの[mise](https://mise.jdx.dev/)、CIの[setup-ruby](https://github.com/ruby/setup-ruby)、RuboCopの対象版の判定は、どれもこのファイルを読みます。

```sh
mise install
docker compose up -d --wait
bundle install
pre-commit install
bin/rails db:create db:schema:load
bin/rails quality
```

`bin/rails quality` は次の順に実行し、どれかが失敗すると止まります。

1. `bundle exec rspec`（SimpleCovで行カバレッジ80%以上）
2. `bundle exec evilution run ... --min-score 1.0`（生き残った変異が0件）
3. `bin/rails 'crap_metrics[15]'`（CRAP値が15以上のメソッドが0件）

## フォーマッターとリンター

コミット前に[pre-commit](https://pre-commit.com/)が次を実行します。設定は `.pre-commit-config.yaml` です。

- 行末の空白と、ファイル末尾の改行を直します。
- YAMLの構文と、マージの衝突記号を確かめます。
- `bin/rubocop --autocorrect` でRubyを整形し、規約違反を止めます。

CIのlintジョブも、同じ設定を `pipx run pre-commit==4.6.2 run --all-files` で実行します。RuboCopは `bin/rubocop` 経由なので、ローカルとCIのどちらでも `Gemfile.lock` に書かれた版が動きます。pre-commit-hooksの版は、書き換えられないコミットのSHAで指定しました。

全ファイルに一度かけるときのコマンドは次のとおりです。

```sh
pre-commit run --all-files
```

## JSON APIとE2E

送料見積もり、注文キャンセル、在庫引当はJSON APIで公開しており、契約は `AGENTS.md` の表のとおりです。

このAPIには認証も所有者の確認もなく、誰でもIDを指定して注文をキャンセルしたり在庫を引き当てたりできます。説明用のサンプルなので、そのままデプロイしないでください。

`spec/e2e/` のE2Eは、空いているポートで `bin/rails server -e test` を子プロセスとして起動し、`Net::HTTP` で要求を送ります。データはspec側でコミットしてからサーバーに読ませ、各例の後で消すのが決まりです。在庫引当では、在庫1個に2本の要求を同時に送り、成功が1件だけになるかを見ます。サーバー側のカバレッジもSimpleCovでマージするので、コントローラも行カバレッジとCRAP値の対象です。

evilutionは変異をテストのプロセスの中で当てるため、別プロセスのサーバーには届きません。このため、コントローラはevilutionの対象に入れていません。

## 弱いspecの再現

`weak_specs/` には、変異を見逃すspecを置いています。次のように実行すると、生き残る変異を確かめられます。

```sh
script/evil_json app/services/shipping_calculator.rb weak_specs/services/shipping_calculator_spec.rb shipping_weak
```

記事に載せた件数は、弱いspecと最終のspecの両方について `script/article_measurements` で取り直せます。

## CRAP値

`lib/tasks/crap_metrics.rake` は、Prismで数えたメソッドごとの循環的複雑度と、SimpleCovの行カバレッジからCRAP値を計算します。

```sh
bundle exec rspec
bin/rails 'crap_metrics[30]'
```

## ライセンス

MIT
