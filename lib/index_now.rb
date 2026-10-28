require "time"
require "index_now/version"

module IndexNow
  class Error < StandardError; end
end

require "index_now/configuration"
require "index_now/engine"
require "index_now/sitemap"
require "index_now/client"

module IndexNow
  class << self
    def config = @config ||= Configuration.new

    def configure = yield(config)

    def reset_config! = @config = nil
  end
end
