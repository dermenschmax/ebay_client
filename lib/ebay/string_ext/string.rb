module Ebay
  module StringExt
    module String
  
      def self.included(base)
        unless "hallo".respond_to?(:to_camel_case)
          base.send(:include, Extension)
        end
      end
    
      module Extension
        def to_camel_case()
          str = dup
          
          camel_case = ""
          str.to_s.each_line("_") do |s|
            camel_case += if (s.chomp("_") == "id") then "ID" else s.chomp("_").capitalize end
          end
          
          camel_case
        end
      end
    end
  end
end

String.send :include, Ebay::StringExt::String