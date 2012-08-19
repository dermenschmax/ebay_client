require "savon"


# ------------------------------------------------------------------------------
# This holds the EbayClient class that handles all communications with the
# Trading API.
#
# The client parses the wsdl file of the ebay trading api and offers methods
# matching the soap operations. The object types are generated on the fly as
# needed. The parsing is done at the time of creation.
#
# The attributes for the authentication are here: app_id, dev_id, cert_id,
# auth_token. They can be set by requiring a config.rb.
#
# Some configurations are done on class level:
#   - the Ebay site (US, Germay, ...)
#   - authentication
#   - wsdl stuff
#   - sandbox
#
# You cannot change them for a client instance. Talking to multiple ebays doesn't
# make any sense to me.
# ------------------------------------------------------------------------------


module Ebay
  
  module Trading
    
    class EbayClient
      
      
      # set the class instance variables:
      #  - wsdl filename
      #  - wsdl_classes
      #  - wsdl_version       -> the version number of the wsdl file, this will 
      #                          be in the soap call
      #  - route_to_sandbox   -> testing yes/no
      #  - side_id            -> connect to which site (77 => Germany)
      #  - app_id             -> the application id you get from the ebay dev center
      #  - dev_id             -> get one on ebay dev
      #  - cert_id            -> your certificate
      #  - auth_token         -> should be obvious
      class << self
        attr_accessor :wsdl_file_name
        attr_accessor :wsdl_classes
        attr_accessor :wsdl_version
        attr_accessor :route_to_sandbox
        attr_accessor :site_id
        
        attr_accessor :app_id
        attr_accessor :dev_id
        attr_accessor :cert_id
        attr_accessor :auth_token
      end      
    
    
    
      # ------------------------------------------------------------------
      # Sets some defaults in the 
      # ------------------------------------------------------------------      
      def initialize
        EbayClient.wsdl_classes ||= Hash.new()
        EbayClient.route_to_sandbox ||= true
        EbayClient.site_id ||= 77
        
        @wsdl_document = nil
        @soap_client = Savon.client File.expand_path(EbayClient.wsdl_file_name(), __FILE__)
      end
    
    
    
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
      
      
      
      # ------------------------------------------------------------------
      # Soap Action "GetCategories"
      #  TODO: dynamisch?
      # ------------------------------------------------------------------
      def get_categories(soap_input, params)
        set_soap_header()
        
        endpoint = if (EbayClient.route_to_sandbox) then "https://api.sandbox.ebay.com/wsapi"
                      else "https://api.hier_sollte_prod_stehen.ebay.com/wsapi"
                      end
        
        action = "GetCategories"
        
        @soap_client.wsdl.endpoint = endpoint + "?" +
                                    "callname=#{action}&" +
                                    "siteid=#{EbayClient.site_id}&" +
                                    #"appid=#{EbayClient.app_id}&" + 
                                    "routing=default"  
        
        
        response = @soap_client.request :urn, action do  
          soap.body = params
        end
        
        response
        
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
        parser = @wsdl_document.parser
        class_attributes = Array.new()
        
        parser.types[type_name].keys.each() do |m|
        
          attr = if (m.is_a?(Symbol)) then m else m.snakecase.to_sym end
          class_attributes << attr
          
        end
        
        wsdl_class = create_class_for_wsdl_type(type_name, class_attributes)
        
        EbayClient.wsdl_classes[type_name.to_sym] = wsdl_class
        wsdl_class
      end
      
      
      
      
      # ------------------------------------------------------------------
      # This creates a class to represent a wsdl type. It has these features:
      #
      #  - attributes that match the wsdl definition
      #  - to_s prints the wsdl type name  (Parameter class_name)
      #  - the to_camel_case method generates a hash with CamelCase keys that is
      #    used for the soap request
      # ------------------------------------------------------------------
      def create_class_for_wsdl_type(class_name, attribute_list)
        
        new_class = Class.new() do
        
          class << self
            attr_accessor :class_name
            attr_reader :wsdl_attributes
          end
          
          def to_s
            self.class.class_name
          end
          
          def to_camel_case
            h = Hash.new
            
            self.class.wsdl_attributes.each() do |attr|
              
              cc_attr = ""
              attr.to_s.each_line("_") do |a|
                cc_attr += if (a.chomp("_") == "id") then "ID" else a.chomp("_").capitalize end
              end
              
              h[cc_attr] = send(attr)
            end
            
            h
          end
          
          
          @wsdl_attributes = Array.new()
          attribute_list.each() do |attr|
            attr_accessor attr.to_sym
            @wsdl_attributes << attr
          end
          
        end
        
        new_class.class_name = class_name
        
        new_class
      end
      
      
      # ------------------------------------------------------------------
      # We have to set some special values in the soap header for authentication.
      #
      # ------------------------------------------------------------------
      def set_soap_header
        @soap_client.config.soap_header = {
          "urn:RequesterCredentials" => {
            "urn:eBayAuthToken" => EbayClient.auth_token,  
            "urn:Credentials" => {
              "urn:AppId" => EbayClient.app_id, "urn:DevId" => EbayClient.dev_id,
              "urn:AuthCert" => EbayClient.cert_id
            }
        }
      }
      end
      
    
      
    end # ebay_client
    
    
    
    
  end  # trading
end   # ebay
