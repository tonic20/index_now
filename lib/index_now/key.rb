require "securerandom"

module IndexNow
  module Key
    FORMAT = /\A[a-zA-Z0-9-]{8,128}\z/

    def self.generate = SecureRandom.hex(16)

    def self.valid?(key) = FORMAT.match?(key)
  end
end
