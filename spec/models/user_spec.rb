require "rails_helper"

RSpec.describe User do
  it "ADULT-01/02 年齢を作成後に書き換えるメソッドを持たない" do
    expect(User.new(age: 20)).not_to respond_to(:age=)
  end

  describe "#adult?" do
    it "ADULT-01 20歳なら成人である" do
      expect(User.new(age: 20).adult?).to eq(true)
    end

    it "ADULT-01 19歳なら成人である" do
      expect(User.new(age: 19).adult?).to eq(true)
    end

    it "ADULT-01 18歳ちょうどなら成人である" do
      expect(User.new(age: 18).adult?).to eq(true)
    end

    it "ADULT-02 17歳なら成人ではない" do
      expect(User.new(age: 17).adult?).to eq(false)
    end

    it "ADULT-02 15歳なら成人ではない" do
      expect(User.new(age: 15).adult?).to eq(false)
    end
  end
end
