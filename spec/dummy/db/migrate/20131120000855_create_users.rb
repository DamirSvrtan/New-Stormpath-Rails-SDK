# This migration comes from phrasing_rails_engine (originally 20120313191745)
class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :stormpath_url
      t.timestamps
    end
  end
end
