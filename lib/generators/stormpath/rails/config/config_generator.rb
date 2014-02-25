require "active_support/core_ext/string/inflections"

module Stormpath
  module Rails
    module Generators
      class ConfigGenerator < ::Rails::Generators::Base
        source_root File.expand_path('../../templates', __FILE__)

        def create_migration_file
          template "stormpath_config.rb", "config/initializers/stormpath_rails.rb"
        end

      end
    end
  end
end
