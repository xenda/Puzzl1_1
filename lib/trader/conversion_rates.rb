require 'xmlsimple'

module Trader
  class ConversionRates

    @@rates = []
    @@rate_tree []
    
    class << self

      def parse(filename)
        filename << ".xml" unless filename =~ /\.xml/
        parse_structure = XmlSimple.xml_in(filename)
        parse_structure['rate'].each do |rate|
          rate = Trader::Rate.create(:from => rate["from"][0] ,:to => rate["to"][0], :conversion => rate["conversion"][0].to_f)
          @@rates << rate
        end
        fill_missing
        @@rates
      end

      def add_rate(rate)
        @@rates << rate unless @@rates.include? rate
        fill_missing
      end

      def get(conditions)
        return nil unless possible_routes(conditions)
        create_missing_routes
        rate = @@rates.select{|rate| rate.matches(conditions)}.first
      rescue
        nil
      end

      def fill_missing
        fill_missing_pairs
      end
      
      def possible_routes(conditions)
        # if a exiting rate is there, return it. Queue is empty
        return true if @@rates.any?{|rate| rate.matches(conditions) }
        # iterate through each off them and see if there is something missing
        @@rates.each do |rate|
          
        end
      end
      
      def fill_missing_pairs
        # Iterate through the rates, if it's missing, create it
        complete_match = @@rates.map{|rate| @@rates.select {|r| r.from == rate.to && r.to == rate.from  } }.flatten.compact
        missing = @@rates - complete_match
        # create missing rates
        missing.each do |rate|
          @@rates << Trader::Rate.create(:from => rate.to, :to => rate.from, :conversion => (1/rate.conversion).round(4))
        end
        
      end

      def rates
        @@rates
      end

      def teardown
        @@rates = []
      end


      
    end


  end
  
  
end