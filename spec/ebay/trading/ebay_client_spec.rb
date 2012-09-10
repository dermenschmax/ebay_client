require "ebay/trading/ebay_client"
require "config/config"
require "savon"
require "hashie"


describe Ebay::Trading::EbayClient, :complete_trading => true do

  before :each do
    wsdl_file_name = File.expand_path("wsdl/trading/ebay_trading_v787.wsdl")
    Ebay::Trading::EbayClient.wsdl_file_name = wsdl_file_name
    Ebay::Trading::EbayClient.wsdl_version = 787
    @client = Ebay::Trading::EbayClient.new
  end


  context 'basic tests of the library', :trading => :basic do

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
      
      wsdl_type.class_name.should eq wsdl_type_name
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
    
    
    # Tests a complete soap request to the ebay api with the following features:
    #
    #   - use request type to set request parameter
    #   - action returns a response type that matches the request type
    #   - the ack value is "Success"
    #   - test some dependencies in the returned data (eg. num of category
    #     children == attribute category_size)
    #   - to limit the response we're using a level limit of 2
    #
    it "should execute a soap request" do
      action = :get_categories
      soap_action = @client.operations[action][:action]
      soap_input = @client.generate_type(@client.operations[action][:input])
      soap_input.should_not be_nil
      
      Ebay::Trading::EbayClient.site_id = 77
      
      # the params
      soap_input.detail_level = "ReturnAll"
      soap_input.view_all_nodes = false
      soap_input.level_limit = 2
      soap_input.version = 777
      
      
      soap_output = @client.execute_soap_action(soap_action, soap_input)
      soap_output.should_not be_nil
      soap_output.ack.should eq "Success"
      
      soap_output.class_name.should eq "GetCategoriesResponseType"
      soap_output.category_count.to_i.should eq soap_output.category_array.category.size()
    end
    
    
    
    # Tests a private method that ist important. It's the construction of the
    # response structures
    #
    it "should generate a response type" do
      wsdl_input_name = @client.operations[:get_categories][:input]
      wsdl_output_name = @client.operations[:get_categories][:output]
      soap_action = @client.operations[:get_categories][:action]
      
      resp = '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
   <soapenv:Body>
    <GetCategoriesResponse xmlns="urn:ebay:apis:eBLBaseComponents">
     <Timestamp>2012-08-19T12:24:23.786Z</Timestamp>
     <Ack>Success</Ack>
     <Version>785</Version>
     <Build>E785_INTL_BUNDLED_15167907_R1</Build>
     <CategoryArray>
      <Category>
       <CategoryID>45642</CategoryID>
       <CategoryLevel>2</CategoryLevel>
       <CategoryName>Nutzfahrzeuge</CategoryName>
       <CategoryParentID>9800</CategoryParentID>
       <IntlAutosFixedCat>true</IntlAutosFixedCat>
       <LeafCategory>true</LeafCategory>
       <ORPA>true</ORPA>
      </Category>
      <Category>
       <CategoryID>44794</CategoryID>
       <CategoryLevel>2</CategoryLevel>
       <CategoryName>Wohnwagen &amp; Wohnmobile</CategoryName>
       <CategoryParentID>9800</CategoryParentID>
       <IntlAutosFixedCat>true</IntlAutosFixedCat>
       <LeafCategory>true</LeafCategory>
       <ORPA>true</ORPA>
      </Category>
     </CategoryArray>
     <CategoryCount>72</CategoryCount>
     <UpdateTime>2012-08-14T19:20:20.000Z</UpdateTime>
     <CategoryVersion>104</CategoryVersion>
     <MinimumReservePrice>0.0</MinimumReservePrice>
    </GetCategoriesResponse>
   </soapenv:Body>
  </soapenv:Envelope>'
      
      # we have to fake an HTTPI::Response object
      http_response = Hashie::Mash.new()
      http_response.body = resp
      
      savon_response = Savon::SOAP::Response.new(Savon.config.clone, http_response)
          
      response_type = @client.send(:create_response_type, savon_response.body.to_hash)
      response_type.should_not be_nil
      
      response_type.version.should eq 785.to_s
      
      response_type.category_array.class_name.should eq "CategoryArrayType"
      response_type.category_array.category.size.should be 2
      
      #puts "to_s: #{response_type.to_s}"
    end
    
    
    
    it "should be able to create the correct subtypes for complex elements" do
  
      @client.check_wasabi_document    
      subtype = @client.send(:lookup_which_subtype_to_create, "GetCategoryFeaturesResponseType", "Category")
      subtype.should eq "CategoryFeatureType"
          
      subtype = @client.send(:lookup_which_subtype_to_create, "ItemType", :bidding_details)
      subtype.should eq "BiddingDetailsType"
      
      subtype = @client.send(:lookup_which_subtype_to_create, "ItemType", :payment_methods)
      subtype.should eq "BuyerPaymentMethodCodeType"
      
      subtype = @client.send(:lookup_which_subtype_to_create, "GetCategoryFeaturesResponseType", :category_version)
      subtype.should eq "xs:string"
      
    end
    
    
    # get the features of the category 11071 "Fernseher"
    it "should get additional information for a single category" do
      action = :get_category_features
      wsdl_input_name = @client.operations[action][:input]
      wsdl_output_name = @client.operations[action][:output]
      soap_action = @client.operations[action][:action]
      
      input = @client.generate_type(wsdl_input_name)
      
      
      # some parameters
      Ebay::Trading::EbayClient.site_id = 77
      input.detail_level = "ReturnAll"
      input.version = 777
      input.category_id = 11071    # Fernseher
      input.view_all_nodes = true
        
      soap_output = @client.execute_soap_action(soap_action, input)
      soap_output.should_not be nil
      soap_output.class_name.should eq wsdl_output_name
    end
    
    
    # TODO: spec für has_complex_types, get_type_name_for schreiben
    
    
  end
  
  context "item related tests", :trading => :item do
    
    
    it "should get an item with a known id" do
      action = :get_item
      wsdl_input_name = @client.operations[action][:input]
      wsdl_output_name = @client.operations[action][:output]
      soap_action = @client.operations[action][:action]
      input = @client.generate_type(wsdl_input_name)
      
      wsdl_input_name.should_not be_nil
      wsdl_output_name.should_not be_nil
      soap_action.should_not be_nil
      input.should_not be_nil
      
      # some parameters
      Ebay::Trading::EbayClient.site_id = 77
      input.item_id = 110093916181
      input.version = 787
      input.detail_level = "ReturnAll"
      
      soap_output = @client.execute_soap_action(soap_action, input)
      soap_output.should_not be nil
      soap_output.class_name.should eq wsdl_output_name
    end
    
    
    
    it "should create a correct get_item_response_type" do
      action = :get_item
      wsdl_input_name = @client.operations[action][:input]
      wsdl_output_name = @client.operations[action][:output]
      soap_action = @client.operations[action][:action]
      input = @client.generate_type(wsdl_input_name)
      
      resp = '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
 <soapenv:Body>
  <GetItemResponse xmlns="urn:ebay:apis:eBLBaseComponents">
   <Timestamp>2012-09-06T08:16:00.337Z</Timestamp>
   <Ack>Success</Ack>
   <Version>787</Version>
   <Build>E787_INTL_BUNDLED_15262951_R1</Build>
   <Item>
    <AutoPay>false</AutoPay>
    <MotorsGermanySearchable>false</MotorsGermanySearchable>
    <BuyerProtection>ItemIneligible</BuyerProtection>
    <BuyItNowPrice currencyID="EUR">0.0</BuyItNowPrice>
    <Country>US</Country>
    <Currency>USD</Currency>
    <Description>&lt;html&gt; &lt;head&gt; &lt;meta http-equiv=&quot;Content-Type&quot; content=&quot;text/html; charset=iso-8859-1&quot;&gt; &lt;title&gt;Tech For Less Outlet Store&lt;/title&gt; &lt;/head&gt; &lt;body topmargin=&quot;0&quot;&gt; &lt;table width=&quot;100%&quot; align=&quot;center&quot; cellpadding=&quot;2&quot; cellspacing=&quot;0&quot; bordercolor=&quot;#004DBB&quot;&gt;   &lt;tr&gt;      &lt;td valign=&quot;middle&quot;&gt; &lt;table width=&quot;100%&quot; cellpadding=&quot;0&quot; cellspacing=&quot;0&quot;&gt;         &lt;tr valign=&quot;middle&quot;&gt;            &lt;td&gt;&lt;img src=&quot;http://www.techforless.com/se_images/images/logo-new327x70.gif&quot; alt=&quot;TFL Logo - Save Now&quot; width=&quot;327&quot; height=&quot;70&quot;&gt;&lt;/td&gt;           &lt;td align=&quot;right&quot; valign=&quot;bottom&quot;&gt;&lt;font size=&quot;2&quot; face=&quot;Arial, Helvetica, sans-serif&quot;&gt;&lt;a href=&quot;#condition&quot;&gt;Product              Condition&lt;/a&gt; | &lt;a href=&quot;#customerservice&quot;&gt;Customer Service&lt;/a&gt; |              &lt;a href=&quot;#Returns&quot;&gt;Returns&lt;/a&gt; | &lt;a href=&quot;#shipping&quot;&gt;Shipping&lt;/a&gt;              &lt;/font&gt;&lt;/td&gt;         &lt;/tr&gt;         &lt;tr valign=&quot;middle&quot;&gt;            &lt;td colspan=&quot;2&quot;&gt;&lt;img src=&quot;../images/clear.gif&quot; width=&quot;1&quot; height=&quot;5&quot;&gt;&lt;/td&gt;         &lt;/tr&gt;         &lt;tr background=&quot;http://www.techforless.com/se_images/blubarnavbg.png&quot;&gt;            &lt;td height=&quot;25&quot; colspan=&quot;2&quot; background=&quot;http://www.techforless.com/se_images/images/blubarnavbg2.png&quot;&gt;              &lt;div align=&quot;left&quot;&gt;&lt;font size=&quot;2&quot; face=&quot;Arial, Helvetica, sans-serif&quot;&gt;&lt;strong&gt;&lt;a href=&quot;http://stores.ebay.com/Tech-For-Less-Outlet-Store&quot;&gt;&lt;img src=&quot;http://www.techforless.com/se_images/images/tab-allcat.gif&quot; width=&quot;83&quot; height=&quot;28&quot; border=&quot;0&quot;&gt;&lt;/a&gt;&lt;img src=&quot;http://www.techforless.com/se_images/images/tab-dash.gif&quot; width=&quot;21&quot; height=&quot;28&quot;&gt;&lt;a href=&quot;http://stores.ebay.com/Tech-For-Less-Outlet-Store_Laptops-Notebooks_W0QQfsubZ12075075&quot;&gt;&lt;img src=&quot;http://www.techforless.com/se_images/images/tab-laptop.gif&quot; width=&quot;46&quot; height=&quot;28&quot; border=&quot;0&quot;&gt;&lt;/a&gt;&lt;img src=&quot;http://www.techforless.com/se_images/images/tab-dash.gif&quot; width=&quot;21&quot; height=&quot;28&quot;&gt;&lt;a href=&quot;http://stores.ebay.com/Tech-For-Less-Outlet-Store_Computer-Systems_Desktop-Computers_W0QQfsubZ13448786&quot;&gt;&lt;img src=&quot;http://www.techforless.com/se_images/images/tab-computers.gif&quot; width=&quot;63&quot; height=&quot;28&quot; border=&quot;0&quot;&gt;&lt;/a&gt;&lt;img src=&quot;http://www.techforless.com/se_images/images/tab-dash.gif&quot; width=&quot;21&quot; height=&quot;28&quot;&gt;&lt;a href=&quot;http://stores.ebay.com/Tech-For-Less-Outlet-Store_Digital-Cameras_Digital-Cameras_W0QQfsubZ13767558&quot;&gt;&lt;img src=&quot;http://www.techforless.com/se_images/images/tab-camera.gif&quot; width=&quot;53&quot; height=&quot;28&quot; border=&quot;0&quot;&gt;&lt;/a&gt;&lt;img src=&quot;http://www.techforless.com/se_images/images/tab-dash.gif&quot; width=&quot;21&quot; height=&quot;28&quot;&gt;&lt;a href=&quot;http://stores.ebay.com/Tech-For-Less-Outlet-Store_Monitors_LCD-Flat-Panel_W0QQfsubZ13361616&quot;&gt;&lt;img src=&quot;http://www.techforless.com/se_images/images/tab-monitors.gif&quot; width=&quot;51&quot; height=&quot;28&quot; border=&quot;0&quot;&gt;&lt;/a&gt;&lt;img src=&quot;http://www.techforless.com/se_images/images/tab-dash.gif&quot; width=&quot;21&quot; height=&quot;28&quot;&gt;&lt;a href=&quot;http://stores.ebay.com/Tech-For-Less-Outlet-Store_MP3-Players_W0QQfsubZ12075077&quot;&gt;&lt;img src=&quot;http://www.techforless.com/se_images/images/tab-audio.gif&quot; width=&quot;82&quot; height=&quot;28&quot; border=&quot;0&quot;&gt;&lt;/a&gt;&lt;img src=&quot;http://www.techforless.com/se_images/images/tab-dash.gif&quot; width=&quot;21&quot; height=&quot;28&quot;&gt;&lt;a href=&quot;http://stores.ebay.com/Tech-For-Less-Outlet-Store_Televisions_LCD_W0QQfsubZ13731379&quot;&gt;&lt;img src=&quot;http://www.techforless.com/se_images/images/tab-tv.gif&quot; width=&quot;65&quot; height=&quot;28&quot; border=&quot;0&quot;&gt;&lt;/a&gt;&lt;img src=&quot;http://www.techforless.com/se_images/images/tab-dash.gif&quot; width=&quot;21&quot; height=&quot;28&quot;&gt;&lt;a href=&quot;http://stores.ebay.com/Tech-For-Less-Outlet-Store_Printers_W0QQfsubZ13768257&quot;&gt;&lt;img src=&quot;http://www.techforless.com/se_images/images/tab-printers.gif&quot; width=&quot;47&quot; height=&quot;28&quot; border=&quot;0&quot;&gt;&lt;/a&gt;&lt;img src=&quot;http://www.techforless.com/se_images/images/tab-dash.gif&quot; width=&quot;21&quot; height=&quot;28&quot;&gt;&lt;a href=&quot;http://stores.ebay.com/Tech-For-Less-Outlet-Store__W0QQ_fsubZ13959411&quot;&gt;&lt;img src=&quot;http://www.techforless.com/se_images/images/tab-snd2.gif&quot; width=&quot;86&quot; height=&quot;28&quot; border=&quot;0&quot;&gt;&lt;/a&gt;&lt;/strong&gt;&lt;/font&gt;&lt;/div&gt;&lt;/td&gt;         &lt;/tr&gt;       &lt;/table&gt;&lt;/td&gt;   &lt;/tr&gt; &lt;/table&gt; &lt;table width=&quot;100%&quot; border=&quot;3&quot; align=&quot;center&quot; cellpadding=&quot;0&quot; cellspacing=&quot;0&quot; bordercolor=&quot;#004DBB&quot;&gt;   &lt;tr&gt;      &lt;td align=&quot;left&quot; valign=&quot;top&quot;&gt;        &lt;p align=&quot;left&quot;&gt;       &lt;table width=&quot;100%&quot; align=&quot;left&quot; cellpadding=&quot;2&quot; cellspacing=&quot;2&quot;&gt;         &lt;tr&gt;            &lt;td width=&quot;165&quot; align=&quot;center&quot; valign=&quot;top&quot; bgcolor=&quot;#EFEFEF&quot;&gt; &lt;p&gt;&lt;img src=&quot;http://www.techforless.com/newimages/banners.gif&quot; alt=&quot;tech for less&quot; width=&quot;153&quot; height=&quot;53&quot;&gt;&lt;/p&gt;             &lt;p&gt;&lt;a href=&quot;http://my.ebay.com/ws/eBayISAPI.dll?AcceptSavedSeller&amp;linkname=includenewsletter&amp;sellerid=techforless_outlet&quot;&gt;&lt;font size=&quot;2&quot; face=&quot;Arial, Helvetica, sans-serif&quot;&gt;Sign                Up for Newsletter&lt;/font&gt;&lt;/a&gt;&lt;/p&gt;             &lt;p&gt;&lt;font size=&quot;2&quot; face=&quot;Arial, Helvetica, sans-serif&quot;&gt;&lt;strong&gt;See                More Bargains:&lt;/strong&gt;&lt;/font&gt;&lt;/p&gt;             &lt;p&gt;&lt;a href=&quot;http://stores.ebay.com/Tech-For-Less-Outlet-Store_Laptops-Notebooks_W0QQfsubZ12075075&quot;&gt;&lt;img src=&quot;http://www.techforless.com/cimages/thumb/101453.JPG&quot; width=&quot;75&quot; height=&quot;60&quot; border=&quot;1&quot;&gt;&lt;/a&gt;&lt;br&gt;               &lt;strong&gt;&lt;font size=&quot;2&quot; face=&quot;Arial, Helvetica, sans-serif&quot;&gt;&lt;a href=&quot;http://stores.ebay.com/Tech-For-Less-Outlet-Store_Laptops-Notebooks_W0QQfsubZ12075075&quot;&gt;LAPTOPS&lt;/a&gt;&lt;/font&gt;&lt;/strong&gt;&lt;/p&gt;             &lt;p&gt;&lt;a href=&quot;http://stores.ebay.com/Tech-For-Less-Outlet-Store_Monitors_LCD-Flat-Panel_W0QQfsubZ13361616&quot;&gt;&lt;img src=&quot;http://www.techforless.com/cimages/thumb/68049.JPG&quot; width=&quot;75&quot; height=&quot;56&quot; border=&quot;1&quot;&gt;&lt;/a&gt;&lt;br&gt;               &lt;strong&gt;&lt;font size=&quot;2&quot; face=&quot;Arial, Helvetica, sans-serif&quot;&gt;&lt;a href=&quot;http://stores.ebay.com/Tech-For-Less-Outlet-Store_Monitors_LCD-Flat-Panel_W0QQfsubZ13361616&quot;&gt;MONITORS&lt;/a&gt;&lt;/font&gt;&lt;/strong&gt;&lt;/p&gt;             &lt;p&gt;&lt;a href=&quot;http://stores.ebay.com/Tech-For-Less-Outlet-Store_Computer-Systems_Desktop-Computers_W0QQfsubZ13448786&quot;&gt;&lt;img src=&quot;http://www.techforless.com/cimages/thumb/109992.JPG&quot; width=&quot;71&quot; height=&quot;75&quot; border=&quot;1&quot;&gt;&lt;/a&gt;&lt;br&gt;               &lt;strong&gt;&lt;font size=&quot;2&quot; face=&quot;Arial, Helvetica, sans-serif&quot;&gt;&lt;a href=&quot;http://stores.ebay.com/Tech-For-Less-Outlet-Store_Computer-Systems_Desktop-Computers_W0QQfsubZ13448786&quot;&gt;DESKTOPS&lt;/a&gt;&lt;/font&gt;&lt;/strong&gt;&lt;/p&gt;             &lt;p&gt;&lt;a href=&quot;http://stores.ebay.com/Tech-For-Less-Outlet-Store_Digital-Cameras_Digital-Cameras_W0QQfsubZ13767558&quot;&gt;&lt;img src=&quot;http://www.techforless.com/cimages/thumb/41615.JPG&quot; width=&quot;75&quot; height=&quot;56&quot; border=&quot;1&quot;&gt;&lt;/a&gt;&lt;br&gt;               &lt;strong&gt;&lt;font size=&quot;2&quot; face=&quot;Arial, Helvetica, sans-serif&quot;&gt;&lt;a href=&quot;http://stores.ebay.com/Tech-For-Less-Outlet-Store_Digital-Cameras_Digital-Cameras_W0QQfsubZ13767558&quot;&gt;DIGITAL                CAMERAS&lt;/a&gt; &lt;/font&gt;&lt;/strong&gt;&lt;/p&gt;             &lt;p&gt;&lt;a href=&quot;http://stores.ebay.com/Tech-For-Less-Outlet-Store_Televisions_LCD_W0QQfsubZ13731379&quot;&gt;&lt;img src=&quot;http://www.techforless.com/cimages/thumb/61467.JPG&quot; width=&quot;75&quot; height=&quot;56&quot; border=&quot;1&quot;&gt;&lt;/a&gt;&lt;br&gt;               &lt;strong&gt;&lt;font size=&quot;2&quot; face=&quot;Arial, Helvetica, sans-serif&quot;&gt;&lt;a href=&quot;http://stores.ebay.com/Tech-For-Less-Outlet-Store_Televisions_LCD_W0QQfsubZ13731379&quot;&gt;BIG                SCREEN HDTVS&lt;/a&gt;&lt;/font&gt;&lt;/strong&gt;&lt;/p&gt;             &lt;p&gt;&lt;a href=&quot;http://stores.ebay.com/Tech-For-Less-Outlet-Store_Printers_W0QQfsubZ13768257&quot;&gt;&lt;img src=&quot;http://www.techforless.com/cimages/thumb/44414.JPG&quot; width=&quot;75&quot; height=&quot;56&quot; border=&quot;1&quot;&gt;&lt;/a&gt;&lt;br&gt;               &lt;strong&gt;&lt;font size=&quot;2&quot; face=&quot;Arial, Helvetica, sans-serif&quot;&gt;&lt;a href=&quot;http://stores.ebay.com/Tech-For-Less-Outlet-Store_Printers_W0QQfsubZ13768257&quot;&gt;PRINTERS&lt;/a&gt;&lt;/font&gt;&lt;/strong&gt;              &lt;/p&gt;             &lt;p&gt;&lt;a href=&quot;http://stores.ebay.com/Tech-For-Less-Outlet-Store_MP3-Players_W0QQfsubZ12075077&quot;&gt;&lt;img src=&quot;http://www.techforless.com/cimages/thumb/114014.JPG&quot; width=&quot;75&quot; height=&quot;56&quot; border=&quot;1&quot;&gt;&lt;/a&gt;&lt;br&gt;               &lt;strong&gt;&lt;font size=&quot;2&quot; face=&quot;Arial, Helvetica, sans-serif&quot;&gt;&lt;a href=&quot;http://stores.ebay.com/Tech-For-Less-Outlet-Store_MP3-Players_W0QQfsubZ12075077&quot;&gt;MP3                PLAYERS&lt;/a&gt;&lt;/font&gt;&lt;/strong&gt; &lt;/p&gt;             &lt;p&gt;&lt;a href=&quot;http://stores.ebay.com/Tech-For-Less-Outlet-Store_Networking_W0QQfsubZ13768857&quot;&gt;&lt;img src=&quot;http://www.techforless.com/cimages/thumb/114588.JPG&quot; width=&quot;75&quot; height=&quot;21&quot; border=&quot;1&quot;&gt;&lt;/a&gt;&lt;br&gt;               &lt;strong&gt;&lt;font size=&quot;2&quot; face=&quot;Arial, Helvetica, sans-serif&quot;&gt;&lt;a href=&quot;http://stores.ebay.com/Tech-For-Less-Outlet-Store_Networking_W0QQfsubZ13768857&quot;&gt;NETWORKING&lt;/a&gt;&lt;/font&gt;&lt;/strong&gt;              &lt;/p&gt;             &lt;p&gt;&lt;strong&gt;&lt;font size=&quot;2&quot; face=&quot;Arial, Helvetica, sans-serif&quot;&gt;&lt;a href=&quot;http://stores.ebay.com/Tech-For-Less-Outlet-Store&quot;&gt;SEE                ALL OUR PRODUCTS&lt;/a&gt;&lt;/font&gt;&lt;/strong&gt;&lt;/p&gt;             &lt;p&gt;&lt;font color=&quot;#1755ae&quot; size=&quot;2&quot; face=&quot;Arial, Helvetica, sans-serif&quot;&gt;&lt;/font&gt;&lt;/p&gt;             &lt;p&gt;&lt;img src=&quot;http://www.techforless.com/newimages/nc_30daymbg.png&quot; alt=&quot;satisfaction guaranteed&quot; width=&quot;68&quot; height=&quot;79&quot;&gt;&lt;br&gt;               &lt;font size=&quot;1&quot; face=&quot;Arial, Helvetica, sans-serif&quot;&gt;Your satisfaction                is 100% guaranteed. All products shown are in stock and carry a                warranty &amp;#8211; so you can buy with confidence!&lt;/font&gt;&lt;/p&gt;             &lt;p&gt;&lt;a href=&quot;https://www.squaretrade.com/pages/&quot; target=&quot;_blank&quot;&gt;&lt;img src=&quot;http://www.techforless.com/se_images/images/squaretrade-box.gif&quot; alt=&quot;Squaretrade extended warranty&quot; width=&quot;150&quot; height=&quot;70&quot; border=&quot;0&quot;&gt;&lt;/a&gt;&lt;br&gt;             &lt;/p&gt;             &lt;/td&gt;           &lt;td valign=&quot;top&quot;&gt;&lt;table width=&quot;100%&quot; cellspacing=&quot;2&quot; cellpadding=&quot;2&quot;&gt;               &lt;tr&gt;                  &lt;td valign=&quot;top&quot;&gt; &lt;p&gt;                      &lt;!--////////// BEGIN DESCRIPTION //////////--&gt;                   &lt;/p&gt;                   &lt;h3 style=&quot;font-weight: normal; font-size: 18px; color: #666; line-height: 26px; border-bottom: #eee 9px solid; font-family: Arial, Helvetica, sans-serif;&quot;&gt;&lt;b&gt;Refurbished                      Asus Eee PC Seashell 1005HA-VU1X-BK Netbook - Intel Atom N270 1.6 GHz Processor - 1 GB RAM - 160 GB Hard Drive - 10.1-inch Display - XP Home - Black&lt;/b&gt;&lt;/h3&gt;                   &lt;p&gt;&lt;font size=&quot;2&quot; face=&quot;Arial, Helvetica, sans-serif&quot;&gt;                       With the Asus Eee PC Seashell 1005HA-VU1X-BK Notebook you can share photos of your travels without waiting till you get home. The Asus Eee PC Seashell 1005HA-VU1X-BK Notebook offers the ultimate in mobility with 802.11n and Bluetooth V2.1 wireless capabilities. It offers massive amounts of storage space with a 160 GB hard drive and 10 GB online Eee Storage. The Asus Eee PC Seashell 1005HA-VU1X-BK Notebook features an ergonomically designed keyboard for enhanced comfort and less fatigue while typing for long periods. The Asus Eee PC Seashell 1005HA-VU1X-BK Notebook features a modern design, up to 10.5 hours of battery life, and other useful features that make it the easy choice.&lt;/font&gt;&lt;br&gt;                   &lt;/p&gt;                   &lt;p&gt;&lt;font color=&quot;#FF0000&quot; size=&quot;2&quot; face=&quot;MS Sans Serif&quot;&gt;&lt;b&gt;Product                      Condition: &lt;/b&gt;&lt;br&gt;                     Refurbished - &lt;/font&gt;&lt;font color=&quot;#FF0000&quot; size=&quot;2&quot; face=&quot;Arial, Helvetica, sans-serif&quot;&gt;These products work great as they have been restored and tested to meet manufacturer quality standards. These products have been greatly discounted as they may show limited signs of use and may be missing some accessories that are not needed for the functionality of the product. Manuals and software might not be included, however those are usually available for download from the manufacturer&apos;s web site. These products have a 45 Day satisfaction guarantee and a 90 day Tech For Less warranty in the unlikely event of issues. These items are usually repackaged for protection during shipping.&lt;/font&gt;&lt;font color=&quot;#FF0000&quot; size=&quot;2&quot; face=&quot;MS Sans Serif&quot;&gt;&lt;br&gt;                     &lt;/font&gt;&lt;br&gt;                     &lt;!--////////// END DESCRIPTION //////////--&gt;                     &lt;!--////////// BEGIN FEATURES //////////--&gt;                   &lt;/p&gt;                   &lt;TABLE cellSpacing=2 cellPadding=2 width=&quot;100%&quot;&gt;                     &lt;TBODY&gt;                       &lt;TR&gt;                          &lt;TD height=&quot;25&quot; background=http://www.techforless.com/se_images/images/blubarnavbg.gif&gt;                            &lt;P&gt;&lt;FONT face=&quot;Arial, Helvetica, sans-serif&quot; color=#ffffff size=3&gt;&lt;STRONG&gt;Features&lt;/STRONG&gt;&lt;/FONT&gt;&lt;/P&gt;&lt;/TD&gt;                       &lt;/TR&gt;                     &lt;/TBODY&gt;                   &lt;/TABLE&gt;                   &lt;p&gt;&lt;font size=&quot;2&quot; face=&quot;Arial, Helvetica, sans-serif&quot;&gt; &lt;table border=1&gt;&lt;tr&gt;&lt;td width=&quot;50%&quot;&gt;&lt;font face=&quot;MS Sans Serif&quot; size=&quot;2&quot;&gt;Product Name&lt;/font&gt;&lt;/td&gt;&lt;td width=&quot;50%&quot;&gt;&lt;font face=&quot;MS Sans Serif&quot; size=&quot;2&quot;&gt;Asus Eee PC Seashell 1005HA-VU1X-BK Netbook&lt;/font&gt;&lt;/td&gt;&lt;/tr&gt;&lt;tr&gt;&lt;td width=&quot;50%&quot;&gt;&lt;font face=&quot;MS Sans Serif&quot; size=&quot;2&quot;&gt;Product Type&lt;/font&gt;&lt;/td&gt;&lt;td width=&quot;50%&quot;&gt;&lt;font face=&quot;MS Sans Serif&quot; size=&quot;2&quot;&gt;Netbook&lt;/font&gt;&lt;/td&gt;&lt;/tr&gt;&lt;tr&gt;&lt;td width=&quot;50%&quot;&gt;&lt;font face=&quot;MS Sans Serif&quot; size=&quot;2&quot;&gt;Processor&lt;/font&gt;&lt;/td&gt;&lt;td width=&quot;50%&quot;&gt;&lt;font face=&quot;MS Sans Serif&quot; size=&quot;2&quot;&gt;Intel Atom N270 1.6 GHz&lt;/font&gt;&lt;/td&gt;&lt;/tr&gt;&lt;tr&gt;&lt;td width=&quot;50%&quot;&gt;&lt;font face=&quot;MS Sans Serif&quot; size=&quot;2&quot;&gt;Processor Technology&lt;/font&gt;&lt;/td&gt;&lt;td width=&quot;50%&quot;&gt;&lt;font face=&quot;MS Sans Serif&quot; size=&quot;2&quot;&gt;Hyper-Threading Technology, Enhanced SpeedStep Technology&lt;/font&gt;&lt;/td&gt;&lt;/tr&gt;&lt;tr&gt;&lt;td width=&quot;50%&quot;&gt;&lt;font face=&quot;MS Sans Serif&quot; size=&quot;2&quot;&gt;Bus Speed&lt;/font&gt;&lt;/td&gt;&lt;td width=&quot;50%&quot;&gt;&lt;font face=&quot;MS Sans Serif&quot; size=&quot;2&quot;&gt;533 MHz&lt;/font&gt;&lt;/td&gt;&lt;/tr&gt;&lt;tr&gt;&lt;td width=&quot;50%&quot;&gt;&lt;font face=&quot;MS Sans Serif&quot; size=&quot;2&quot;&gt;L2 Cache&lt;/font&gt;&lt;/td&gt;&lt;td width=&quot;50%&quot;&gt;&lt;font face=&quot;MS Sans Serif&quot; size=&quot;2&quot;&gt;512 KB&lt;/font&gt;&lt;/td&gt;&lt;/tr&gt;&lt;tr&gt;&lt;td width=&quot;50%&quot;&gt;&lt;font face=&quot;MS Sans Serif&quot; size=&quot;2&quot;&gt;Chipset&lt;/font&gt;&lt;/td&gt;&lt;td width=&quot;50%&quot;&gt;&lt;font face=&quot;MS Sans Serif&quot; size=&quot;2&quot;&gt;Intel 945GSE Express&lt;/font&gt;&lt;/td&gt;&lt;/tr&gt;&lt;tr&gt;&lt;td width=&quot;50%&quot;&gt;&lt;font face=&quot;MS Sans Serif&quot; size=&quot;2&quot;&gt;Standard Memory&lt;/font&gt;&lt;/td&gt;&lt;td width=&quot;50%&quot;&gt;&lt;font face=&quot;MS Sans Serif&quot; size=&quot;2&quot;&gt;1 GB&lt;/font&gt;&lt;/td&gt;&lt;/tr&gt;&lt;tr&gt;&lt;td width=&quot;50%&quot;&gt;&lt;font face=&quot;MS Sans Serif&quot; size=&quot;2&quot;&gt;Memory Technology&lt;/font&gt;&lt;/td&gt;&lt;td width=&quot;50%&quot;&gt;&lt;font face=&quot;MS Sans Serif&quot; size=&quot;2&quot;&gt;DDR2 SDRAM&lt;/font&gt;&lt;/td&gt;&lt;/tr&gt;&lt;tr&gt;&lt;td width=&quot;50%&quot;&gt;&lt;font face=&quot;MS Sans Serif&quot; size=&quot;2&quot;&gt;Memory Card Reader&lt;/font&gt;&lt;/td&gt;&lt;td width=&quot;50%&quot;&gt;&lt;font face=&quot;MS Sans Serif&quot; size=&quot;2&quot;&gt;Yes&lt;/font&gt;&lt;/td&gt;&lt;/tr&gt;&lt;tr&gt;&lt;td width=&quot;50%&quot;&gt;&lt;font face=&quot;MS Sans Serif&quot; size=&quot;2&quot;&gt;Memory Card Support&lt;/font&gt;&lt;/td&gt;&lt;td width=&quot;50%&quot;&gt;&lt;font face=&quot;MS Sans Serif&quot; size=&quot;2&quot;&gt;Secure Digital High Capacity (SDHC), MultiMediaCard (MMC&lt;/font&gt;&lt;/td&gt;&lt;/tr&gt;&lt;tr&gt;&lt;td width=&quot;50%&quot;&gt;&lt;font face=&quot;MS Sans Serif&quot; size=&quot;2&quot;&gt;Hard Drive Capacity&lt;/font&gt;&lt;/td&gt;&lt;td width=&quot;50%&quot;&gt;&lt;font face=&quot;MS Sans Serif&quot; size=&quot;2&quot;&gt;160 GB&lt;/font&gt;&lt;/td&gt;&lt;/tr&gt;&lt;tr&gt;&lt;td width=&quot;50%&quot;&gt;&lt;font face=&quot;MS Sans Serif&quot; size=&quot;2&quot;&gt;Screen Size&lt;/font&gt;&lt;/td&gt;&lt;td width=&quot;50%&quot;&gt;&lt;font face=&quot;MS Sans Serif&quot; size=&quot;2&quot;&gt;10.1 inches&lt;/font&gt;&lt;/td&gt;&lt;/tr&gt;&lt;tr&gt;&lt;td width=&quot;50%&quot;&gt;&lt;font face=&quot;MS Sans Serif&quot; size=&quot;2&quot;&gt;Graphic Mode&lt;/font&gt;&lt;/td&gt;&lt;td width=&quot;50%&quot;&gt;&lt;font face=&quot;MS Sans Serif&quot; size=&quot;2&quot;&gt;WSVGA&lt;/font&gt;&lt;/td&gt;&lt;/tr&gt;&lt;tr&gt;&lt;td width=&quot;50%&quot;&gt;&lt;font face=&quot;MS Sans Serif&quot; size=&quot;2&quot;&gt;Display Screen Type&lt;/font&gt;&lt;/td&gt;&lt;td width=&quot;50%&quot;&gt;&lt;font face=&quot;MS Sans Serif&quot; size=&quot;2&quot;&gt;Active Matrix TFT Color LCD&lt;/font&gt;&lt;/td&gt;&lt;/tr&gt;&lt;tr&gt;&lt;td width=&quot;50%&quot;&gt;&lt;font face=&quot;MS Sans Serif&quot; size=&quot;2&quot;&gt;Widescreen&lt;/font&gt;&lt;/td&gt;&lt;td width=&quot;50%&quot;&gt;&lt;font face=&quot;MS Sans Serif&quot; size=&quot;2&quot;&gt;Yes&lt;/font&gt;&lt;/td&gt;&lt;/tr&gt;&lt;tr&gt;&lt;td width=&quot;50%&quot;&gt;&lt;font face=&quot;MS Sans Serif&quot; size=&quot;2&quot;&gt;Display Resolution&lt;/font&gt;&lt;/td&gt;&lt;td width=&quot;50%&quot;&gt;&lt;font face=&quot;MS Sans Serif&quot; size=&quot;2&quot;&gt;1024 x 600&lt;/font&gt;&lt;/td&gt;&lt;/tr&gt;&lt;tr&gt;&lt;td width=&quot;50%&quot;&gt;&lt;font face=&quot;MS Sans Serif&quot; size=&quot;2&quot;&gt;Graphics Controller&lt;/font&gt;&lt;/td&gt;&lt;td width=&quot;50%&quot;&gt;&lt;font face=&quot;MS Sans Serif&quot; size=&quot;2&quot;&gt;Intel GMA950&lt;/font&gt;&lt;/td&gt;&lt;/tr&gt;&lt;tr&gt;&lt;td width=&quot;50%&quot;&gt;&lt;font face=&quot;MS Sans Serif&quot; size=&quot;2&quot;&gt;Graphics Memory Accessibility&lt;/font&gt;&lt;/td&gt;&lt;td width=&quot;50%&quot;&gt;&lt;font face=&quot;MS Sans Serif&quot; size=&quot;2&quot;&gt;Shared&lt;/font&gt;&lt;/td&gt;&lt;/tr&gt;&lt;tr&gt;&lt;td width=&quot;50%&quot;&gt;&lt;font face=&quot;MS Sans Serif&quot; size=&quot;2&quot;&gt;Network Technology&lt;/font&gt;&lt;/td&gt;&lt;td width=&quot;50%&quot;&gt;&lt;font face=&quot;MS Sans Serif&quot; size=&quot;2&quot;&gt;Fast Ethernet, Wi-Fi&lt;/font&gt;&lt;/td&gt;&lt;/tr&gt;&lt;tr&gt;&lt;td width=&quot;50%&quot;&gt;&lt;font face=&quot;MS Sans Serif&quot; size=&quot;2&quot;&gt;Network Standard&lt;/font&gt;&lt;/td&gt;&lt;td width=&quot;50%&quot;&gt;&lt;font face=&quot;MS Sans Serif&quot; size=&quot;2&quot;&gt;IEEE 802.3u, IEEE 802.11n&lt;/font&gt;&lt;/td&gt;&lt;/tr&gt;&lt;tr&gt;&lt;td width=&quot;50%&quot;&gt;&lt;font face=&quot;MS Sans Serif&quot; size=&quot;2&quot;&gt;Keyboard Size&lt;/font&gt;&lt;/td&gt;&lt;td width=&quot;50%&quot;&gt;&lt;font face=&quot;MS Sans Serif&quot; size=&quot;2&quot;&gt;Standard Size&lt;/font&gt;&lt;/td&gt;&lt;/tr&gt;&lt;tr&gt;&lt;td width=&quot;50%&quot;&gt;&lt;font face=&quot;MS Sans Serif&quot; size=&quot;2&quot;&gt;Pointing Device Type&lt;/font&gt;&lt;/td&gt;&lt;td width=&quot;50%&quot;&gt;&lt;font face=&quot;MS Sans Serif&quot; size=&quot;2&quot;&gt;TouchPad&lt;/font&gt;&lt;/td&gt;&lt;/tr&gt;&lt;tr&gt;&lt;td width=&quot;50%&quot;&gt;&lt;font face=&quot;MS Sans Serif&quot; size=&quot;2&quot;&gt;Interfaces/Ports&lt;/font&gt;&lt;/td&gt;&lt;td width=&quot;50%&quot;&gt;&lt;font face=&quot;MS Sans Serif&quot; size=&quot;2&quot;&gt;1 x RJ-45 Network, 1 x Mini-phone Microphone, 1 x 15-pin HD-15 VGA, 1 x Mini-phone Headphone, 1 x DC Power Input, 3 x 4-pin Type A USB 2.0 - USB&lt;/font&gt;&lt;/td&gt;&lt;/tr&gt;&lt;tr&gt;&lt;td width=&quot;50%&quot;&gt;&lt;font face=&quot;MS Sans Serif&quot; size=&quot;2&quot;&gt;Camera&lt;/font&gt;&lt;/td&gt;&lt;td width=&quot;50%&quot;&gt;&lt;font face=&quot;MS Sans Serif&quot; size=&quot;2&quot;&gt;Yes&lt;/font&gt;&lt;/td&gt;&lt;/tr&gt;&lt;tr&gt;&lt;td width=&quot;50%&quot;&gt;&lt;font face=&quot;MS Sans Serif&quot; size=&quot;2&quot;&gt;Operating System Provided&lt;/font&gt;&lt;/td&gt;&lt;td width=&quot;50%&quot;&gt;&lt;font face=&quot;MS Sans Serif&quot; size=&quot;2&quot;&gt;Microsoft Windows XP Home&lt;/font&gt;&lt;/td&gt;&lt;/tr&gt;&lt;tr&gt;&lt;td width=&quot;50%&quot;&gt;&lt;font face=&quot;MS Sans Serif&quot; size=&quot;2&quot;&gt;Battery&lt;/font&gt;&lt;/td&gt;&lt;td width=&quot;50%&quot;&gt;&lt;font face=&quot;MS Sans Serif&quot; size=&quot;2&quot;&gt;6-cell, Lithium-ion, 48 Wh, 8.5 hours&lt;/font&gt;&lt;/td&gt;&lt;/tr&gt;&lt;tr&gt;&lt;td width=&quot;50%&quot;&gt;&lt;font face=&quot;MS Sans Serif&quot; size=&quot;2&quot;&gt;Color&lt;/font&gt;&lt;/td&gt;&lt;td width=&quot;50%&quot;&gt;&lt;font face=&quot;MS Sans Serif&quot; size=&quot;2&quot;&gt;Black&lt;/font&gt;&lt;/td&gt;&lt;/tr&gt;&lt;tr&gt;&lt;td width=&quot;50%&quot;&gt;&lt;font face=&quot;MS Sans Serif&quot; size=&quot;2&quot;&gt;Dimensions&lt;/font&gt;&lt;/td&gt;&lt;td width=&quot;50%&quot;&gt;&lt;font face=&quot;MS Sans Serif&quot; size=&quot;2&quot;&gt;10.3 x 1.4 x 7.0 inches&lt;/font&gt;&lt;/td&gt;&lt;/tr&gt;&lt;tr&gt;&lt;td width=&quot;50%&quot;&gt;&lt;font face=&quot;MS Sans Serif&quot; size=&quot;2&quot;&gt;Weight&lt;/font&gt;&lt;/td&gt;&lt;td width=&quot;50%&quot;&gt;&lt;font face=&quot;MS Sans Serif&quot; size=&quot;2&quot;&gt;2.8 lbs&lt;/font&gt;&lt;/td&gt;&lt;/tr&gt;&lt;tr&gt;&lt;td colspan=2 align=&quot;center&quot;&gt;&lt;font face=&quot;MS Sans Serif&quot; size=&quot;2&quot;&gt;Warranty&lt;/font&gt;&lt;/td&gt;&lt;/tr&gt;&lt;tr&gt;&lt;td width=&quot;50%&quot;&gt;&lt;font face=&quot;MS Sans Serif&quot; size=&quot;2&quot;&gt;Money Back Guarantee:&lt;/font&gt;&lt;/td&gt;&lt;td width=&quot;50%&quot;&gt;&lt;font face=&quot;MS Sans Serif&quot; size=&quot;2&quot;&gt;45 Days. One of the best guarantees on the Web! No questions asked, full refund of product price and return shipping via pre-paid label so your return will be easy and hassle-free.&lt;/font&gt;&lt;/td&gt;&lt;/tr&gt; &lt;tr&gt;&lt;td width=&quot;50%&quot;&gt;&lt;font face=&quot;MS Sans Serif&quot; size=&quot;2&quot;&gt;  Refurbished/Open Box Warranty:&lt;/font&gt;&lt;/td&gt;&lt;td width=&quot;50%&quot;&gt;&lt;font face=&quot;MS Sans Serif&quot; size=&quot;2&quot;&gt;90 Days, and Tech for Less provides free pre-paid return label and replaces the item or reimburses original purchase price including shipping costs&lt;/font&gt;&lt;/td&gt;&lt;/tr&gt;&lt;/table&gt;                        &lt;/font&gt;&lt;/p&gt;                   &lt;p&gt;&lt;font size=&quot;2&quot; face=&quot;Arial, Helvetica, sans-serif&quot;&gt;The picture                      we use is intended to be a representation of the model of                      product for sale. Please be sure to check the condition of                      the unit that is for sale.&lt;/font&gt;&lt;/p&gt;                   &lt;p&gt;                      &lt;!--////////// END FEATURES //////////--&gt;                     &lt;!--////////// BEGIN THIS ITEM INCLUDES //////////--&gt;                     &lt;!--a name=&quot;condition&quot;&gt;&lt;/a&gt; &lt;/p&gt;                   &lt;TABLE cellSpacing=2 cellPadding=2 width=&quot;100%&quot;&gt;                     &lt;TBODY&gt;                       &lt;TR&gt;                          &lt;TD height=&quot;25&quot; background=http://www.techforless.com/se_images/images/blubarnavbg.gif&gt;                            &lt;P&gt;&lt;FONT face=&quot;Arial, Helvetica, sans-serif&quot; color=#ffffff size=3&gt;&lt;STRONG&gt;Product                              Condition&lt;/STRONG&gt;&lt;/FONT&gt;&lt;/P&gt;&lt;/TD&gt;                       &lt;/TR&gt;                     &lt;/TBODY&gt;                   &lt;/TABLE&gt;                   &lt;p&gt;&lt;font face=&quot;Arial, Helvetica, sans-serif&quot; size=&quot;2&quot;&gt;&lt;strong&gt;Refurbished&lt;br&gt;                     &lt;/strong&gt;&lt;/font&gt;&lt;font size=&quot;2&quot; face=&quot;Arial, Helvetica, sans-serif&quot;&gt;These products work great as they have been restored and tested to meet manufacturer quality standards. These products have been greatly discounted as they may show limited signs of use and may be missing some accessories that are not needed for the functionality of the product. Manuals and software might not be included, however those are usually available for download from the manufacturer&apos;s web site. These products have a 45 Day satisfaction guarantee and a 90 day Tech For Less warranty in the unlikely event of issues. These items are usually repackaged for protection during shipping.&lt;strong&gt;                      &lt;/strong&gt;&lt;/font&gt;&lt;font face=&quot;Arial, Helvetica, sans-serif&quot; size=&quot;2&quot;&gt;&lt;strong&gt;                      &lt;/strong&gt;&lt;/font&gt;&lt;/p&gt;                   &lt;!--////////// END THIS ITEM INCLUDES //////////--&gt;                     &lt;!--////////// BEGIN SHIPPING //////////--&gt;                     &lt;a name=&quot;shipping&quot;&gt;&lt;/a&gt;                    &lt;TABLE cellSpacing=2 cellPadding=2 width=&quot;100%&quot;&gt;                     &lt;TBODY&gt;                       &lt;TR&gt;                          &lt;TD height=&quot;25&quot; background=http://www.techforless.com/se_images/images/blubarnavbg.gif&gt;                            &lt;P&gt;&lt;FONT face=&quot;Arial, Helvetica, sans-serif&quot; color=#ffffff size=3&gt;&lt;STRONG&gt;Shipping&lt;/STRONG&gt;&lt;/FONT&gt;&lt;/P&gt;&lt;/TD&gt;                       &lt;/TR&gt;                     &lt;/TBODY&gt;                   &lt;/TABLE&gt;                   &lt;ul&gt;                     &lt;li&gt;&lt;font size=&quot;2&quot; face=&quot;Arial, Helvetica, sans-serif&quot;&gt;Within                        the United States, we ship via FedEx or USPS at our discretion.&lt;/font&gt;&lt;/li&gt;                     &lt;li&gt;&lt;font size=&quot;2&quot; face=&quot;Arial, Helvetica, sans-serif&quot;&gt; If                        we offer free ground shipping on a listing, it will be for                        the 48 contiguous United States only. Shipping to Alaska,                        Hawaii and the US Territories will incur regular shipping                        charge as we cannot ship via the regular ground service.&lt;/font&gt;&lt;/li&gt;                     &lt;li&gt;&lt;font size=&quot;2&quot; face=&quot;Arial, Helvetica, sans-serif&quot;&gt;Freight                        delivery appointments may be required for oversized or heavy                        items.&lt;/font&gt;&lt;/li&gt;                     &lt;li&gt;&lt;font size=&quot;2&quot; face=&quot;Arial, Helvetica, sans-serif&quot;&gt;Tech                        for Less is not responsible for any customs, duties, and/or                        taxes for international shipments. We do not mark merchandise                        values below value or mark items as &amp;quot;gifts&amp;quot; as                        US and International government regulations prohibit such                        behavior.&lt;/font&gt;&lt;/li&gt;                     &lt;li&gt;&lt;font size=&quot;2&quot; face=&quot;Arial, Helvetica, sans-serif&quot;&gt;Removing                        the product from the United States may void all warranties.                        Please check with the product manufacturer to find out their                        international warranty terms.&lt;/font&gt;&lt;/li&gt;                     &lt;li&gt;&lt;font size=&quot;2&quot; face=&quot;Arial, Helvetica, sans-serif&quot;&gt; We                        only ship to your PayPal address and cannot change the address                        once your order is placed.&lt;/font&gt;&lt;/li&gt;                     &lt;li&gt;&lt;font size=&quot;2&quot; face=&quot;Arial, Helvetica, sans-serif&quot;&gt; 					  Please Note: All International orders (including orders                        shipping to US territories) will be held for a period of                        72 hours from the time of payment to insure payment via                        PayPal is cleared.&lt;/font&gt;&lt;/li&gt; 					                   &lt;/ul&gt;                   &lt;!--////////// END SHIPPING //////////--&gt;                   &lt;!--////////// BEGIN PAYMENT //////////--&gt;                   &lt;TABLE cellSpacing=2 cellPadding=2 width=&quot;100%&quot;&gt;                     &lt;TBODY&gt;                       &lt;TR&gt;                          &lt;TD height=&quot;25&quot; background=http://www.techforless.com/se_images/images/blubarnavbg.gif&gt;                            &lt;P&gt;&lt;FONT face=&quot;Arial, Helvetica, sans-serif&quot; color=#ffffff size=3&gt;&lt;STRONG&gt;Payment&lt;/STRONG&gt;&lt;/FONT&gt;&lt;/P&gt;&lt;/TD&gt;                       &lt;/TR&gt;                     &lt;/TBODY&gt;                   &lt;/TABLE&gt;                   &lt;ul&gt;                     &lt;li&gt;&lt;font size=&quot;2&quot; face=&quot;Arial, Helvetica, sans-serif&quot;&gt;We                        only accept payment by PayPal.&lt;/font&gt;&lt;/li&gt;                     &lt;li&gt;&lt;font size=&quot;2&quot; face=&quot;Arial, Helvetica, sans-serif&quot;&gt;Immediate                        payment is required, or within 5 days of auction closing.&lt;/font&gt;&lt;/li&gt;                     &lt;li&gt;&lt;font size=&quot;2&quot; face=&quot;Arial, Helvetica, sans-serif&quot;&gt;We                        charge sales tax in Colorado and Indiana. State taxes will                        be calculated at checkout.&lt;/font&gt;&lt;/li&gt;                     &lt;li&gt;&lt;font size=&quot;2&quot; face=&quot;Arial, Helvetica, sans-serif&quot;&gt;In                        Store Pick-Ups can be arranged from 9:00am&amp;#8211;6:00pm                        Monday&amp;#8211;Friday. All orders must be picked up within                        5 business days of the order date to avoid cancellation.                        Please note that a $10.00 handling fee and sales tax will                        apply for all in store pick-up orders placed. At the time                        of pick up accepted payment methods are cash, check or credit                        card. PayPal payment is not accepted in store. Please contact                        us for further inquiries.&lt;/font&gt;&lt;/li&gt;                   &lt;/ul&gt;                   &lt;!--////////// END PAYMENT //////////--&gt;                   &lt;!--////////// BEGIN RETURNS //////////--&gt;                   &lt;font face=&quot;Arial, Helvetica, sans-serif&quot;&gt;&lt;font size=&quot;2&quot;&gt;&lt;a name=&quot;Returns&quot;&gt;&lt;/a&gt;&lt;/font&gt;&lt;/font&gt;                    &lt;TABLE cellSpacing=2 cellPadding=2 width=&quot;100%&quot;&gt;                     &lt;TBODY&gt;                       &lt;TR&gt;                          &lt;TD height=&quot;25&quot; background=http://www.techforless.com/se_images/images/blubarnavbg.gif&gt;                            &lt;P&gt;&lt;FONT face=&quot;Arial, Helvetica, sans-serif&quot; color=#ffffff size=3&gt;&lt;STRONG&gt;Returns&lt;/STRONG&gt;&lt;/FONT&gt;&lt;/P&gt;&lt;/TD&gt;                       &lt;/TR&gt;                     &lt;/TBODY&gt;                   &lt;/TABLE&gt;                   &lt;font size=&quot;2&quot; face=&quot;Arial, Helvetica, sans-serif&quot;&gt;&amp;nbsp;&lt;/font&gt;                    &lt;ul&gt;                     &lt;li&gt;&lt;font size=&quot;2&quot; face=&quot;Arial, Helvetica, sans-serif&quot;&gt;Please                        contact our Customer Service team if you have any issues                        with your item. &lt;/font&gt;&lt;/li&gt;                     &lt;li&gt;&lt;font size=&quot;2&quot; face=&quot;Arial, Helvetica, sans-serif&quot;&gt;Defective items may be returned for a  					full refund within 90 days.  Tech for Less will arrange for and pay the cost to ship authorized  					defective returns.&lt;/font&gt;&lt;/li&gt;                     &lt;li&gt;&lt;font size=&quot;2&quot; face=&quot;Arial, Helvetica, sans-serif&quot;&gt;Items listed as Scratch &amp; Dent or Non-Functional  					are sold as-is and cannot be returned.&lt;/font&gt;&lt;/li&gt;                     &lt;li&gt;&lt;font size=&quot;2&quot; face=&quot;Arial, Helvetica, sans-serif&quot;&gt;All other items are subject to our  					no-hassle 45-Day Money-back Guarantee.  One of the best guarantees on the Web! No questions  					asked on non-defective returns within 45 days of the purchase date.  You will get a  					full refund minus the original shipping fees and we will send you a pre-paid return label  					so your return will be easy and hassle-free&lt;/font&gt;&lt;/li&gt;                   &lt;/ul&gt;                   &lt;!--////////// END RETURNS //////////--&gt;                   &lt;!--////////// BEGIN CUSTOMER SUPPORT //////////--&gt;                   &lt;font face=&quot;Arial, Helvetica, sans-serif&quot;&gt;&lt;font size=&quot;2&quot;&gt;&lt;a name=&quot;customerservice&quot;&gt;&lt;/a&gt;&lt;/font&gt;&lt;/font&gt;                    &lt;TABLE cellSpacing=2 cellPadding=2 width=&quot;100%&quot;&gt;                     &lt;TBODY&gt;                       &lt;TR&gt;                          &lt;TD height=&quot;25&quot; background=http://www.techforless.com/se_images/images/blubarnavbg.gif&gt;                            &lt;P&gt;&lt;FONT face=&quot;Arial, Helvetica, sans-serif&quot; color=#ffffff size=3&gt;&lt;STRONG&gt;Customer                              Support&lt;/STRONG&gt;&lt;/FONT&gt;&lt;/P&gt;&lt;/TD&gt;                       &lt;/TR&gt;                     &lt;/TBODY&gt;                   &lt;/TABLE&gt;                   &lt;ul&gt;                     &lt;li&gt;&lt;font size=&quot;2&quot; face=&quot;Arial, Helvetica, sans-serif&quot;&gt;Our                        customer support is available from 7:30am to 6:30pm, Monday                        through Friday.&lt;/font&gt;&lt;/li&gt;                     &lt;li&gt;&lt;font size=&quot;2&quot; face=&quot;Arial, Helvetica, sans-serif&quot;&gt;Please                        contact us at (866) 880-1230 or use the eBay Contact Seller Functionality&lt;/font&gt;&lt;/li&gt;                     &lt;li&gt;&lt;font size=&quot;2&quot; face=&quot;Arial, Helvetica, sans-serif&quot;&gt;Please                        contact us with any concerns so that we can ensure you are                        satisfied with your purchase.&lt;/font&gt;&lt;/li&gt;                   &lt;/ul&gt;                   &lt;!--////////// END CUSTOMER SUPPORT //////////--&gt;                   &lt;TABLE cellSpacing=2 cellPadding=2 width=&quot;100%&quot;&gt;                     &lt;TBODY&gt;                       &lt;TR&gt;                          &lt;TD height=&quot;25&quot; background=http://www.techforless.com/se_images/images/blubarnavbg.gif&gt;                            &lt;P&gt;&lt;FONT face=&quot;Arial, Helvetica, sans-serif&quot; color=#ffffff size=3&gt;&lt;STRONG&gt;Want                              Even More Deals?&lt;/STRONG&gt;&lt;/FONT&gt;&lt;/P&gt;&lt;/TD&gt;                       &lt;/TR&gt;                     &lt;/TBODY&gt;                   &lt;/TABLE&gt;                   &lt;p&gt;&lt;font size=&quot;2&quot; face=&quot;Arial, Helvetica, sans-serif&quot;&gt;Click                      here for more specials: &lt;a href=&quot;http://stores.ebay.com/Tech-For-Less-Outlet-Store&quot; target=&quot;_blank&quot;&gt;http://stores.ebay.com/Tech-For-Less-Outlet-Store&lt;/a&gt;&lt;/font&gt;&lt;/p&gt;                   &lt;p&gt;&amp;nbsp;&lt;/p&gt;&lt;/td&gt;               &lt;/tr&gt;             &lt;/table&gt;             &lt;table width=&quot;100%&quot; cellspacing=&quot;2&quot; cellpadding=&quot;2&quot;&gt;               &lt;tr&gt;                  &lt;td height=&quot;25&quot; background=&quot;http://www.techforless.com/se_images/images/blubarnavbg.gif&quot;&gt;&lt;font color=&quot;#FFFFFF&quot; size=&quot;3&quot; face=&quot;Arial, Helvetica, sans-serif&quot;&gt;&lt;strong&gt;About                    Us &lt;/strong&gt;&lt;/font&gt;&lt;/td&gt;               &lt;/tr&gt;               &lt;tr&gt;                  &lt;td valign=&quot;top&quot;&gt;&lt;p&gt;&lt;font size=&quot;2&quot; face=&quot;Arial, Helvetica, sans-serif&quot;&gt;&lt;strong&gt;&lt;br&gt;                     &lt;/strong&gt;Tech for Less LLC operates this outlet store. We                      have been in business online since early 2001 and we are one                      of the world&apos;s largest overstock vendors of new, open box,                      and refurbished computer equipment, peripherals and electronics.                      With a focus on sustainability, we do not manufacture new                      products. Rather, we sort, renew, and reintroduce existing                      products into the eBay marketplace. &lt;/font&gt;&lt;/p&gt;                   &lt;p&gt;&lt;font size=&quot;2&quot; face=&quot;Arial, Helvetica, sans-serif&quot;&gt;Our philosophy                      is simple. We want you to feel comfortable ordering all your                      computer and electronic needs from us. Not just today, but                      for years to come. That&apos;s why we guarantee your satisfaction.                      Check out our generous returns policy, and feel free to contact                      us with any questions.&lt;br&gt;                     &lt;/font&gt;&lt;/p&gt;                   &lt;p align=&quot;center&quot;&gt;&lt;font color=&quot;#1755ae&quot; size=&quot;2&quot; face=&quot;Arial, Helvetica, sans-serif&quot;&gt;&lt;strong&gt;&lt;font size=&quot;3&quot;&gt;Tech                      for Less&lt;br&gt;                     &lt;/font&gt;Name Brand Computers &amp;amp; Electronics...Same Technology,                      Lower Prices&lt;/strong&gt;&lt;/font&gt;&lt;/p&gt;                 &lt;/td&gt;               &lt;/tr&gt;             &lt;/table&gt;             &lt;/td&gt;         &lt;/tr&gt;       &lt;/table&gt;    &lt;/tr&gt; &lt;/table&gt; &lt;/body&gt; &lt;/html&gt; </Description>
    <GiftIcon>0</GiftIcon>
    <HitCounter>HiddenStyle</HitCounter>
    <ItemID>110093916181</ItemID>
    <ListingDetails>
     <Adult>false</Adult>
     <BindingAuction>false</BindingAuction>
     <CheckoutEnabled>true</CheckoutEnabled>
     <ConvertedBuyItNowPrice currencyID="EUR">0.0</ConvertedBuyItNowPrice>
     <ConvertedStartPrice currencyID="EUR">184.66</ConvertedStartPrice>
     <HasReservePrice>false</HasReservePrice>
     <StartTime>2011-11-14T21:07:38.000Z</StartTime>
     <EndTime>2012-09-09T21:07:38.000Z</EndTime>
     <ViewItemURL>http://cgi.sandbox.ebay.de/Asus-Eee-PC-Seashell-1005HA-VU1X-BK-Netbook-Intel-Atom-N270-1-6-GHz-Processor-/110093916181</ViewItemURL>
     <HasUnansweredQuestions>false</HasUnansweredQuestions>
     <HasPublicMessages>false</HasPublicMessages>
     <ExpressListing>false</ExpressListing>
     <ViewItemURLForNaturalSearch>http://cgi.sandbox.ebay.de/Asus-Eee-PC-Seashell-1005HA-VU1X-BK-Netbook-Intel-Atom-N270-1-6-GHz-Processor-/110093916181</ViewItemURLForNaturalSearch>
    </ListingDetails>
    <ListingDesigner>
     <LayoutID>10000</LayoutID>
     <ThemeID>10</ThemeID>
    </ListingDesigner>
    <ListingDuration>GTC</ListingDuration>
    <ListingType>FixedPriceItem</ListingType>
    <Location>Colorado Springs, Colorado</Location>
    <PaymentMethods>PayPal</PaymentMethods>
    <PrimaryCategory>
     <CategoryID>177</CategoryID>
     <CategoryName>Computers/Tablets &amp; Networking:Laptops &amp; Netbooks:PC Laptops &amp; Netbooks</CategoryName>
    </PrimaryCategory>
    <PrivateListing>false</PrivateListing>
    <ProductListingDetails>
     <ProductID>118513:2:2107:3704544885:339810925:d090ca76aa032b01284e6b10a55b0134:1:1:1:1398975633</ProductID>
     <IncludeStockPhotoURL>true</IncludeStockPhotoURL>
     <IncludePrefilledItemInformation>false</IncludePrefilledItemInformation>
     <UseStockPhotoURLAsGallery>false</UseStockPhotoURLAsGallery>
     <StockPhotoURL>http://i.ebayimg.com/00/$(KGrHqEOKooE1z-8RvL)BNs32DEg1w~~_7.JPG?set_id=89040003C1</StockPhotoURL>
     <ProductReferenceID>77833925</ProductReferenceID>
     <UPC>884840501831</UPC>
     <BrandMPN>
      <Brand>Asus</Brand>
      <MPN>1005HAVU1XBK</MPN>
     </BrandMPN>
    </ProductListingDetails>
    <Quantity>1</Quantity>
    <ReviseStatus>
     <ItemRevised>false</ItemRevised>
    </ReviseStatus>
    <Seller>
     <AboutMePage>false</AboutMePage>
     <Email>Invalid Request</Email>
     <FeedbackScore>6</FeedbackScore>
     <PositiveFeedbackPercent>87.5</PositiveFeedbackPercent>
     <FeedbackPrivate>false</FeedbackPrivate>
     <FeedbackRatingStar>None</FeedbackRatingStar>
     <IDVerified>true</IDVerified>
     <eBayGoodStanding>true</eBayGoodStanding>
     <NewUser>false</NewUser>
     <RegistrationDate>2004-05-27T00:00:00.000Z</RegistrationDate>
     <Site>US</Site>
     <Status>Confirmed</Status>
     <UserID>testuser_t4luser</UserID>
     <UserIDChanged>false</UserIDChanged>
     <UserIDLastChanged>2009-05-21T17:22:57.000Z</UserIDLastChanged>
     <VATStatus>NoVATTax</VATStatus>
     <SellerInfo>
      <AllowPaymentEdit>true</AllowPaymentEdit>
      <CheckoutEnabled>true</CheckoutEnabled>
      <CIPBankAccountStored>false</CIPBankAccountStored>
      <GoodStanding>true</GoodStanding>
      <LiveAuctionAuthorized>false</LiveAuctionAuthorized>
      <MerchandizingPref>OptIn</MerchandizingPref>
      <QualifiesForB2BVAT>false</QualifiesForB2BVAT>
      <StoreOwner>false</StoreOwner>
      <ExpressEligible>false</ExpressEligible>
      <ExpressWallet>false</ExpressWallet>
      <SafePaymentExempt>true</SafePaymentExempt>
     </SellerInfo>
     <MotorsDealer>false</MotorsDealer>
    </Seller>
    <SellingStatus>
     <BidCount>0</BidCount>
     <BidIncrement currencyID="USD">0.0</BidIncrement>
     <ConvertedCurrentPrice currencyID="EUR">184.66</ConvertedCurrentPrice>
     <CurrentPrice currencyID="USD">231.12</CurrentPrice>
     <MinimumToBid currencyID="USD">231.12</MinimumToBid>
     <QuantitySold>0</QuantitySold>
     <ReserveMet>true</ReserveMet>
     <SecondChanceEligible>false</SecondChanceEligible>
     <ListingStatus>Active</ListingStatus>
    </SellingStatus>
    <ShippingDetails>
     <ApplyShippingDiscount>false</ApplyShippingDiscount>
     <CalculatedShippingRate>
      <OriginatingPostalCode>80907</OriginatingPostalCode>
      <PackageDepth measurementSystem="English" unit="inches">4</PackageDepth>
      <PackageLength measurementSystem="English" unit="inches">13</PackageLength>
      <PackageWidth measurementSystem="English" unit="inches">10</PackageWidth>
      <ShippingIrregular>false</ShippingIrregular>
      <ShippingPackage>PackageThickEnvelope</ShippingPackage>
      <WeightMajor measurementSystem="English" unit="lbs">4</WeightMajor>
      <WeightMinor measurementSystem="English" unit="oz">0</WeightMinor>
      <InternationalPackagingHandlingCosts currencyID="USD">0.0</InternationalPackagingHandlingCosts>
     </CalculatedShippingRate>
     <InsuranceFee currencyID="USD">0.0</InsuranceFee>
     <InsuranceOption>NotOffered</InsuranceOption>
     <PaymentInstructions>Please note: This is a Refurbished product.  Please make sure that PayPal has your correct shipping address on file as we can not change your address once your order is placed. (sku: 1005HA-VU1X-BK )</PaymentInstructions>
     <SalesTax>
      <SalesTaxPercent>0.0</SalesTaxPercent>
      <ShippingIncludedInTax>false</ShippingIncludedInTax>
     </SalesTax>
     <ShippingServiceOptions>
      <ShippingService>Other</ShippingService>
      <ShippingServiceCost currencyID="USD">0.0</ShippingServiceCost>
      <ShippingServicePriority>1</ShippingServicePriority>
      <ExpeditedService>false</ExpeditedService>
      <ShippingTimeMin>1</ShippingTimeMin>
      <ShippingTimeMax>10</ShippingTimeMax>
      <FreeShipping>true</FreeShipping>
     </ShippingServiceOptions>
     <ShippingServiceOptions>
      <ShippingService>ShippingMethodStandard</ShippingService>
      <ShippingServiceCost currencyID="USD">1.99</ShippingServiceCost>
      <ShippingServicePriority>2</ShippingServicePriority>
      <ExpeditedService>false</ExpeditedService>
      <ShippingTimeMin>1</ShippingTimeMin>
      <ShippingTimeMax>5</ShippingTimeMax>
     </ShippingServiceOptions>
     <ShippingServiceOptions>
      <ShippingService>ShippingMethodExpress</ShippingService>
      <ShippingServiceCost currencyID="USD">8.06</ShippingServiceCost>
      <ShippingServicePriority>3</ShippingServicePriority>
      <ExpeditedService>false</ExpeditedService>
      <ShippingTimeMin>1</ShippingTimeMin>
      <ShippingTimeMax>3</ShippingTimeMax>
     </ShippingServiceOptions>
     <InternationalShippingServiceOption>
      <ShippingService>USPSPriorityMailInternational</ShippingService>
      <ShippingServicePriority>1</ShippingServicePriority>
      <ShipToLocation>Worldwide</ShipToLocation>
     </InternationalShippingServiceOption>
     <InternationalShippingServiceOption>
      <ShippingService>USPSExpressMailInternational</ShippingService>
      <ShippingServicePriority>2</ShippingServicePriority>
      <ShipToLocation>Worldwide</ShipToLocation>
     </InternationalShippingServiceOption>
     <InternationalShippingServiceOption>
      <ShippingService>UPSWorldWideExpedited</ShippingService>
      <ShippingServicePriority>3</ShippingServicePriority>
      <ShipToLocation>Americas</ShipToLocation>
      <ShipToLocation>Europe</ShipToLocation>
      <ShipToLocation>Asia</ShipToLocation>
      <ShipToLocation>AU</ShipToLocation>
     </InternationalShippingServiceOption>
     <ShippingType>FlatDomesticCalculatedInternational</ShippingType>
     <ThirdPartyCheckout>false</ThirdPartyCheckout>
     <TaxTable>
      <TaxJurisdiction>
       <JurisdictionID>CO</JurisdictionID>
       <SalesTaxPercent>7.4</SalesTaxPercent>
       <ShippingIncludedInTax>false</ShippingIncludedInTax>
      </TaxJurisdiction>
      <TaxJurisdiction>
       <JurisdictionID>IN</JurisdictionID>
       <SalesTaxPercent>7.0</SalesTaxPercent>
       <ShippingIncludedInTax>true</ShippingIncludedInTax>
      </TaxJurisdiction>
     </TaxTable>
     <InsuranceDetails>
      <InsuranceOption>NotOffered</InsuranceOption>
     </InsuranceDetails>
     <InternationalInsuranceDetails>
      <InsuranceOption>NotOffered</InsuranceOption>
     </InternationalInsuranceDetails>
     <ShippingDiscountProfileID>0</ShippingDiscountProfileID>
     <InternationalShippingDiscountProfileID>0</InternationalShippingDiscountProfileID>
     <SellerExcludeShipToLocationsPreference>false</SellerExcludeShipToLocationsPreference>
    </ShippingDetails>
    <ShipToLocations>Worldwide</ShipToLocations>
    <Site>US</Site>
    <StartPrice currencyID="USD">231.12</StartPrice>
    <TimeLeft>P3DT12H51M38S</TimeLeft>
    <Title>Asus Eee PC Seashell 1005HA-VU1X-BK Netbook - Intel Atom N270 1.6 GHz Processor</Title>
    <HitCount>0</HitCount>
    <LocationDefaulted>true</LocationDefaulted>
    <SKU>1005HA-VU1X-BKC_23</SKU>
    <PostalCode>80907</PostalCode>
    <PictureDetails>
     <GalleryType>Gallery</GalleryType>
     <GalleryURL>http://www.techforless.com/cimages/111132.JPG</GalleryURL>
     <PhotoDisplay>PicturePack</PhotoDisplay>
     <PictureURL>http://www.techforless.com/cimages/111132.JPG</PictureURL>
     <PictureSource>Vendor</PictureSource>
    </PictureDetails>
    <ProxyItem>false</ProxyItem>
    <BuyerGuaranteePrice currencyID="EUR">20000.0</BuyerGuaranteePrice>
    <ReturnPolicy>
     <RefundOption>MoneyBack</RefundOption>
     <Refund>Money Back</Refund>
     <ReturnsWithinOption>Days_30</ReturnsWithinOption>
     <ReturnsWithin>30 Days</ReturnsWithin>
     <ReturnsAcceptedOption>ReturnsAccepted</ReturnsAcceptedOption>
     <ReturnsAccepted>Returns Accepted</ReturnsAccepted>
     <Description>Tech For Less offers a generous (45) day return / replacement policy for all products that do not meet or exceed the condition described in the Product Description. Tech For Less LLC shall determine whether to provide a replacement or a refund once a return has been authorized. An RMA (Return Materials Authorization) number must be requested within (45) Days of the Invoice Date. Please contact us with questions</Description>
     <ShippingCostPaidByOption>Buyer</ShippingCostPaidByOption>
     <ShippingCostPaidBy>Buyer</ShippingCostPaidBy>
    </ReturnPolicy>
    <PaymentAllowedSite>eBayMotors</PaymentAllowedSite>
    <PaymentAllowedSite>CanadaFrench</PaymentAllowedSite>
    <PaymentAllowedSite>Canada</PaymentAllowedSite>
    <PaymentAllowedSite>US</PaymentAllowedSite>
    <ConditionID>3000</ConditionID>
    <ConditionDisplayName>Used</ConditionDisplayName>
    <PostCheckoutExperienceEnabled>false</PostCheckoutExperienceEnabled>
    <ShippingPackageDetails>
     <PackageDepth measurementSystem="English" unit="inches">4</PackageDepth>
     <PackageLength measurementSystem="English" unit="inches">13</PackageLength>
     <PackageWidth measurementSystem="English" unit="inches">10</PackageWidth>
     <ShippingIrregular>false</ShippingIrregular>
     <ShippingPackage>PackageThickEnvelope</ShippingPackage>
     <WeightMajor measurementSystem="English" unit="lbs">4</WeightMajor>
     <WeightMinor measurementSystem="English" unit="oz">0</WeightMinor>
    </ShippingPackageDetails>
   </Item>
  </GetItemResponse>
 </soapenv:Body>
