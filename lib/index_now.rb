require "time"
require "index_now/version"

module IndexNow
  class Error < StandardError; end
end

require "index_now/configuration"
require "index_now/engine"
require "index_now/result"
require "index_now/sitemap"
require "index_now/client"

module IndexNow
  class << self
    def config = @config ||= Configuration.new

    def configure = yield(config)

    def reset_config! = @config = nil

    def pending = Announcement.due(Sitemap.entries)

    def announce_changes = announce { pending }

    def announce_all = announce { Sitemap.entries }

    private
      # Never raises: a failed announcement must not fail the deploy or job that asked for it.
      def announce
        entries = yield
        urls = entries.map(&:url)

        unless config.enabled
          Rails.logger.info("IndexNow disabled; would announce #{urls.join(", ")}") if urls.any?
          return Result.new(urls: [], error: nil)
        end

        Client.submit!(urls)
        Announcement.record!(entries)
        Rails.logger.info("IndexNow announced #{urls.join(", ")}") if urls.any?
        Result.new(urls: urls, error: nil)
      rescue StandardError => error
        Rails.logger.error("IndexNow failed: #{error.class}: #{error.message}")
        Rails.error.report(error, handled: true, source: "index_now")
        Result.new(urls: [], error: error)
      end
  end
end
