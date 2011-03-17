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
        # puts records.inspect
        return records unless currency
        wrong_currency = records.select{|t| t.currency != currency }
        transformed_currencies = wrong_currency.map {|t| t.send("to_#{currency}_currency") }
        records = records - wrong_currency + transformed_currencies
        # puts records.inspect
        records
      end
      
      def get_total_for_product(product_sku,currency=false)
        transactions = get_for_product(product_sku,currency)
        total = (transactions.inject(0){|total,t| total + t.amount_in_cents})/100.0
      end
      
      def parse(file)
        collection = load_from_file(file)
        @@transactions = collection.map do |trans|
                            amount, currency = parse_currency(trans[:amount])
                            Transaction.create(:store => trans[:store], :sku => trans[:sku], :amount_in_cents => to_cents(amount), :currency => currency)
                          end
      end

      def to_cents(amount)
        (amount.to_f * 100 ).to_i
      end

      def parse_currency(currency)
        # puts currency
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