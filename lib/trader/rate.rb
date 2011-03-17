module Trader
  class Rate

    attr_accessor :from, :to, :conversion
  
    def self.create(attributes)
      rate = Rate.new
      attributes.keys.each do |a|
        rate.send("#{a}=",attributes[a])
      end
      rate
    end
        
    def ==(other)
      from == other.from && to == other.to && conversion == other.conversion
    end
    
    def matches(conditions)
      conditions.keys.all? {|condition| self.send(condition) == conditions[condition]}
    rescue 
      false
    end
    
  end
end