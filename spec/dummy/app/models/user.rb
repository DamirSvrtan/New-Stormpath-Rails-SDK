class User < ActiveRecord::Base
  include Stormpath::Rails::Account
  custom_data_attributes :age, :favorite_color
end