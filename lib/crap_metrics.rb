require "prism"
require "flog"
require "simplecov"

# メソッドごとのCRAP値を計算する。
# CRAP(m) = comp(m)^2 * (1 - cov(m))^3 + comp(m)
# comp はPrismで数えた循環的複雑度、cov はSimpleCovの行カバレッジ。
class CrapMetrics
  class MissingCoverage < StandardError; end

  # キーワード引数でしか作らないため、メンバーの並び順を入れ替える変異は振る舞いを変えない。
  Row = Data.define(:name, :location, :complexity, :coverage, :crap, :flog) # evilution:disable

  BRANCH_NODES = [
    Prism::IfNode, Prism::UnlessNode, Prism::WhileNode, Prism::UntilNode, Prism::ForNode,
    Prism::WhenNode, Prism::InNode, Prism::RescueNode, Prism::RescueModifierNode,
    Prism::AndNode, Prism::OrNode
  ].freeze

  def self.crap(complexity, coverage)
    complexity**2 * (1 - coverage)**3 + complexity
  end

  def self.report(rows, threshold:, io:)
    io.puts format("%8s  %s  %s  %6s  %s", "CRAP", "複雑度", "カバレッジ", "flog", "メソッド")
    rows.each do |row|
      io.puts format("%8.2f  %6d  %8.1f%%  %6.2f  %s (%s)",
                     row.crap, row.complexity, row.coverage * 100, row.flog, row.name, row.location)
    end
    offenders = rows.reject { it.crap < threshold }
    # 配列のsizeとlengthは同じ値を返すため、入れ替える変異は区別できない。
    total, over = rows.size, offenders.size # evilution:disable
    io.puts "メソッド数: #{total} / CRAP値が#{format("%g", threshold)}以上: #{over}"
    offenders
  end

  def initialize(paths:, resultset_path:)
    @paths = paths
    @resultset_path = resultset_path
  end

  def rows
    coverage = line_coverage
    flog = flog_scores

    all_rows = @paths.flat_map { |path| rows_in(path, coverage[File.expand_path(path)], flog) }
    # flat_mapが作った配列なので、sort_by!に置き換えても返す値は同じになる。
    all_rows.sort_by { -it.crap } # evilution:disable
  end

  private

  def rows_in(path, lines, flog)
    # ブロックがRowを返すため、mapをflat_mapやmap!に置き換えても返す値は同じになる。
    collect_defs(Prism.parse_file(path).value).map do |name, node| # evilution:disable
      location = "#{path}:#{node.start_line}-#{node.end_line}"
      complexity = 1 + decisions_in(node.body)
      ratio = coverage_ratio(node, lines)

      Row.new(name:, location:, complexity:, coverage: ratio,
              crap: self.class.crap(complexity, ratio), flog: flog.fetch(location, 0.0))
    end
  end

  # prefix は "Shop::Cart#" のように、所有者と区切りをつないだ文字列。
  # トップレベルのdefはObjectのprivateメソッドになる。
  def collect_defs(node, prefix = "Object#")
    owner = prefix.chop
    case node
    when Prism::ClassNode, Prism::ModuleNode
      name = node.constant_path.slice
      defs_below(node, owner == "Object" ? "#{name}#" : "#{owner}::#{name}#")
    when Prism::SingletonClassNode
      defs_below(node, "#{owner}.")
    when Prism::DefNode
      [ [ "#{node.receiver ? "#{owner}." : prefix}#{node.name}", node ], *defs_below(node, prefix) ]
    else
      defs_below(node, prefix)
    end
  end

  def defs_below(node, prefix)
    node.compact_child_nodes.flat_map { collect_defs(it, prefix) }
  end

  # 入れ子のdefは別のメソッドとして数える。
  def decisions_in(node)
    return 0 if node.nil?
    return 0 if node.instance_of?(Prism::DefNode)

    (decision?(node) ? 1 : 0) + node.compact_child_nodes.sum { decisions_in(it) }
  end

  def decision?(node)
    return true if BRANCH_NODES.include?(node.class)
    return true if node.instance_of?(Prism::CallNode) && node.safe_navigation?

    node.class.name.end_with?("OrWriteNode", "AndWriteNode")
  end

  # defの行はクラスの読み込み時に実行されるため、本体がある限り分母から外す。
  def coverage_ratio(node, lines)
    return 0.0 unless lines

    first = node.end_line > node.start_line ? node.start_line + 1 : node.start_line
    counts = lines[(first - 1)...node.end_line].compact
    return 1.0 if counts.empty?

    covered = counts.count(&:positive?)
    # 配列のsizeとlengthは同じ値を返すため、入れ替える変異は区別できない。
    covered.fdiv(counts.size) # evilution:disable
  end

  def line_coverage
    unless File.exist?(@resultset_path)
      raise MissingCoverage, "#{@resultset_path} がありません。先に bundle exec rspec を実行してください"
    end

    SimpleCov::ResultMerger.merge_results(@resultset_path, ignore_timeout: true)
                           .original_result.transform_values { it.fetch("lines") }
  end

  def flog_scores
    flog = Flog.new
    flog.flog(*@paths)
    flog.totals.to_h { |name, score| [ flog.method_locations[name], score ] }
  end
end
