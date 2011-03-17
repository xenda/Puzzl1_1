$:.unshift File.join(File.dirname(__FILE__),'../lib')
$:.unshift File.join(File.dirname(__FILE__),'..')

require 'trader'
require 'test/unit'

class TestTransactionalAggregator < Test::Unit::TestCase

  def setup
    Trader::ConversionRates.teardown
    Trader::TransactionRecords.teardown
  end

  def test_missing_rates_are_created
    rate = Trader::Rate.create(:from => "USD",:to => "PEN", :conversion => 2.8)
    Trader::ConversionRates.add_rate(rate)
    assert_equal 0.3571, Trader::ConversionRates.get(:from => "PEN", :to => "USD")
  end
  
  def test_missing_rates_are_derived
    rate = Trader::Rate.create(:from => "USD",:to => "PEN", :conversion => 2.8)    
    Trader::ConversionRates.add_rate(rate)
    rate2 = Trader::Rate.create(:from => "PEN",:to => "ARG", :conversion => 1.8)    
    Trader::ConversionRates.add_rate(rate2)
    rate3 = Trader::Rate.create(:from => "ARG",:to => "BER", :conversion => 0.5)
    Trader::ConversionRates.add_rate(rate3)
    assert_equal 2.52, Trader::ConversionRates.get(:from => "USD", :to => "BER")                
  end
  
  def test_loading_rates_from_xml
    Trader::ConversionRates.parse("SAMPLE_RATES")
    rate = Trader::Rate.create(:from => "AUD",:to => "CAD", :conversion => 1.0079)
    assert_equal rate, Trader::ConversionRates.rates.first
  end

  def test_loading_real_rates_from_xml
    Trader::ConversionRates.parse("RATES")
    assert_equal 6, Trader::ConversionRates.rates.size
  end

  def test_deriving_rate
    Trader::ConversionRates.parse("SAMPLE_RATES")
    assert_equal 1.0169711, Trader::ConversionRates.get(:from => "AUD", :to => "USD")
  end


  
  def test_loading_transactions_from_csv
    transaction = {:store => "Yonkers", :sku => "DM1210", :amount => "70.00 USD" }
    collection = Trader::TransactionRecords.load_from_file("SAMPLE_TRANS")
    assert_equal transaction, collection.first
  end
  
  def test_loading_transactions_from_csv
    collection = Trader::TransactionRecords.load_from_file("TRANS")
    assert_equal 10000, collection.size
  end
  
  def test_loading_currency_from_csv
    collection = Trader::TransactionRecords.parse("SAMPLE_TRANS")
    transaction = collection.first
    assert_equal 7000, transaction.amount_in_cents
    assert_equal "USD", transaction.currency
  end
  
  def test_convert_transaction_from_one_to_another
    Trader::ConversionRates.parse("SAMPLE_RATES")    
    transaction = Trader::Transaction.create(:store => "Demo", :sku => "DM123", :amount_in_cents => 1230, :currency => "USD")
    assert_equal 1219, transaction.to_cad_currency.amount_in_cents
  end

  def test_getting_transactions_from_product
    Trader::TransactionRecords.parse("SAMPLE_TRANS")
    assert_equal 3, Trader::TransactionRecords.get_for_product("DM1182").size
  end
  
  def test_getting_transactions_from_product
    Trader::TransactionRecords.parse("TRANS")
    assert_equal 1010, Trader::TransactionRecords.get_for_product("DM1182").size
  end
  
  def test_getting_transactions_from_product_with_currency
    Trader::TransactionRecords.parse("SAMPLE_TRANS")
    Trader::ConversionRates.parse("SAMPLE_RATES")        
    assert_equal 3, Trader::TransactionRecords.get_for_product("DM1182","USD").size
  end

  def test_getting_transactions_from_product_with_currency
    Trader::TransactionRecords.parse("TRANS")
    Trader::ConversionRates.parse("RATES")        
    assert_equal 1010, Trader::TransactionRecords.get_for_product("DM1182","USD").size
    puts Trader::TransactionRecords.get_for_product("DM1182","USD").map{|i| [i.amount_in_cents, i.currency]}.inspect
  end


  def test_getting_total_amount_from_project
    Trader::ConversionRates.teardown
    Trader::TransactionRecords.teardown
    Trader::TransactionRecords.parse("SAMPLE_TRANS")
    Trader::ConversionRates.parse("SAMPLE_RATES")        
    assert_equal 134.22, Trader::TransactionRecords.get_total_for_product("DM1182","USD")
  end

end
