require "ebay/trading/ebay_client"


describe Ebay::Trading::EbayClient do
  
  
  it "should create an instance of the client" do
    ec = Ebay::Trading::EbayClient.new
    ec.should_not be_nil
  end
  
  
  it "should set the wsdl_file_name as class instance variable" do
    
    wsdl_file_name = File.expand_path("wsdl/trading/ebay_trading_v777.wsdl")
    Ebay::Trading::EbayClient.wsdl_file_name = wsdl_file_name
    
    Ebay::Trading::EbayClient.wsdl_file_name.should be_equal wsdl_file_name
    
  end
  
  
  it "should list the soap operations of the wsdl" do
    client = Ebay::Trading::EbayClient.new
    client.should_not be_nil
    
    client.operations.should_not be_nil
    client.operations.should include(:get_categories)
    client.operations.should include(:add_item)
    puts client.operations
  end
  
  
  
  
end
