require_relative "boot"
require "rails"
require "active_record/railtie"
require "action_controller/railtie"

Bundler.require(*Rails.groups)
require "index_now"

module Dummy
  class Application < Rails::Application
    config.load_defaults Rails::VERSION::STRING.to_f
    config.eager_load = false
    config.root = File.expand_path("..", __dir__)
    config.secret_key_base = "index_now_dummy"
    config.hosts << "example.org"
  end
end
