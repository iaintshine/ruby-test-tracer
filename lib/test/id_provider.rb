require 'securerandom'

module Test
  module IdProvider
    class << self
      def generate
        SecureRandom.uuid
      end
    end
  end
end
