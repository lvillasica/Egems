require 'openssl'

module Devise
  module Encryptors
    class Cipher < Base
      def self.digest(password, stretches, salt, pepper)
        enc = OpenSSL::Cipher::Cipher.new('DES-EDE3-CBC')
        enc.encrypt(salt)
        data = enc.update(password)
        Base64.encode64(data << enc.final).strip
      end
    end
  end
end
