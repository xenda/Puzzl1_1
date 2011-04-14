require 'xmlsimple'

module Trader
  class ConversionRates
    
    @@rates = []
    @@rates_tree = {}

    class << self
      
      def teardown
        @@rates = []
        @@rates_tree = {}
      end
      
      def parse(filename)
        
        # loads the structure from XML 
        parse_structure = XmlSimple.xml_in(filename)
      
        # creates Rates objects from adjusted and converted data and assigns to cval @@rates
        parse_structure['rate'].each do |rate|
      
                  from = rate["from"][0]
                    to = rate["to"][0]
            conversion = BigDecimal(rate["conversion"][0])
      
          @@rates << Trader::Rate.create(:from => from ,:to => to, :conversion => conversion)
      
        end
        
        # computes de rates_tree, showing all the possible iterations and existing relations 
        # also, adds missing rates (if there's USD -> CAD but no CAD ->, it creates it)
        compute_rates_tres
        fill_missing_rates
        
        # returns the created rates
        @@rates
        
      end

      def add_rate(rate)
        @@rates << rate unless @@rates.include? rate
        compute_rates_tres
        fill_missing_rates
      end

      def get(conditions)
        from,to = conditions[:from], conditions[:to]
        
        # original condition. Ex. AUD -> USD, original would be AUD
        base = conditions[:base]
        base ||= from
        
        if rate_tree[from].include? to
          # if a rate for that target exists, return it
          return get_rate(from,to)
        else
          # if not, try to derive it from each existing targets (Ex. targets from AUD)
          # also, removes if the original currency is part of one of the targets
          # or DOOM happens
          rate_tree[from].reject{|r| r == base }.each do |base|
            # get the next one till the target currency is met
            rate = get(:from => base,:to => to, :base => from)
            # multiply the rates to get a final one
            return rate * get_rate(from,base)
          end
        end
        # if none exists, 
        return BigDecimal("0")
      end

      def get_rate(from,to)
        # gets the rate from the array
        rates = @@rates.select{|rate| rate.from == from && rate.to == to }
        # if there were found, return the first - only - one 
        # if not, return 0
        unless rates.empty?
          rates.first.conversion
        else
          0.00
        end
      end

      def compute_rates_tres
        # iterate through each rate and create a sort-of tree structure of 
        # all the source currency and their targets existing conversions
        @@rates.each do |rate|
          # if the root doesn't exists, initialize it
          unless @@rates_tree[rate.to]
            @@rates_tree[rate.to] = []
          end
          unless @@rates_tree[rate.from]
            @@rates_tree[rate.from] = []
          end
          @@rates_tree[rate.from] << rate.to unless @@rates_tree[rate.from].include? rate.to
          @@rates_tree[rate.to] << rate.from unless @@rates_tree[rate.to].include? rate.from  
        end
        @@rates_tree
      end
      
      def rate_tree
        @@rates_tree ||= compute_rates_tres
      end
      
      def fill_missing_rates
        
        # Iterate through the rates, creating missing ones
        # if USD -> CAD exists, it will attempt to create CAD -> USD
        complete_match = @@rates.map{|rate| @@rates.select {|r| r.from == rate.to && r.to == rate.from  } }.flatten.compact
        missing = @@rates - complete_match
        # create missing rates
        missing.each do |rate|

                  from = rate.to
                    to = rate.from
            conversion = (1/rate.conversion)
            
          @@rates << Trader::Rate.create(:from => from, :to => to, :conversion => conversion)
        end
        
      end

      def rates
        @@rates
      end
      
    end

  end  
end