require "savon"
require "ebay/string_ext/string"

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
            @parser = @wsdl_document.parser
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
          
          op = @parser.operations
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
      # Executes the action given in the first parameter. The value of the parameter
      # is used "as-it-is". It should be the CamelCaseVersion.
      # ------------------------------------------------------------------
      def execute_soap_action(soap_action, soap_input)
        set_soap_header()
        set_wsdl_endpoint(soap_action)
        
        response = @soap_client.request :urn, soap_action do  
          soap.body = soap_input.to_camel_case()
        end
        
        create_response_type(response.body.to_hash) unless response.nil? || response.body.nil?
        
        
      end
 
      
      private
      
      
      # ------------------------------------------------------------------
      # Creates an object tree from the ebay response. The action is not relevant,
      # we're relying only on the response. The input parameter is expected to be
      # a hash with one or more keys. The following steps are done once per key
      # (typically there's only one)
      #
      # The method calls itself recursivly. So be careful...
      #
      # 1. step: create a (wsdl-) type that matches the key of the hash.
      #          the hash is expected to be something like {:wsdl_name => {attributes}}
      #
      # 2. step: process the attributes of the type. The work is handed to a second
      #          method. In case of structured attributes even more methods appear.
      # ------------------------------------------------------------------
      def create_response_type(response_hash)
        response_type = nil
        
        response_hash.each_pair do |key, val|
        
          #puts "[create_response_type] key, val: #{key}, #{val.class} (#{val.keys.join(', ')})"
          
          response_type_name = get_type_name_for(key)
          
          response_type = generate_type(response_type_name.to_camel_case)
          
          fill_response_types_attributes(response_type, response_type_name.to_camel_case, val)
          
        end
        
        response_type
      end
      
      
      def get_type_name_for(key)
        if (key.to_s.downcase.end_with?("type")) then
          key.to_s
        else
          key.to_s + "_type"
        end
      end
      
      
      # ------------------------------------------------------------------
      # Parses the wsdl document and creates a class that matches the requirements
      # for the wsdl complex type for the given name. We generate getters and
      # setters for each attribute.
      #
      # The new class is cached. The type_name has to be CamelCase (depends on your wsdl)
      # ------------------------------------------------------------------
      def create_type(type_name)
        class_attributes = Array.new()
        
        #puts "[create_type] looking up type name: #{type_name}"
        @parser.types[type_name].keys.each() do |m|
        
          attr = if (m.is_a?(Symbol)) then m else m.snakecase.to_sym end
          class_attributes << attr
          
        end
        
        wsdl_class = create_class_for_wsdl_type(type_name, class_attributes)
        
        EbayClient.wsdl_classes[type_name.to_sym] = wsdl_class
        wsdl_class
      end
      
      
      # ------------------------------------------------------------------
      # This fills the attributes of the wsdl-instance. We're filtering the
      # @xmlns attribute.
      #
      # There are three cases to watch out:
      #   a) the attribute value itself is a hash. We call the create_response_type
      #      method recursively. This way subtypes are created.
      #
      #   b) the attribute value is an array. That is even worse. We have a list of
      #      subtypes. These subtypes may be complex types or simple ones. To decide
      #      we peek at the first one. If it's a complex one we fake a hash for 
      #      each one and call create_response_type. The results are collected in
      #      an array and attached to the top attribute. If it's a simple one we
      #      just add the array filled with the values
      #
      #   c) the attribute value is a simple type. Hey that's easy, simply set the
      #      value.
      # ------------------------------------------------------------------
      def fill_response_types_attributes(type_instance, type_name, attributes)
        
        attributes.each_pair do |attr, attr_val|
            
            unless (attr.to_s == "@xmlns")
            
              puts "attr: #{attr} is #{attr_val.class.to_s}"
            
              v= if (attr_val.class == Hash) then
                
                #puts "creating hash subtype: #{attr} for parent #{type_name}"
                
                subtype_to_create = lookup_which_subtype_to_create(type_name, attr.to_s)
                #puts "parser tells us to create this: #{subtype_to_create}"
                create_response_type({subtype_to_create => attr_val})
                
              elsif (attr_val.class == Array) then
                
                puts "creating array subtype: for key #{attr} for parent #{type_instance.class_name}"
                a = Array.new()
                
                if has_complex_types?(a, attr) then
                  
                  puts "has_complex_types"
                  
                  attr_val.each() do |i|
                    h = Hash.new
                    h[attr] = i
                    a << create_response_type(h)
                  end
                else
                  
                  puts "does_not_have_complex_types"
                  
                  attr_val.each do |i|
                    a << i.to_s
                  end
                end
                
                a
              else
                v = attr_val
              end
              
              type_instance.send("#{attr}=", v) 
            end
          end
      end      
      
      
      # ------------------------------------------------------------------
      # Checks if the first element meets these rules:
      #
      #   - it is a hash
      #   - there's a type for attr in @parser.types
      # ------------------------------------------------------------------
      def has_complex_types?(a, attr)
        
        attr_type_name = get_type_name_for(attr)
        
        !a.nil? && !a.empty? && !attr_type_name.nil? && @parser.types.include?(attr_type_name.to_camel_case)
      end
      
      
      
      # ------------------------------------------------------------------
      # Takes the name of the parent element and the attribute and looks into 
      # the wsdl which type the child has.
      #
      # First we look for a direkt hit (case sensitive). If nothing is found
      # we try case insensitive.
      #
      # Example:
      #<xs:complexType name="GetCategoryFeaturesResponseType">
      #  <xs:complexContent>
      #    <xs:sequence>
      #            <xs:element name="CategoryVersion" type="xs:string"></xs:element>
      #            <xs:element name="UpdateTime" type="xs:dateTime"></xs:element>
      #            <xs:element name="Category" type="ns:CategoryFeatureType"></xs:element>
      #            <xs:element name="SiteDefaults" type="ns:SiteDefaultsType"></xs:element>
      #            <xs:element name="FeatureDefinitions" type="ns:FeatureDefinitionsType"></xs:element>
      #    </xs:sequence>
      #  </xs:complexContent>
      #</xs:complexType>
      #
      # lookup_which_subtype_to_create("GetCategoryFeaturesResponseType", "Category")
      # returns "CategoryFeatureType". The "ns:" is cut off
      # ------------------------------------------------------------------
      def lookup_which_subtype_to_create(parent_name, attr_name)
        begin
          attr = attr_name.to_s.to_camel_case
          
          p = @parser.types[parent_name]
          a = p[attr]
          a = p.select{|pk| pk.downcase == attr.downcase}.values.first if a.nil?
          
          s = a[:type]
          
          subtype = s.gsub(/ns:/, '')
          
          subtype
          
        rescue Exception => e
          puts "Exception: #{e.to_s} parent_name: #{parent_name} attr_name: #{attr_name} attr: #{attr}"
          nil
        end 
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
            "#{self.class.class_name.to_s} => {" +
            self.class.wsdl_attributes.collect {|a| "#{a}: #{self.send(a.to_sym)}"}.join(",") + "}"
            
          end
          
          def class_name
            self.class.class_name
          end
          
          
          def to_camel_case
            h = Hash.new
            
            self.class.wsdl_attributes.each() do |attr|
              
              cc_attr = attr.to_s.to_camel_case
              
              h[cc_attr] = send(attr)
            end
            
            h
          end
          
          
          def method_missing(name, *args)
            if args.size == 1 && name.to_s =~ /(.*)=$/
              
              attr_name = name.to_s.chomp("=")
              puts "WARNING setting unknown attribute #{attr_name} to #{args.first} in class #{self.class_name}"
              
              return
            end
    
            super
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
      
      
      def set_wsdl_endpoint(soap_action)
        
        endpoint = if (EbayClient.route_to_sandbox) then "https://api.sandbox.ebay.com/wsapi"
                      else "https://api.hier_sollte_prod_stehen.ebay.com/wsapi"
                      end
        
        
        @soap_client.wsdl.endpoint = endpoint + "?" +
                                    "callname=#{soap_action}&" +
                                    "siteid=#{EbayClient.site_id}&" +
                                    #"appid=#{EbayClient.app_id}&" + 
                                    "routing=default"  
      end

    
      
    end # ebay_client
    
    
    
    
  end  # trading
end   # ebay
