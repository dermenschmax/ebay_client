
# ------------------------------------------------------------------------------
# This type offers a generic base for the dynamically created wsdl types. It 
# defines some common methods and attributes.
#
# ------------------------------------------------------------------------------

module Ebay

  class GenericEbayType
    
    attr_reader :class_name
    
    
    def initialize(name)
      @class_name = name
      @attr = Array.new()
    end
    
    
    def to_s
      @class_name
    end
    
    def add_attribute(name)
      attr_accessor name.to_sym
    end
  end

end