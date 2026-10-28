ENV["RAILS_ENV"] = "test"

require_relative "dummy/config/environment"
require "rspec/rails"
require "webmock/rspec"

ActiveRecord::Migration.verbose = false
ActiveRecord::MigrationContext.new(File.expand_path("../db/migrate", __dir__)).migrate

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
