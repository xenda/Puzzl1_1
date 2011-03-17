module Trader
  class Transaction
    
    attr_accessor :store, :sku, :amount_in_cents, :currency
        
    def self.create(attributes)
      transaction = Transaction.new
      attributes.keys.each do |a|
        transaction.send("#{a}=",attributes[a])
      end
      transaction
    end
    
    def method_missing(method,*args)
      super unless method =~/to_(.*)_currency/
      target_currency = $1.upcase
      # puts "Searching #{self.currency} - #{target_currency}"
      conversion = ConversionRates.get(:from => self.currency, :to => target_currency)

      self.class.class_eval do
        define_method(method) do

          # puts conversion
          # puts amount_in_cents
          amount_in_cents = BigDecimal((self.amount_in_cents * conversion).to_s).round(2,BigDecimal::ROUND_HALF_EVEN).to_i

          Transaction.create(:store => self.store, :sku => self.sku, :amount_in_cents => amount_in_cents, :currency => target_currency)
        end

      end

      send(method,*args)

    end
    
  end
end