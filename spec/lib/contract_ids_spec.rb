require "rails_helper"

RSpec.describe ContractIds do
  describe "IDS-01 .table_ids" do
    it "表の行の先頭の列にあるIDだけを読み取る" do
      table = <<~MD
        | ID | 契約 |
        |---|---|
        | INV-01 | 在庫数は負にならない |
        | SHIP-03 | 0円以下は例外 |

        INV-02 のように文中に書いたIDは数えない。
        | 契約 | INV-03 |
      MD

      expect(described_class.table_ids(table)).to eq(%w[INV-01 SHIP-03])
    end

    it "表の行がなければ空の配列を返す" do
      expect(described_class.table_ids("| ID | 契約 |\n|---|---|\n")).to eq([])
    end
  end

  describe "IDS-02 .references" do
    it "名前に書いた複数のIDを読み取る" do
      expect(described_class.references("API-03 在庫1個 CON-01 成功は1件")).to eq(%w[API-03 CON-01])
    end

    it "スラッシュで続けた番号を同じ接頭辞のIDとして数える" do
      expect(described_class.references("POST-01/02/03 指定数量だけ移動する")).to eq(%w[POST-01 POST-02 POST-03])
    end

    it "番号が1桁や3桁のものはIDとして数えない" do
      expect(described_class.references("UTF-8 と AB-001 と AB-1")).to eq([])
    end

    it "IDがなければ空の配列を返す" do
      expect(described_class.references("20歳なら成人である")).to eq([])
    end
  end

  describe "IDS-03 .check" do
    let(:table) { "| INV-01 | a |\n| INV-02 | b |\n" }

    it "表とspecの名前が対応していれば、どの一覧も空になる" do
      result = described_class.check(table:, descriptions: [ "INV-01 x", "INV-02 y" ])

      expect(result).to eq(unnamed: [], unknown: [], uncovered: [])
    end

    it "IDのないspec、表にないID、specのない行をそれぞれ返す" do
      result = described_class.check(table:, descriptions: [ "INV-01 x", "名前だけ", "ADULT-01 z" ])

      expect(result).to eq(unnamed: [ "名前だけ" ], unknown: [ "ADULT-01" ], uncovered: [ "INV-02" ])
    end

    it "IDのあるspecが1つもなければ、すべての名前を返す" do
      result = described_class.check(table:, descriptions: [ "名前だけ", "これも名前だけ" ])

      expect(result).to eq(unnamed: [ "名前だけ", "これも名前だけ" ], unknown: [], uncovered: %w[INV-01 INV-02])
    end

    it "同じIDを複数のspecが使っても1回だけ数える" do
      result = described_class.check(table:, descriptions: [ "ADULT-01 x", "ADULT-01 y", "INV-01/02 z" ])

      expect(result).to eq(unnamed: [], unknown: [ "ADULT-01" ], uncovered: [])
    end
  end
end
