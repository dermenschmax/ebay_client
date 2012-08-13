require "ebay/types/generic_ebay_type"


describe Ebay::GenericEbayType do
  
  
  it "should be valid" do
    gt = Ebay::GenericEbayType.new("hallo")
    
    gt.should_not be_nil
  end
  
  
  
end
