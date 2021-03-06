$:.unshift File.join(File.dirname(__FILE__),'../lib')
$:.unshift File.join(File.dirname(__FILE__),'..')

require 'trader'
require 'test/unit'

class TestTransactionalAggregator < Test::Unit::TestCase

  def setup
    Trader::ConversionRates.teardown
    Trader::TransactionRecords.teardown
  end
  
  def test_missing_rates_are_derived
    rate = Trader::Rate.create(:from => "USD",:to => "PEN", :conversion => 2.8)    
    Trader::ConversionRates.add_rate(rate)
    rate2 = Trader::Rate.create(:from => "PEN",:to => "ARG", :conversion => 1.8)    
    Trader::ConversionRates.add_rate(rate2)
    rate3 = Trader::Rate.create(:from => "ARG",:to => "BER", :conversion => 0.5)
    Trader::ConversionRates.add_rate(rate3)
    assert_equal BigDecimal("2.52"), Trader::ConversionRates.get(:from => "USD", :to => "BER")                
  end
  
  def test_loading_rates_from_xml
    Trader::ConversionRates.parse("SAMPLE_RATES.xml")
    rate = Trader::Rate.create(:from => "AUD",:to => "CAD", :conversion => 1.0079)
    assert_equal rate, Trader::ConversionRates.rates.first
  end

  def test_deriving_rate
    Trader::ConversionRates.parse("SAMPLE_RATES.xml")
    assert_equal BigDecimal("1.0169711"), Trader::ConversionRates.get(:from => "AUD", :to => "USD")
  end

  def test_deriving_real_rate
    Trader::ConversionRates.parse("RATES.xml")
    assert_equal BigDecimal("1.0169711"), Trader::ConversionRates.get(:from => "AUD", :to => "USD")
    assert_equal BigDecimal("1.009"), Trader::ConversionRates.get(:from => "CAD", :to => "USD")  
    assert_equal BigDecimal("1.36701255262"), Trader::ConversionRates.get(:from => "EUR", :to => "USD")
  end

  def test_loading_transactions_from_csv
    transaction = {:store => "Yonkers", :sku => "DM1210", :amount => "70.00 USD" }
    collection = Trader::TransactionRecords.load_from_file("SAMPLE_TRANS")
    assert_equal transaction, collection.first
  end
  
  def test_loading_transactions_from_csv
    collection = Trader::TransactionRecords.load_from_file("TRANS.csv")
    assert_equal 10000, collection.size
  end
  
  def test_loading_currency_from_csv
    collection = Trader::TransactionRecords.parse("SAMPLE_TRANS.csv")
    transaction = collection.first
    assert_equal BigDecimal("70"), transaction.amount
    assert_equal "USD", transaction.currency
  end
  
  def test_convert_transaction_from_one_to_another
    Trader::ConversionRates.parse("SAMPLE_RATES.xml")    
    transaction = Trader::Transaction.create(:store => "Demo", :sku => "DM123", :amount => 1230, :currency => "USD")
    assert_equal BigDecimal("1219.05"), transaction.exchange_to("CAD").amount
  end

  def test_getting_total_amount_from_project
    Trader::TransactionRecords.parse("SAMPLE_TRANS.csv")
    Trader::ConversionRates.parse("SAMPLE_RATES.xml")        
    assert_equal BigDecimal("134.22"), Trader::TransactionRecords.get_total_for_product("DM1182","USD")
  end
  
  def test_getting_real_total_amount_from_project
    Trader::TransactionRecords.parse("TRANS.csv")
    Trader::ConversionRates.parse("RATES.xml")   
    assert_equal BigDecimal("59482.02"), Trader::TransactionRecords.get_total_for_product("DM1182","USD")
  end  

end
