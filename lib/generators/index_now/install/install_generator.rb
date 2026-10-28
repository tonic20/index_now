require "rails/generators"
require "rails/generators/active_record"
require "securerandom"

module IndexNow
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      source_root File.expand_path("templates", __dir__)
      class_option :key, type: :string, desc: "Reuse an existing IndexNow key instead of generating one"

      def self.next_migration_number(dirname) = ActiveRecord::Generators::Base.next_migration_number(dirname)

      def create_key_file
        create_file "public/#{key}.txt", key
      end

      def create_initializer
        template "initializer.rb.tt", "config/initializers/index_now.rb"
      end

      def copy_migration
        migration_template "create_index_now_announcements.rb.tt", "db/migrate/create_index_now_announcements.rb"
      end

      private
        def key
          @key ||= (options[:key] || SecureRandom.hex(16)).tap do |key|
            raise ArgumentError, "an IndexNow key is 8 to 128 letters, digits or dashes" unless key.match?(/\A[a-zA-Z0-9-]{8,128}\z/)
          end
        end
    end
  end
end
