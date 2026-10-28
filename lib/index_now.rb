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
      def announce(&entries)
        return dry_run(&entries) unless config.enabled

        entries = entries.call
        urls = entries.map(&:url)
        Client.submit!(urls)
        Announcement.record!(entries)
        Rails.logger.info("IndexNow announced #{urls.join(", ")}") if urls.any?
        Result.new(urls: urls)
      rescue StandardError => error
        Rails.logger.error("IndexNow failed: #{error.class}: #{error.message}")
        Rails.error.report(error, handled: true, source: "index_now")
        Result.new(error: error)
      end

      # Staging and development often cannot read their own sitemap (basic auth, config.hosts); that is not an error there.
      def dry_run
        urls = yield.map(&:url)
        Rails.logger.info("IndexNow disabled; would announce #{urls.join(", ")}") if urls.any?
        Result.new(disabled: true)
      rescue StandardError => error
        Rails.logger.info("IndexNow disabled; could not read the sitemap: #{error.message}")
        Result.new(disabled: true)
      end
  end
end
