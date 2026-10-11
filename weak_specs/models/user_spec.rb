require "rails_helper"

RSpec.describe User do
  describe "#adult?" do
    it "20歳なら成人である" do
      user = User.new(age: 20)

      expect(user.adult?).to eq(true)
    end

    it "15歳なら成人ではない" do
      user = User.new(age: 15)

      expect(user.adult?).to eq(false)
    end
  end
end
