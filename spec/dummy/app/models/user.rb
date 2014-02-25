class User < ActiveRecord::Base
  include Stormpath::Rails::Account
end