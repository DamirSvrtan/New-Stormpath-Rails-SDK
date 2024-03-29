require "active_support/core_ext/class/attribute_accessors"
require "generator_spec/test_case"
require "generators/stormpath/rails/migration/migration_generator"
require 'pry-debugger'

describe Stormpath::Rails::Generators::MigrationGenerator do
  include GeneratorSpec::TestCase
  destination File.expand_path("../tmp", __FILE__)
  arguments %w(person)

  before do
    Stormpath::Rails::Generators::MigrationGenerator.any_instance.stub(:migration_time).and_return("0")
    prepare_destination
    run_generator
  end

  it "creates migration file" do
    assert_file "db/migrate/0_add_stormpath_url_to_people.rb", "class AddStormpathUrlToPeople < ActiveRecord::Migration\n  def up\n    add_column :people, :stormpath_url, :string\n    add_index :people, :stormpath_url\n  end\n\n  def down\n    remove_column :people, :stormpath_url\n  end\nend"
  end
end
