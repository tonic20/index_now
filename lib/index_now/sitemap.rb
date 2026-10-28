require "nokogiri"

module IndexNow
  class SitemapError < Error; end

  module Sitemap
    Entry = Data.define(:url, :lastmod)

    class << self
      def entries
        parse(fetch).xpath("/urlset/url").map do |url|
          Entry.new(url: url.at("loc").text.strip, lastmod: url.at("lastmod")&.text&.then { |text| lastmod(text) })
        end.uniq(&:url)
      end

      private
        def url = "https://#{IndexNow.config.host}#{IndexNow.config.sitemap_path}"

        # Own thread: Rails.application.call runs the executor, which would reset the caller's Current and query cache.
        def fetch = Thread.new { request }.value

        def request
          status, _headers, body = Rails.application.call(Rack::MockRequest.env_for(url, "HTTP_HOST" => IndexNow.config.host))
          content = +""
          body.each { |chunk| content << chunk }
          raise SitemapError, failure_message(status) unless status == 200

          content
        ensure
          body.close if body.respond_to?(:close)
        end

        def failure_message(status)
          hint = " (is #{IndexNow.config.host} in config.hosts?)" if status == 403
          "#{status} from #{url}#{hint}"
        end

        def parse(xml)
          document = Nokogiri::XML(xml, &:strict).remove_namespaces!
          root = document.root&.name
          raise SitemapError, "#{url} is a #{root || "empty document"}, not a urlset" unless root == "urlset"

          document
        rescue Nokogiri::XML::SyntaxError => error
          raise SitemapError, "#{url} is not an XML urlset: #{error.message}"
        end

        def lastmod(text)
          text = text.strip
          text = "#{text}T00:00:00Z" if text.match?(/\A\d{4}-\d{2}-\d{2}\z/)
          Time.iso8601(text.sub(/T(\d{2}:\d{2})(?=Z|[+-])/, 'T\1:00')).utc.floor(6)
        end
    end
  end
end
