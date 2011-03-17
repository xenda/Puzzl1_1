require 'xmlsimple'

module Trader
  class ConversionRates
    
    @@rates = []
    @@rates_tree = {}

    class << self

      def parse(filename)
        filename << ".xml" unless filename =~ /\.xml/
        parse_structure = XmlSimple.xml_in(filename)
        parse_structure['rate'].each do |rate|
          rate = Trader::Rate.create(:from => rate["from"][0] ,:to => rate["to"][0], :conversion => BigDecimal(rate["conversion"][0]))
          @@rates << rate
        end
        fill_missing
        @@rates
      end

      def add_rate(rate)
        @@rates << rate #unless @@rates.include? rate
        fill_missing
      end

      def get(conditions)
        from,to = conditions[:from], conditions[:to]
        base = conditions[:base]
        base ||= from
        if rate_tree[from].include? to
          return get_rate(from,to)
        else
          rate_tree[from].reject{|r| r == base }.each do |base|
            rate = get(:from => base,:to => to, :base => from)
            return (rate * get_rate(from,base))
          end
        end
        return 0
      rescue Exception => ex
        puts ex.message
        puts ex.backtrace
        nil
      end

      def get_rate(from,to)
        rates = @@rates.select{|rate| rate.from == from && rate.to == to }
        if rates
          rate = rates
          rate = rates.first if rates.respond_to? :first
          rate.conversion
        else
          0.00
        end
      rescue Exception => ex
        puts ex.message
        0
      end

      def fill_missing
        fill_missing_pairs
        map_rates_routes
      end
      
      def map_rates_routes
        # iterate through each rate and create hash nodes there
        @@rates.each do |rate|
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
        @@rates_tree ||= map_rates_routes
      end
      
      def fill_missing_pairs
        # Iterate through the rates, if it's missing, create it
        complete_match = @@rates.map{|rate| @@rates.select {|r| r.from == rate.to && r.to == rate.from  } }.flatten.compact
        missing = @@rates - complete_match
        # create missing rates
        missing.each do |rate|
          @@rates << Trader::Rate.create(:from => rate.to, :to => rate.from, :conversion => (1/rate.conversion.to_f).round(4))
        end
        
      end

      def rates
        @@rates
      end

      def teardown
        @@rates = []
        @@rates_tree = {}
      end


      
    end


  end
  
  
end