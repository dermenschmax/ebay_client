# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)


Gem::Specification.new do |s|
  s.name        = "ebay_client"
  s.version     = 0.1
  s.author      = "Max Mensch"
  s.email       = "der.mensch.max@googlemail.com"
  s.homepage    = "https://github.com/dermenschmax"
  s.summary     = "A Ruby client for the ebay trading api based on savon"
  s.description = "A Ruby client for the ebay trading api based on savon"

  
  #s.required_rubygems_version = ">= 1.3.4"
  
  s.add_dependency("savon")
  s.add_dependency("rake")
  
  #s.add_dependency("libxml-ruby", ["~> 2.3.0"])
end
