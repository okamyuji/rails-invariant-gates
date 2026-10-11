class User
  attr_reader :age

  def initialize(age:)
    @age = age
  end

  def adult?
    age >= 18
  end
end
