class CardPaymentsController < ApplicationController
  before_filter :authenticate_admin!, only: [:index]
  before_action :set_order, only: [:new, :create]

  def index
    @payments = CardPayment.all
  end

  def new
    @payment = CardPayment.new
    render 'new'
  end

  def create
    card_payment_params = card_params.merge(amount: @order.total)
    @payment = CardPayment.new(card_payment_params)

    if @payment.save
      if @payment.process
        redirect_to store_path, notice: "Order succesfully paid." and return
      end
    end
    render 'new'
  end

private
  def card_params
    params.require(:card_payment).permit(:first_name, :last_name, :credit_card_number, :expiration_month, :expiration_year, :card_security_code)
  end
end