</soapenv:Envelope>'
      
      # we have to fake an HTTPI::Response object
      http_response = Hashie::Mash.new()
      http_response.body = resp
      
      savon_response = Savon::SOAP::Response.new(Savon.config.clone, http_response)
          
      response_type = @client.send(:create_response_type, savon_response.body.to_hash)
      response_type.should_not be_nil
      
      response_type.version.should eq 787.to_s
      
      response_type.class_name.should eq "GetItemResponseType"
      response_type.item.country.should eq "US"
      response_type.item.primary_category.category_id.should eq "177"
      
      response_type.item.shipping_details.should_not be_nil
      response_type.item.shipping_details.shipping_service_options.class.should be Array
      response_type.item.shipping_details.shipping_service_options.size.should be 3
      response_type.item.shipping_details.shipping_service_options.first.class_name.should eq "ShippingServiceOption"
      
      #response_type.category_array.category.size.should be 2
      
      #puts "to_s: #{response_type.to_s}"   
      
    end
    
    
    
    it "should handle complex types in arrays correctly" do
      test_xml = '    <ShippingDetails>
     <ApplyShippingDiscount>false</ApplyShippingDiscount>
     <CalculatedShippingRate>
      <OriginatingPostalCode>80907</OriginatingPostalCode>
      <PackageDepth measurementSystem="English" unit="inches">4</PackageDepth>
      <PackageLength measurementSystem="English" unit="inches">13</PackageLength>
      <PackageWidth measurementSystem="English" unit="inches">10</PackageWidth>
      <ShippingIrregular>false</ShippingIrregular>
      <ShippingPackage>PackageThickEnvelope</ShippingPackage>
      <WeightMajor measurementSystem="English" unit="lbs">4</WeightMajor>
      <WeightMinor measurementSystem="English" unit="oz">0</WeightMinor>
      <InternationalPackagingHandlingCosts currencyID="USD">0.0</InternationalPackagingHandlingCosts>
     </CalculatedShippingRate>
     <InsuranceFee currencyID="USD">0.0</InsuranceFee>
     <InsuranceOption>NotOffered</InsuranceOption>
     <PaymentInstructions>Please note: This is a Refurbished product. </PaymentInstructions>
     <SalesTax>
      <SalesTaxPercent>0.0</SalesTaxPercent>
      <ShippingIncludedInTax>false</ShippingIncludedInTax>
     </SalesTax>
     <ShippingServiceOptions>
      <ShippingService>Other</ShippingService>
      <ShippingServiceCost currencyID="USD">0.0</ShippingServiceCost>
      <ShippingServicePriority>1</ShippingServicePriority>
      <ExpeditedService>false</ExpeditedService>
      <ShippingTimeMin>1</ShippingTimeMin>
      <ShippingTimeMax>10</ShippingTimeMax>
      <FreeShipping>true</FreeShipping>
     </ShippingServiceOptions>
     <ShippingServiceOptions>
      <ShippingService>ShippingMethodStandard</ShippingService>
      <ShippingServiceCost currencyID="USD">1.99</ShippingServiceCost>
      <ShippingServicePriority>2</ShippingServicePriority>
      <ExpeditedService>false</ExpeditedService>
      <ShippingTimeMin>1</ShippingTimeMin>
      <ShippingTimeMax>5</ShippingTimeMax>
     </ShippingServiceOptions>
     <ShippingServiceOptions>
      <ShippingService>ShippingMethodExpress</ShippingService>
      <ShippingServiceCost currencyID="USD">8.06</ShippingServiceCost>
      <ShippingServicePriority>3</ShippingServicePriority>
      <ExpeditedService>false</ExpeditedService>
      <ShippingTimeMin>1</ShippingTimeMin>
      <ShippingTimeMax>3</ShippingTimeMax>
     </ShippingServiceOptions>
     <InternationalShippingServiceOption>
      <ShippingService>USPSPriorityMailInternational</ShippingService>
      <ShippingServicePriority>1</ShippingServicePriority>
      <ShipToLocation>Worldwide</ShipToLocation>
     </InternationalShippingServiceOption>
     <InternationalShippingServiceOption>
      <ShippingService>USPSExpressMailInternational</ShippingService>
      <ShippingServicePriority>2</ShippingServicePriority>
      <ShipToLocation>Worldwide</ShipToLocation>
     </InternationalShippingServiceOption>
     <InternationalShippingServiceOption>
      <ShippingService>UPSWorldWideExpedited</ShippingService>
      <ShippingServicePriority>3</ShippingServicePriority>
      <ShipToLocation>Americas</ShipToLocation>
      <ShipToLocation>Europe</ShipToLocation>
      <ShipToLocation>Asia</ShipToLocation>
      <ShipToLocation>AU</ShipToLocation>
     </InternationalShippingServiceOption>
     <ShippingType>FlatDomesticCalculatedInternational</ShippingType>
     <ThirdPartyCheckout>false</ThirdPartyCheckout>
     <TaxTable>
      <TaxJurisdiction>
       <JurisdictionID>CO</JurisdictionID>
       <SalesTaxPercent>7.4</SalesTaxPercent>
       <ShippingIncludedInTax>false</ShippingIncludedInTax>
      </TaxJurisdiction>
      <TaxJurisdiction>
       <JurisdictionID>IN</JurisdictionID>
       <SalesTaxPercent>7.0</SalesTaxPercent>
       <ShippingIncludedInTax>true</ShippingIncludedInTax>
      </TaxJurisdiction>
     </TaxTable>
     <InsuranceDetails>
      <InsuranceOption>NotOffered</InsuranceOption>
     </InsuranceDetails>
     <InternationalInsuranceDetails>
      <InsuranceOption>NotOffered</InsuranceOption>
     </InternationalInsuranceDetails>
     <ShippingDiscountProfileID>0</ShippingDiscountProfileID>
     <InternationalShippingDiscountProfileID>0</InternationalShippingDiscountProfileID>
     <SellerExcludeShipToLocationsPreference>false</SellerExcludeShipToLocationsPreference>
    </ShippingDetails>'
      

      input = @client.generate_type("ShippingDetailsType")
      
      #create_response_type(hash)
      
    end
    
    
  end
  
end
