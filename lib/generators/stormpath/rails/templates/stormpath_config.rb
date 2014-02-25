module Stormpath
  module Rails
  
    def self.client
      @@client ||= Stormpath::Client.new({ api_key_file_location: ENV['STORMPATH_API_KEY_FILE_LOCATION'] })
    end

    def self.application
      @@application ||= client.applications.get ENV['STORMPATH_APPLICATION_URL'] 
    end

    def self.composite_url
      ENV["STORMPATH_URL"]
    end

  end
end