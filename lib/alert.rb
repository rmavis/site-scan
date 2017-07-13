require 'net/smtp'
require 'yaml'


module SiteScan
  class Alert

    # This is the location of the YAML file that contains the SMTP
    # server credentials.
    def self.creds_file
      "#{File.dirname(__FILE__)}/../smtp.yaml"
    end


    # These keys must be present in the SMTP YAML file.
    def self.required_creds
      [
        'from_address',
        'from_domain',
        'server',
        'port',
        'username',
        'password',
      ]
    end



    def initialize(message, address)
      creds = self.get_smtp_creds(Alert::creds_file)
      if (!creds.nil?)
        email = self.make_email(creds, message, address)
        self.send(address, email, creds)
      end
    end


    def get_smtp_creds(file)
      creds = nil

      yaml_file = File.new(file)
      keys = Alert::required_creds
      YAML.load(yaml_file.read).each do |item|
        if (item.is_a?(Hash))
          ok = true
          keys.each do |key|
            if (!item.has_key?(key))
              ok = false
            end
          end
          if (ok)
            creds = item
          end
        end
      end

      return creds
    end



    def make_email(creds, body, address, subject = 'New finds from SiteScan')
      email = <<EOM
From: #{creds[:from_address]}
To: #{address}
Subject: #{subject}
Date: #{Time.now.strftime('%a, %_m %b %Y %T %z')}
    
#{body}
EOM

      return email
    end


    def send(address, email, creds, method = :login)
      Net::SMTP.start(creds[:server], creds[:port], creds[:from_domain],
                      creds[:username], creds[:password], method) do |smtp|
        smtp.send_message email, creds[:from_address], address
      end
    end

  end
end
