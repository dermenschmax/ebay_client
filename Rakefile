
require 'rspec/core/rake_task'



desc 'Default: run specs.'
task :default => :run_all_specs



desc "run all tests on spec/ebay/string_ext"
RSpec::Core::RakeTask.new(:run_all_string_specs) do |t|
  t.pattern = "--tag string" # don't need this, it's default.
end


desc "run all tests on spec/ebay/trading"
RSpec::Core::RakeTask.new(:run_all_trading_specs) do |t|
  t.pattern = " --tag complete_trading"
end


desc "run basic tests on spec/ebay/trading"
RSpec::Core::RakeTask.new(:run_basic_trading_specs) do |t|
  t.pattern = " --tag trading:basic"
end


desc "run item tests on spec/ebay/trading"
RSpec::Core::RakeTask.new(:run_item_trading_specs) do |t|
  t.pattern = " --tag trading:item"
end


desc "Run all specs"
RSpec::Core::RakeTask.new(:run_all_specs) do |t|
  t.pattern = "./spec/**/*_spec.rb" # don't need this, it's default.
  # Put spec opts in a file named .rspec in root
end