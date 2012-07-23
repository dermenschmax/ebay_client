require "wasabi"


# ------------------------------------------------------------------------------
# This holds the EbayClient class that handles all communications with the
# Trading API.
#
# The client parses the wsdl file of the ebay trading api and offers methods
# matching the soap operations. The object types are generated on the fly as
# needed.
# ------------------------------------------------------------------------------


module Ebay
  
  module Trading
    
    class EbayClient
      
      
      # set the wsdl filename as class instance variable
      class << self
        attr_accessor :wsdl_file_name
      end
      
      
      
      def initialize
        @wsdl_document = nil
      end
      
      
      # ------------------------------------------------------------------
      #
      # Lists all available operations (soap actions) listed in the wsdl
      #
      # Format:
      #     operation => { :action => soap name, :input => input type,
      #                    :namespace => the namespace, :output=> output type}
      # ------------------------------------------------------------------
      def operations
        
        
        unless (EbayClient.wsdl_file_name.nil?)
          
          if (@wsdl_document.nil?) then
            @wsdl_document = Wasabi::Document.new()
            @wsdl_document.document = EbayClient.wsdl_file_name
          end
          
          parser = @wsdl_document.parser
          op = parser.operations
          op.keys.each() do |k|
            output = op[k][:action]+"ResponseType"
            input = op[k][:action]+"RequestType"
            op[k][:input] = input
            op[k][:output] = output
          end
          
          op
        end
        
        
      end
      
      
    end
    
    
    
    
  end
  
end
