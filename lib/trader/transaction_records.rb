require 'csv'

module Trader
  class TransactionRecords
    
    @@transactions = []
    
    class << self
      
      def teardown
        @@transactions = []
      end
      
      def get_for_product(product_sku,currency=false)
        records = @@transactions.select{|transaction| transaction.sku == product_sku}
        return records unless currency
        
        # removes already there transactions
        currency_records = records.select{|t| t.currency == currency }
        base_total = currency_records.inject(0){|sum, t| sum + t.amount_in_cents}
        puts "#{currency}: #{base_total.to_f}"
        records -= currency_records
        
        target_currencies = []
        records.map(&:currency).each {|r| target_currencies << r unless target_currencies.include? r  }
        
        pre_totals = target_currencies.map do |target_currency|
        
          conversion = ConversionRates.get(:from => target_currency, :to => currency)
          puts "#{target_currency}-#{currency}: #{conversion}"
          pre_total = records.select{|r| r.currency == target_currency }.map(&:amount_in_cents).map do |r|
            # puts r
            res = (r * conversion).round(2,BigDecimal::ROUND_HALF_EVEN)
            # puts res.to_s("F")
            res
          end
          pre_total = pre_total.inject(0){|s,i| s+i }
          pre_total
        end
        
        pre_total = pre_totals.inject(0){|sum,t| sum + t }
        
        puts "Others: #{pre_total.to_s('F')}"
        total = base_total + pre_total

      end
      
      def get_total_for_product(product_sku,currency=false)
        get_for_product(product_sku,currency)
      end
      
      def parse(file)
        collection = load_from_file(file)
        @@transactions = collection.map do |trans|
                            amount, currency = parse_currency(trans[:amount])
                            Transaction.create(:store => trans[:store], :sku => trans[:sku], :amount_in_cents => parse_amount(amount), :currency => currency)
                          end
      end

      def parse_amount(amount)
        # (BigDecimal(amount).round(2,BigDecimal::ROUND_HALF_EVEN)) #  * 100 ) #.to_i
        BigDecimal(amount)
      end

      def parse_currency(currency)
        if currency =~ /(\d{2}\.\d{2})\s(\D{2,3})/
          [$1.to_s,$2]
        else
          ["0.00",""]
        end
      end

      def load_from_file(file)

        file << ".csv" unless file =~ /\.csv/ 
        transactions = []
        CSV.foreach(file, :headers => true) do |row|
           row_hash = {}
           row.headers.each do |i|
             row_hash[i.to_sym] = row[i]
           end
           transactions << row_hash
         end
         transactions
      end      
      
    end    
    
  end
end