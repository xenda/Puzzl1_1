$:.unshift File.join(File.dirname(__FILE__),'lib')
require 'trader'

Trader::TransactionRecords.parse("TRANS")
Trader::ConversionRates.parse("RATES")        
result = Trader::TransactionRecords.get_total_for_product("DM1182","USD").to_s("F")

File.open("OUTPUT.txt", 'w'){|f| f.write(result+"\n") }
