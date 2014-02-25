# Note: If SimpleCov starts after your application code is already loaded (via require),
# it won't be able to track your files and their coverage! The SimpleCov.start must be
# issued before any of your application code is required!
require 'simplecov'
SimpleCov.start

ENV["RAILS_ENV"] = 'test'
require File.expand_path("../dummy/config/environment.rb", __FILE__)

require "vcr"
require "webmock"
require "pry"
require "pry-debugger"
require 'stormpath-rails'

Dir["./spec/support/**/*.rb"].sort.each {|f| require f}

module Stormpath
  class TestEnvironmentConfigurator
    
    def self.verify_setup

      unless ENV["STORMPATH_RAILS_TEST_API_KEY_FILE_LOCATION"]
        raise <<-message
          Must specify either STORMPATH_RAILS_TEST_API_KEY_FILE_LOCATION or
          STORMPATH_RAILS_TEST_API_KEY_SECRET and STORMPATH_RAILS_TEST_API_KEY_ID
          in order to run tests.
        message
      end

      unless ENV["STORMPATH_RAILS_TEST_APPLICATION_URL"]
        raise <<-message
          Must specify STORMPATH_RAILS_TEST_APPLICATION_URL so that tests have
          an Application Resource to run against.
        message
      end

      unless ENV["STORMPATH_RAILS_TEST_DIRECTORY_WITH_VERIFICATION_URL"]
        raise <<-message
          Must specify STORMPATH_RAILS_TEST_DIRECTORY_WITH_VERIFICATION_URL so that tests have
          an Directory with a Email Verification Workflow enable to run against.
        message
      end
    end

  end
end

RSpec.configure do |config|
  config.mock_framework = :rspec
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.before(:all) { Stormpath::TestEnvironmentConfigurator.verify_setup }
end

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  c.hook_into :webmock
  c.configure_rspec_metadata!
end
