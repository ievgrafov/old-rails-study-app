class Order < ActiveRecord::Base
	has_many :cart_items
  belongs_to :payment, polymorphic: true

  include Countable

	validates_associated :cart_items

	validates :email,
            :name,
            :country,
            :state,
            :city,
            :address_line_1,
            :postal_code,
        	  presence: true,
            length: { minimum: 2 }

  validates_format_of :email,
    with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i,
    message: "Doesn't look like an email address"

  def paid?
    !payment.nil?
  end

  def paypal_items
    self.cart_items.map do |cart_item|
      product = cart_item.product
      { 
        :name => product.title,
        :description => product.description,
        :quantity => cart_item.count,
        :amount => cart_item.total * 100
      }
    end
  end
end