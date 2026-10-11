require "rails_helper"

RSpec.describe CrapMetrics do
  # macOSの一時ディレクトリはシンボリックリンク経由なので、Dir.pwdと同じ実パスにそろえる。
  let(:dir) { Pathname(Dir.mktmpdir).realpath }
  after { FileUtils.remove_entry(dir) }

  def write_source(name, code)
    path = dir.join(name)
    path.write(code)
    path.to_s
  end

  # SimpleCovはtimestampのない結果を古いものとして捨てるため、実物と同じ形で書く。
  def write_resultset(runs)
    path = dir.join(".resultset.json")
    resultset = runs.to_h do |command, coverage_by_path|
      coverage = coverage_by_path.transform_values { |lines| { "lines" => lines } }
      [ command, { "coverage" => coverage, "timestamp" => Time.now.to_i } ]
    end
    path.write(JSON.generate(resultset))
    path.to_s
  end

  def rows_for(code, lines)
    source = write_source("subject.rb", code)
    described_class.new(paths: [ source ], resultset_path: write_resultset("RSpec" => { source => lines })).rows
  end

  describe "CRAP-01 .crap" do
    it "複雑度1でカバレッジ100%なら1になる" do
      expect(described_class.crap(1, 1.0)).to eq(1.0)
    end

    it "カバレッジ0%なら複雑度の2乗に複雑度を足した値になる" do
      expect(described_class.crap(5, 0.0)).to eq(30.0)
    end

    it "原典の式 comp^2 * (1 - cov)^3 + comp で計算する" do
      expect(described_class.crap(10, 0.5)).to eq(22.5)
    end
  end

  describe "CRAP-05 .report" do
    def row(name, crap)
      CrapMetrics::Row.new(name:, location: "app/x.rb:1-3", complexity: 2, coverage: 0.5, crap:, flog: 3.25)
    end

    it "表を出力し、閾値以上のメソッドだけを返す" do
      io = StringIO.new
      rows = [ row("A#far", 30.0), row("A#over", 15.0), row("A#under", 14.99) ]

      offenders = described_class.report(rows, threshold: 15.0, io:)

      aggregate_failures do
        expect(offenders.map(&:name)).to eq([ "A#far", "A#over" ])
        expect(io.string.lines).to eq([
          "    CRAP  複雑度  カバレッジ    flog  メソッド\n",
          "   30.00       2      50.0%    3.25  A#far (app/x.rb:1-3)\n",
          "   15.00       2      50.0%    3.25  A#over (app/x.rb:1-3)\n",
          "   14.99       2      50.0%    3.25  A#under (app/x.rb:1-3)\n",
          "メソッド数: 3 / CRAP値が15以上: 2\n"
        ])
      end
    end
  end

  describe "CRAP-02 #rows の循環的複雑度" do
    {
      "分岐なし" => [ "x = 1\n    x", 1 ],
      "if と elsif" => [ "if a\n      1\n    elsif b\n      2\n    else\n      3\n    end", 3 ],
      "後置 if と後置 unless" => [ "return 1 if a\n    return 2 unless b\n    3", 3 ],
      "三項演算子" => [ "a ? 1 : 2", 2 ],
      "&& と ||" => [ "a && b || c", 3 ],
      "and と or" => [ "a and b or c", 3 ],
      "case の when" => [ "case a\n    when 1 then :one\n    when 2 then :two\n    end", 3 ],
      "case の in" => [ "case a\n    in Integer then :int\n    in String then :str\n    end", 3 ],
      "while と until と for" => [ "while a do end\n    until b do end\n    for i in c do end", 4 ],
      "rescue 節と後置 rescue" => [ "begin\n      a\n    rescue ArgumentError\n      b\n    rescue TypeError\n      c\n    end\n    d rescue e", 4 ],
      "&. と ||= と &&=" => [ "a&.b\n    x ||= 1\n    y &&= 2", 4 ],
      "&. を使わない呼び出し" => [ "a.b.c", 1 ]
    }.each do |label, (body, complexity)|
      it "#{label}を数える" do
        rows = rows_for("def target\n    #{body}\n  end\n", [ 1 ])

        expect(rows.first.complexity).to eq(complexity)
      end
    end

    it "入れ子のdefは外側のメソッドに数えない" do
      code = "def outer\n  def inner\n    a ? 1 : 2\n  end\nend\n"

      rows = rows_for(code, [ 1, 1, 0, nil, nil ])

      expect(rows.to_h { [ _1.name, _1.complexity ] }).to eq("Object#outer" => 1, "Object#inner" => 2)
    end
  end

  describe "CRAP-04 #rows の名前と位置" do
    it "クラス、モジュール、特異メソッドを区別して名前を付け、入れ子を抜けたら元に戻す" do
      code = <<~RUBY
        module Shop
          class Cart
            def total; end
            def self.build; end

            class << self
              def empty; end
            end

            def after_singleton; end

            class Item
              def price; end
            end

            def after_item; end
          end
        end

        def top_level; end
      RUBY

      rows = rows_for(code, Array.new(20, 1))

      expect(rows.map(&:name)).to contain_exactly(
        "Shop::Cart#total", "Shop::Cart.build", "Shop::Cart.empty", "Shop::Cart#after_singleton",
        "Shop::Cart::Item#price", "Shop::Cart#after_item", "Object#top_level"
      )
    end

    it "ファイルと開始行、終了行を持つ" do
      source = write_source("located.rb", "class A\n  def b\n    1\n  end\nend\n")
      resultset = write_resultset("RSpec" => { source => [ 1, 1, 1, nil, nil ] })

      row = described_class.new(paths: [ source ], resultset_path: resultset).rows.first

      expect(row.location).to eq("#{source}:2-4")
    end

    it "相対パスで渡してもカバレッジを引ける" do
      source = write_source("relative.rb", "def target\n  1\nend\n")
      resultset = write_resultset("RSpec" => { source => [ 1, 1, nil ] })

      row = Dir.chdir(dir) { described_class.new(paths: [ "relative.rb" ], resultset_path: resultset).rows.first }

      expect([ row.location, row.coverage ]).to eq([ "relative.rb:1-3", 1.0 ])
    end
  end

  describe "CRAP-03 #rows のカバレッジ" do
    let(:code) { "def target(a)\n  if a\n    1\n  else\n    2\n  end\nend\n" }

    it "読み込み時に実行されるdefの行を除き、メソッド本体で実行された行の割合を使う" do
      row = rows_for(code, [ 1, 1, 1, nil, 0, nil, nil ]).first

      aggregate_failures do
        expect(row.coverage).to eq(2.0 / 3)
        expect(row.crap).to eq(described_class.crap(2, 2.0 / 3))
      end
    end

    it "メソッドの終わりより後ろの行は数えない" do
      code = "def first\n  1\nend\ndef second\n  2\nend\n"

      rows = rows_for(code, [ 1, 1, nil, 0, 0, nil ])

      expect(rows.to_h { [ _1.name, _1.coverage ] }).to eq("Object#first" => 1.0, "Object#second" => 0.0)
    end

    it "1行で書いたメソッドはその行を使う" do
      row = rows_for("def target = 1\n", [ 0 ]).first

      expect(row.coverage).to eq(0.0)
    end

    it "複数の計測結果は行ごとに足し合わせる" do
      source = write_source("merged.rb", code)
      resultset = write_resultset(
        "RSpec" => { source => [ 1, 1, 1, nil, 0, nil, nil ] },
        "Other" => { source => [ 1, 1, 0, nil, 0, nil, nil ] }
      )

      row = described_class.new(paths: [ source ], resultset_path: resultset).rows.first

      expect(row.coverage).to eq(2.0 / 3)
    end

    it "SimpleCovのマージ期限を過ぎた計測結果も読む" do
      source = write_source("old.rb", code)
      path = dir.join(".resultset.json")
      path.write(JSON.generate("RSpec" => {
        "coverage" => { source => { "lines" => [ 1, 1, 1, nil, 1, nil, nil ] } },
        "timestamp" => Time.now.to_i - (SimpleCov.merge_timeout + 60)
      }))

      row = described_class.new(paths: [ source ], resultset_path: path.to_s).rows.first

      expect(row.coverage).to eq(1.0)
    end

    it "計測対象にないファイルはカバレッジ0として扱う" do
      source = write_source("untracked.rb", code)

      row = described_class.new(paths: [ source ], resultset_path: write_resultset("RSpec" => {})).rows.first

      expect(row.coverage).to eq(0.0)
    end

    it "実行対象の行がないメソッドはカバレッジ100%として扱う" do
      row = rows_for("def target\nend\n", [ nil, nil ]).first

      expect(row.coverage).to eq(1.0)
    end

    it "CRAP-06 resultsetがなければ場所と対処を示して止める" do
      missing = dir.join("missing.json").to_s

      expect {
        described_class.new(paths: [], resultset_path: missing).rows
      }.to raise_error(CrapMetrics::MissingCoverage, "#{missing} がありません。先に bundle exec rspec を実行してください")
    end
  end

  describe "CRAP-07 #rows のflogスコア" do
    it "同じ位置のメソッドのflogスコアを並べ、flogが数えないメソッドは0にする" do
      code = "class A\n  attr_reader :x\n\n  def b(x)\n    x.foo.bar\n  end\n\n  def c; end\nend\n"

      rows = rows_for(code, [ 1, 1, nil, 1, 1, nil, nil, 1, nil ])

      aggregate_failures do
        expect(rows.find { _1.name == "A#b" }.flog).to be > 0
        expect(rows.find { _1.name == "A#c" }.flog).to eq(0.0)
      end
    end
  end

  describe "CRAP-05 #rows の並び" do
    it "CRAP値の大きい順に並べる" do
      code = "def simple\n  1\nend\n\ndef branchy(a)\n  a ? 1 : 2\nend\n"

      rows = rows_for(code, [ 1, 1, nil, nil, 1, 0, nil, nil ])

      expect(rows.map(&:name)).to eq(%w[Object#branchy Object#simple])
    end
  end
end
