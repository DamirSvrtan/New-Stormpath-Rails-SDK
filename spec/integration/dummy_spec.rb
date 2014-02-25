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

  describe 'instances' do
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
      expect(user.stormpath_account.email).to eq(email)
      expect(user.stormpath_account.username).to eq(username)
      expect(user.stormpath_account.given_name).to eq(given_name)
      expect(user.stormpath_account.surname).to eq(surname)
      expect(user.stormpath_account.full_name).to eq(given_name + " " + surname)
    end

    context 'with custom data' do
      it { should respond_to :age }
      it { should respond_to :age= }
      it { should respond_to :favorite_color }
      it { should respond_to :favorite_color= }
    end
  end


  context 'update profile ' do
    let(:new_surname) { "Stormpathian" }
    let(:new_given_name) { "Chubby" }

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

  context '#authenticate' do
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

    it 'should be able to change it while updating the user' do
      user.password = new_password    
      user.save
      authenticated_user = User.authenticate user.email, new_password
      expect(authenticated_user).to eq(user)
    end


    context 'with a reset token' do
      let(:password_reset_token) do
        Stormpath::Rails.application.password_reset_tokens.create(email: user.email).token
      end

      let(:reset_password_account) do
        Stormpath::Rails.application.verify_password_reset_token password_reset_token
      end

      it 'retrieves the account with the reset password and resets it' do
        expect(reset_password_account).to be
        expect(reset_password_account.email).to eq(user.email)

        user.password = new_password
        user.save
        authenticated_user = User.authenticate user.email, new_password
        expect(authenticated_user).to eq(user)
      end

    end #with_a_reset_token
  end #change_password



  describe '#send_password_reset_email' do
    context 'given an email' do
      
      context 'of an exisiting account on the application' do
        let(:sent_to_account) { User.send_password_reset_email user.email }
        it 'sends a password reset request of the account' do
          expect(sent_to_account).to be
          expect(sent_to_account).to be_kind_of User
          expect(sent_to_account.email).to eq(user.email)
        end
      end

      context 'of a non exisitng account' do
        it 'raises an exception' do
          expect do
            User.send_password_reset_email "test@example.com"
          end.to raise_error Stormpath::Error
        end
      end

    end #given an email
  end #send_password_reset_email

  describe '#verify_account_email' do
    context 'given a verfication token of an account' do
      let(:directory) { Stormpath::Rails.client.directories.get ENV['STORMPATH_RAILS_TEST_DIRECTORY_WITH_VERIFICATION_URL'] }

      let(:new_user) do
        User.create(email: email, username: username, given_name: given_name, surname: surname, password: password, stormpath_directory: directory)
      end

      let(:verification_token) do
        new_user.stormpath_account.email_verification_token.token
      end

      let(:verified_account) do
        User.verify_email_token verification_token
      end

      after do
        new_user.destroy
      end

      it 'returns the account' do
        expect(verified_account).to be
        expect(verified_account).to be_kind_of User
        expect(verified_account.username).to eq(user.username)
      end
    end
  end

  describe 'simple #custom_data' do
    let(:new_user) do
      User.create(email: email, username: username, given_name: given_name, surname: surname, password: password, age: 24)
    end

    after do
      new_user.destroy
    end

    it 'should respond to custom data structures' do
      expect(new_user).to be_kind_of User
      expect(new_user.stormpath_account.custom_data[:age]).to eq(new_user.age)
      account = Stormpath::Rails.application.accounts.get new_user.stormpath_url
      expect(new_user.age).to eq(account.custom_data[:age])
    end
  end

  describe 'complex #custom_data' do
    let(:new_user) do
      User.create(email: email, username: username, given_name: given_name, surname: surname, password: password, favorite_color: {"when_night" => "black", "when_day" => "blue"})
    end

    after do
      new_user.destroy
    end

    it 'should respond to custom data structures' do
      expect(new_user).to be_kind_of User
      expect(new_user.stormpath_account.custom_data[:favorite_color]).to eq(new_user.favorite_color)
      account = Stormpath::Rails.application.accounts.get new_user.stormpath_url
      expect(new_user.favorite_color).to eq(account.custom_data[:favorite_color])
      expect(new_user.favorite_color).to eq({"when_night" => "black", "when_day" => "blue"})
    end
  end

  describe 'complex #custom_data update user' do
    let(:new_user) do
      User.create(email: email, username: username, given_name: given_name, surname: surname, password: password)
    end

    after do
      new_user.destroy
    end

    it 'should respond to custom data structures' do
      expect(new_user).to be_kind_of User
      expect(new_user.stormpath_account.custom_data[:favorite_color]).to eq(new_user.favorite_color)
      new_user.favorite_color = {"when_night" => "black", "when_day" => "blue"}
      new_user.save
      expect(new_user.favorite_color).to eq({"when_night" => "black", "when_day" => "blue"})
    end
  end

end #Describe User