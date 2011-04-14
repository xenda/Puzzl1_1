require 'csv'

module Trader
  class TransactionRecords
    
    @transactions = []
    
    class << self
      
      attr_accessor :transactions
      
      def teardown
        @transactions = []
      end
      
      def parse(file)
      
        CSV.foreach(file, :headers => true) do |row|
          store, sku, transaction = *row.fields
          amount, currency = parse_currency(transaction)
          @transactions << Transaction.new(:store => store, :sku => sku, :amount => amount, :currency => currency)     
         end

      end

      # From 70.00 USD to ["70.00","USD"]
      def parse_currency(value)
        amount,currency = value.split(" ")
        [BigDecimal(amount),currency]
      end      
      
      def get_total_for_product(product_sku,currency=false)

        records = @transactions.select{|transaction| transaction.sku == product_sku}

        return records unless currency  # if no currency is asked, returned it as it
        
        # removes already converted transactions
        currency_records = records.select{|t| t.currency == currency }
        records -= currency_records
        
        # get all the existing other currencies
        target_currencies = records.map(&:currency).uniq
        
        pre_totals = target_currencies.map do |target_currency|
        
          conversion = ConversionRates.get(:from => target_currency, :to => currency)
          
          # for each currency, select the records, get their amounts and converse them
          pre_total = records.select{|r| r.currency == target_currency }.map(&:amount).map {|r| (r * conversion).round(2,BigDecimal::ROUND_HALF_EVEN) }

          # sum the results
          pre_total.inject(0){|s,i| s+i }

        end
        
        # gets the total of the currency records and adds them to the converted totals
        base_total = currency_records.map(&:amount).inject(0){|sum, t| sum + t}
        pre_total = pre_totals.inject(0){|sum,t| sum + t }
          
        total = base_total + pre_total

      end
    
    end    
    
  end
end