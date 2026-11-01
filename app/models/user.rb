class User
  # evilutionは変異を既存のクラスへ重ねて読み込むため、attr_readerを消す変異は元のメソッドが残り区別できない。
  attr_reader :age # evilution:disable

  def initialize(age:)
    @age = age
  end

  def adult?
    age >= 18
  end
end
