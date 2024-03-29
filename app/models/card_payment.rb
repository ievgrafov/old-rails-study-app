class CardPayment < ActiveRecord::Base
  require "active_merchant/billing/rails"

  has_one :order, as: :payment

  attr_accessor :card_security_code
  attr_reader :credit_card_number
  def credit_card_number=(ccn)
    self.last4 = "*#{ccn[-4..-1]}"
    @credit_card_number = ccn
  end
  attr_accessor :expiration_month
  attr_accessor :expiration_year

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :card_security_code, presence: true
  validates :credit_card_number, presence: true
  validates :expiration_month, presence: true, numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: 12 }
  validates :expiration_year, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }

  validate :valid_card

  def credit_card
    ActiveMerchant::Billing::CreditCard.new(
      number:              credit_card_number,
      verification_value:  card_security_code,
      month:               expiration_month,
      year:                expiration_year,
      first_name:          first_name,
      last_name:           last_name
    )
  end

  def valid_card
    unless credit_card.valid?
      errors.add(:base, "The credit card information you provided is not valid.  Please double check the information you provided and then try again.")
      false
    else
      true
    end
  end

  def process(order, p_ip)
    if valid_card
      response = CARD_GATEWAY.authorize(amount * 100, credit_card)
      if response.success?
        transaction = CARD_GATEWAY.capture(amount * 100, credit_card)
        unless transaction.success?
          errors.add(:base, "The credit card you provided was declined.  Please double check your information and try again.") and return
          return false
        end
        update_columns({authorization_code: transaction.authorization, success: true})
        order.update_attributes(payment: self, purchased_at: Time.now, ip: p_ip)
        true
      else
        errors.add(:base, "Gateway returned bad response. Please try again later.") and return
        false
      end
    end
  end
end
