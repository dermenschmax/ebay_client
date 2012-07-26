require "ebay/trading/ebay_client"


describe Ebay::Trading::EbayClient do
  
  
  before :each do
    wsdl_file_name = File.expand_path("wsdl/trading/ebay_trading_v777.wsdl")
    Ebay::Trading::EbayClient.wsdl_file_name = wsdl_file_name
    @client = Ebay::Trading::EbayClient.new
  end
  
  
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
    @client.should_not be_nil
    
    @client.operations.should_not be_nil
    @client.operations.should include(:get_categories)
    @client.operations.should include(:add_item)
  end
  
  
  it "should list operations with action, input, namespace and output" do
    @client.should_not be_nil
    
    op = @client.operations
    op.should_not be_nil
    
    get_categories = op[:get_categories]
    get_categories.should_not be_nil
    
    get_categories[:action].should_not be_nil
    get_categories[:input].should_not be_nil
    get_categories[:namespace_identifier].should_not be_nil
    get_categories[:output].should_not be_nil
  end
  
  
  it "should generate wsdl types" do
    wsdl_type_name = @client.operations[:get_categories][:input]
    wsdl_type = @client.generate_type(wsdl_type_name)
    
    wsdl_type.should_not be_nil
  end
  
end
