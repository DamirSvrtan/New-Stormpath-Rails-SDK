require "active_support/core_ext/class/attribute_accessors"
require "generator_spec/test_case"
require "generators/stormpath/rails/config/config_generator"
require 'pry-debugger'

describe Stormpath::Rails::Generators::ConfigGenerator do
  include GeneratorSpec::TestCase
  destination File.expand_path("../tmp", __FILE__)

  before do
    prepare_destination
    run_generator
  end

  it "creates configuration file" do
    assert_file "config/initializers/stormpath_rails.rb", /def self.client\n/
  end
end
