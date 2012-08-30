require "ebay/string_ext/string"


describe Ebay::StringExt::String do
  
  it "should transform snakecase to camelcase" do
    "hello_world".to_camel_case.should eq "HelloWorld"
  end
  
  it "should not destroy camel case strings" do
    "HelloWorld".to_camel_case.should eq "HelloWorld"
  end
  
  it "should work with empty string" do
    "".to_camel_case.should eq ""
  end
  
end
