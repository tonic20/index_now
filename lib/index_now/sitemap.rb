require "nokogiri"

module IndexNow
  class SitemapError < Error; end

  module Sitemap
    Entry = Data.define(:url, :lastmod)

    class << self
      def entries
        document = Nokogiri::XML(fetch).remove_namespaces!
        raise SitemapError, "#{path} is a sitemapindex; only a urlset is supported" if document.root&.name == "sitemapindex"

        document.xpath("/urlset/url").map do |url|
          Entry.new(url: url.at("loc").text.strip, lastmod: url.at("lastmod")&.text&.then { |text| Time.iso8601(normalize(text)).utc })
        end
      end

      private
        def path = IndexNow.config.sitemap_path

        # In-process, so it works whatever the network path back to the app is.
        def fetch
          status, _headers, body = Rails.application.call(env)
          content = +""
          body.each { |chunk| content << chunk }
          raise SitemapError, "#{status} from #{path}" unless status == 200

          content
        ensure
          body.close if body.respond_to?(:close)
        end

        def env
          host = IndexNow.config.host
          Rack::MockRequest.env_for("https://#{host}#{path}", "HTTP_HOST" => host)
        end

        def normalize(lastmod) = lastmod.strip.match?(/\A\d{4}-\d{2}-\d{2}\z/) ? "#{lastmod.strip}T00:00:00Z" : lastmod.strip
    end
  end
end
