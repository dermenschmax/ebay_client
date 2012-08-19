require "ebay/trading/ebay_client"
require "config/config"


describe Ebay::Trading::EbayClient do
  
  
  before :each do
    wsdl_file_name = File.expand_path("wsdl/trading/ebay_trading_v777.wsdl")
    Ebay::Trading::EbayClient.wsdl_file_name = wsdl_file_name
    Ebay::Trading::EbayClient.wsdl_version = 777
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
  
  
  # generate type from wsdl and check methods
  it "should generate wsdl type GetCategories" do
    wsdl_type_name = @client.operations[:get_categories][:input]
    wsdl_type = @client.generate_type(wsdl_type_name)
    
    wsdl_type.should_not be_nil
    wsdl_type.should respond_to(:category_site_id)
    wsdl_type.should respond_to(:category_parent)
    wsdl_type.should respond_to(:level_limit)
    wsdl_type.should respond_to(:view_all_nodes)
    
    wsdl_type.category_site_id =  5
    wsdl_type.category_site_id.should be_equal 5
    
    wsdl_type.level_limit =  1
    wsdl_type.level_limit.should be_equal 1
    
    wsdl_type.to_s.should eq wsdl_type_name
    wsdl_type.class.wsdl_attributes.should include(:level_limit)
  end
  
  
  it "should route to the sandbox by default" do
    Ebay::Trading::EbayClient.route_to_sandbox.should be_true
  end
  
  
  it "should keep values set on class level" do
    Ebay::Trading::EbayClient.site_id = 10
    Ebay::Trading::EbayClient.site_id.should eq 10
    
    c0 = Ebay::Trading::EbayClient.new()
    Ebay::Trading::EbayClient.site_id.should eq 10
    
  end
  
  
  # generate a type and check the to_xml method
  it "should generate a CamelCase attributes hash" do
    wsdl_type_name = @client.operations[:get_categories][:input]
    wsdl_type = @client.generate_type(wsdl_type_name)
    
    wsdl_type.view_all_nodes = false
    wsdl_type.level_limit = 2
    wsdl_type.detail_level = "ReturnAll"
    wsdl_type.version = 777
    
    wsdl_type.to_camel_case.should_not be_nil
    
    cc = wsdl_type.to_camel_case
  end
  
  
  #it "should execute a soap request" do
  #  soap_action = :get_categories
  #  soap_input = @client.generate_type(@client.operations[:get_categories][:input])
  #  soap_input.should_not be_nil
  #  
  #  Ebay::Trading::EbayClient.site_id = 77
  #  
  #  # the params
  #  soap_input.detail_level = "ReturnAll"
  #  soap_input.view_all_nodes = false
  #  soap_input.level_limit = 2
  #  soap_input.version = 777
  #  
  #  
  #  soap_output = @client.get_categories(soap_input)
  #  soap_output.should_not be_nil
  #end
  
  
  
  # todo: Methode wird private
  it "should generate a response type" do
    wsdl_input_name = @client.operations[:get_categories][:input]
    wsdl_output_name = @client.operations[:get_categories][:output]
    soap_action = @client.operations[:get_categories][:action]
    
    @client.create_response_type(soap_action, "").should_not be_nil
  end
  
end
