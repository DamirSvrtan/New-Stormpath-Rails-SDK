require 'active_support/concern'
require "stormpath-sdk"

module Stormpath
  module Rails
    module Account
      extend ActiveSupport::Concern

      STORMPATH_FIELDS = [ :email, :password, :username, :given_name, :middle_name, :surname, :status, :full_name ]

      module ClassMethods

        def authenticate username, password
          login_request = Stormpath::Authentication::UsernamePasswordRequest.new username, password
          auth_result = Stormpath::Rails.application.authenticate_account login_request
          account = auth_result.account
          self.where(stormpath_url: account.href).first
        end

        def send_password_reset_email email
          account = Stormpath::Rails.application.send_password_reset_email email
          self.where(stormpath_url: account.href).first
        end

        def verify_password_reset_token token
          account = Stormpath::Rails.application.verify_password_reset_token token
          self.where(stormpath_url: account.href).first
        end

        def verify_email_token token
          account = Stormpath::Rails.client.accounts.verify_email_token token
          self.where(stormpath_url: account.href).first
        end

      end

      included do
        #AR specific workaround
        self.partial_updates = false if self.respond_to?(:partial_updates)

        #Mongoid specific declaration
        field(:stormpath_url, type: String) if self.respond_to?(:field)
        index({ stormpath_url: 1 }, { unique: true }) if self.respond_to?(:index)

        before_create :create_account_on_stormpath
        before_update :update_account_on_stormpath
        after_destroy :delete_account_on_stormpath

        def self.custom_data_attributes(*attributes)
          @@custom_data_attributes = attributes

          attributes.each do |attribute|
            define_method(attribute) do
              if stormpath_account.present?
                stormpath_account.custom_data[attribute]
              else
                stormpath_pre_create_attrs["custom_data"][attribute]
              end
            end
            define_method("#{attribute}=") do |val|
              if stormpath_account.present?
                stormpath_account.custom_data[attribute] = val
              else
                stormpath_pre_create_attrs["custom_data"][attribute] = val
              end
            end
          end #attributes#each
        end #self.custom_data_attributes

        def stormpath_account
          if stormpath_url
            @stormpath_account ||= begin
                                     Stormpath::Rails.client.accounts.get stormpath_url
                                   rescue Stormpath::Error => error
                                     Stormpath::Rails.logger.warn "Error loading Stormpath account (#{error})"
                                   end
          end
        end

        def stormpath_pre_create_attrs
          @stormpath_pre_create_attrs ||= {"custom_data" => {}}
        end

        (STORMPATH_FIELDS - [:password]).each do |name|
          define_method(name) do
            if stormpath_account.present?
              stormpath_account.send(name)
            else
              stormpath_pre_create_attrs[name]
            end
          end
        end

        (STORMPATH_FIELDS - [:full_name]).each do |name|
          define_method("#{name}=") do |val|
            if stormpath_account.present?
              stormpath_account.send("#{name}=", val)
            else
              stormpath_pre_create_attrs[name] = val
            end
          end
        end

        def stormpath_directory
          @stormpath_directory
        end

        def stormpath_directory=(directory)
          directory_mapped_to_application = false
          Stormpath::Rails.application.account_store_mappings.each do |account_store_mapping|
            directory_mapped_to_application = true if account_store_mapping.account_store == directory
          end
          @stormpath_directory = directory_mapped_to_application ? directory : nil
        end

        def create_account_on_stormpath
          begin
            stormpath_account = if stormpath_directory
              stormpath_directory.accounts.create prepared_account_resource
            else
              Stormpath::Rails.application.accounts.create prepared_account_resource
            end
            stormpath_pre_create_attrs.clear
            self.stormpath_url = stormpath_account.href
          rescue Stormpath::Error => error
            self.errors[:base] << error.to_s
            false
          end
        end

        def update_account_on_stormpath
          if self.stormpath_url.present?
            begin
              stormpath_account.save
            rescue Stormpath::Error => error
              self.errors[:base] << error.to_s
              false
            end
          else
            true
          end
        end

        def delete_account_on_stormpath
          if self.stormpath_url.present?
            begin
              stormpath_account.delete
            rescue Stormpath::Error => error
              Stormpath::Rails.logger.warn "Error destroying Stormpath account (#{error})"
            end
          else
            true
          end
        end

        def prepared_account_resource        
          account = Stormpath::Resource::Account.new stormpath_pre_create_attrs, Stormpath::Rails.client
          account.set_property "custom_data", stormpath_pre_create_attrs["custom_data"]
          account            
        end

        private :prepared_account_resource
      end #included do

    end #Account
  end #Rails
end #Stormpath