$:.unshift File.join(File.dirname(__FILE__),'lib')

require 'trader'

Trader.parse_transaction_records("TRANS.csv")
Trader.parse_conversion_rates("RATES.xml")     

result = Trader.get_total_for_product("DM1182","USD").to_s("F")


File.open("OUTPUT.txt", 'w'){|f| f.write(result+"\n") }
