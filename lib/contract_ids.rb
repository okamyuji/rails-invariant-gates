# AGENTS.mdの契約の表の行と、specの名前に入れたIDを突き合わせる。
module ContractIds
  ROW = /^\| ([A-Z]+-\d{2}) \|/
  # POST-01/02/03 は POST-01、POST-02、POST-03 の3つを指す。
  REFERENCE = %r{\b([A-Z]+)-(\d{2}(?:/\d{2})*)\b}

  def self.table_ids(table)
    table.scan(ROW).flatten
  end

  def self.references(description)
    description.scan(REFERENCE).flat_map do |prefix, numbers|
      "#{prefix}-#{numbers.gsub("/", " #{prefix}-")}".split
    end
  end

  def self.check(table:, descriptions:)
    ids = table_ids(table)
    used = descriptions.flat_map { references(it) }.uniq

    {
      unnamed: descriptions.reject { references(it).any? },
      unknown: used - ids,
      uncovered: ids - used
    }
  end
end
