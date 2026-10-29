ENV["RAILS_ENV"] = "test"

require_relative "dummy/config/environment"
require "rspec/rails"
require "webmock/rspec"
require "generators/index_now/install/install_generator"

ActiveRecord::Migration.verbose = false
unless ActiveRecord::Base.connection.table_exists?(:index_now_announcements)
  Dir.mktmpdir do |root|
    IndexNow::Generators::InstallGenerator.start([ "--quiet" ], destination_root: root)
    ActiveRecord::MigrationContext.new(File.join(root, "db/migrate")).migrate
  end
end

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.include ActiveSupport::Testing::TimeHelpers

  config.before do
    IndexNow.reset_config!
    IndexNow.configure do |c|
      c.key = "0123456789abcdef0123456789abcdef"
      c.host = "example.org"
    end
    SitemapsController.body = ""
    SitemapsController.answer_status = 200
    SitemapsController.last_request = nil
  end
end
