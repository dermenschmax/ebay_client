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
      
    
      # ------------------------------------------------------------------
      #
      # Ensures that EbayClient.wsdl_file_name is set. Throws an exception if not
      #
      # ------------------------------------------------------------------
      def check_wsdl_file_name
        raise "no wsdl file specified" if EbayClient.wsdl_file_name.nil?
      end
    
    
      
      # ------------------------------------------------------------------
      #
      # Ensures that @wsdl_document is set. The wsdl filename has to be set which
      # is checked. An exception is thrown if not.
      #
      # ------------------------------------------------------------------
      def check_wasabi_document

        check_wsdl_file_name()

        if (@wsdl_document.nil?) then
            @wsdl_document = Wasabi::Document.new()
            @wsdl_document.document = EbayClient.wsdl_file_name
          end
      end
      
      
      
      # set the class instance variables:
      #  - wsdl filename
      #  - wsdl_classes
      class << self
        attr_accessor :wsdl_file_name
        attr_accessor :wsdl_classes
      end
      
      
      
      def initialize
        @wsdl_document = nil
        EbayClient.wsdl_classes ||= Hash.new()
      end
      
      
      # ------------------------------------------------------------------
      #
      # Lists all available operations (soap actions) listed in the wsdl. The
      # wsdl document name has to be set.
      #
      # Format:
      #     operation => { :action => soap name, :input => input type,
      #                    :namespace_identifier => the namespace, :output=> output type}
      # ------------------------------------------------------------------
      def operations
      
        check_wasabi_document()  
        
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
      
      
      # ------------------------------------------------------------------
      #
      # Generates the objects you need to talk to the api. Returns an instance
      # of a class that matches the definition of a complex type in the wsdl
      # file of the given name.
      #
      # We're caching the types we create. If necessary a class is created that
      # matches the wsdl definition of the given type.
      #
      # The wsdl document name has to be set.
      #
      # ------------------------------------------------------------------
      def generate_type(type_name)
        
        check_wasabi_document()
        
        type_class = EbayClient.wsdl_classes[type_name.to_sym]  || create_type(type_name)
        
        type_class.new()
      end
      
      
      
      
      private
      
      
      # ------------------------------------------------------------------
      # Parses the wsdl document and creates a class that matches the requirements
      # for the wsdl complex type for the given name. We generate getters and
      # setters for each attribute.
      #
      # The new class is cached.
      # ------------------------------------------------------------------
      def create_type(type_name)
        
        wsdl_class = Class.new()
        parser = @wsdl_document.parser
        
        parser.types[type_name].keys.each() do |m|
        
          attr = if (m.is_a?(Symbol)) then m else m.snakecase.to_sym end
          
          wsdl_class.send(:attr_accessor, attr)
        end
        
        EbayClient.wsdl_classes[type_name.to_sym] = wsdl_class
        wsdl_class
      end
      
      
    end # ebay_client
    
    
    
    
  end  # trading
end   # ebay
