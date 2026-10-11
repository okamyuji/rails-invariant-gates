class PaymentService
  def initialize(amount:)
    @amount = amount
  end

  def charge
    PaymentGateway.charge(@amount)

    true
  end
end
