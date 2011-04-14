require 'ostruct'

module Trader
  class Rate < OpenStruct
        
    def ==(other)
      from == other.from && to == other.to && conversion == other.conversion
    end
    
    def matches(conditions)
      conditions.keys.all? {|condition| self.send(condition) == conditions[condition]}
    end
    
  end
end