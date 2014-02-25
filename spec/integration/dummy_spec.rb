require "spec_helper"
require 'pry-debugger'
require "stormpath-rails"

describe User, :vcr do

  let(:email) { "user@stormpath.com" }
  let(:username) { "stormpath user" }
  let(:given_name) { "stormtrooper" }
  let(:surname) { "jedi" }
  let(:password) { "IzStormpathian111" }

  subject(:user) do
    User.create(email: email, username: username, given_name: given_name, surname: surname, password: password)
  end

  after do
    user.destroy
  end

  context 'instances' do
    it { should be_kind_of User }

    its(:stormpath_account) { should be_kind_of Stormpath::Resource::Account }

    [:given_name, :username, :surname, :email, :status].each do |property_accessor|
      it { should respond_to property_accessor }
      it { should respond_to "#{property_accessor}=" }
      its(property_accessor) { should be_instance_of String }
    end

    it { should_not respond_to "password" }
    it { should respond_to "password=" }

    it { should respond_to "full_name" }
    it { should_not respond_to "full_name=" }

    it '#stormpath_account methods' do
      expect(user.stormpath_account.email).to be_kind_of String
      expect(user.stormpath_account.username).to be_kind_of String
      expect(user.stormpath_account.given_name).to be_kind_of String
      expect(user.stormpath_account.surname).to be_kind_of String
      expect(user.stormpath_account.full_name).to be_kind_of String

      expect(user.stormpath_account.email).to eq(email)
      expect(user.stormpath_account.username).to eq(username)
      expect(user.stormpath_account.given_name).to eq(given_name)
      expect(user.stormpath_account.surname).to eq(surname)
      expect(user.stormpath_account.full_name).to eq(given_name + " " + surname)
    end
  end
  context '#authenticate ' do
    it 'w/username' do
      authenticated_user = User.authenticate user.username, password
      expect(authenticated_user.stormpath_account.href).to eq(user.stormpath_account.href)
    end

    it 'w/email' do
      authenticated_user = User.authenticate user.email, password
      expect(authenticated_user.stormpath_account.href).to eq(user.stormpath_account.href)
    end

    it 'improperly' do
      expect { User.authenticate user.username, "wrong password" }.to raise_error(Stormpath::Error)
    end
  end

  context 'change_password' do  
    let(:new_password) do
      "NewPassword00"
    end

    it 'should be able to change it without a reset token' do
      user.password = new_password    
      user.save
      authenticated_user = User.authenticate user.email, new_password
      expect(authenticated_user).to eq(user)
    end    
  end

  context 'update profile ' do
    let(:new_surname) { "Tables" }
    let(:new_given_name) { "Bobby" }

    it 'single attribute update' do
      expect(user.surname).to eq(surname)
      user.surname = new_surname
      user.save
      expect(user.surname).to eq(new_surname)
      expect(user.stormpath_account.surname).to eq(new_surname)
    end

    it 'multiple attribute update' do
      user.update_attributes(given_name: new_given_name, surname: new_surname)

      expect(user.given_name).to eq(new_given_name)
      expect(user.surname).to eq(new_surname)
      expect(user.stormpath_account.given_name).to eq(new_given_name)
      expect(user.stormpath_account.surname).to eq(new_surname)
    end
  end



end
