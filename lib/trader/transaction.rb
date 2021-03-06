module Trader
  class Transaction
    
    attr_accessor :store, :sku, :amount, :currency
        
    def self.create(attributes)
      transaction = Transaction.new
      attributes.keys.each do |a|
        transaction.send("#{a}=",attributes[a])
      end
      transaction
    end

    # returns an updated version of itself with the adjusted conversion
    def exchange_to(currency)
      return amount if self.currency == currency
      conversion = ConversionRates.get(:from => self.currency, :to => currency)
      self.amount = (self.amount * conversion).round(2,BigDecimal::ROUND_HALF_EVEN)
      self
    end
  
  end
end