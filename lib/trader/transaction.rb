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
      puts self.currency
      puts target_currency
      conversion = ConversionRates.get(:from => self.currency, :to => target_currency).conversion

      self.class.class_eval do
        define_method(method) do
          Transaction.create(:store => self.store, :sku => self.sku, :amount_in_cents => (self.amount_in_cents * conversion).round(4), :currency => target_currency)
        end

      end

      send(method,*args).amount_in_cents

    end
    
  end
end