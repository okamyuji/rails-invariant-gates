require "rails_helper"

RSpec.describe User do
  describe "#adult?" do
    it "20歳なら成人である" do
      expect(User.new(age: 20).adult?).to eq(true)
    end

    it "18歳ちょうどなら成人である" do
      expect(User.new(age: 18).adult?).to eq(true)
    end

    it "17歳なら成人ではない" do
      expect(User.new(age: 17).adult?).to eq(false)
    end
  end
end
