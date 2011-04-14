require 'csv'

module Trader
  class TransactionRecords
    
    @transactions = []
    
    class << self
      
      def teardown
        @transactions = []
      end
      
      def parse(file)
      
        # we load all the transactions in an array
        collection = load_from_file(file)
        
        @transactions = collection.map do |trans|

                          # make some adjustments to the values (parsing, etc)
                          amount, currency = parse_currency(trans[:amount])
                                    amount = BigDecimal(amount)
                                     store = trans[:store]
                                       sku = trans[:sku]
                                      
                          # and we create the transaction
                          Transaction.new(:store => store, :sku => sku, :amount => amount, :currency => currency)

                          end
      end

      def parse_currency(currency)

        # Matches the transaction amount. From 70.00 USD to ["70.00","USD"]
        if currency =~ /(\d{2}\.\d{2})\s(\D{2,3})/
          [$1.to_s,$2]
        else
          # if there isn't anything, return 0.00 with no currency
          ["0.00",""]
        end

      end
      
      def load_from_file(file)
        
        transactions = []

        # iterating through the csv rows, adding a new hash representing the operation to the transactioons array
        CSV.foreach(file, :headers => true) do |row|
           transactions << row.headers.inject({}) {|result,data| result[data.to_sym] = row[data]; result}
         end

         return transactions

      end      
      
      
      def get_total_for_product(product_sku,currency=false)

        # get all the records from the sku
        records = @transactions.select{|transaction| transaction.sku == product_sku}

        # if no currency is asked, returned it as it
        return records unless currency
        
        # removes already there transactions and saves it for later
        currency_records = records.select{|t| t.currency == currency }
        records -= currency_records
        
        # get all the existing other currencies
        target_currencies = records.map(&:currency).inject([]) {|result,r| result << r unless result.include? r; result  }
        
        pre_totals = target_currencies.map do |target_currency|
        
          # get the conversion
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