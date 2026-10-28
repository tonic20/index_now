module IndexNow
  class Configuration
    attr_accessor :key, :sitemap_path
    attr_writer :host, :enabled

    def initialize
      @sitemap_path = "/sitemap.xml"
    end

    def host
      @host || Rails.application.routes.default_url_options[:host] ||
        raise(Error, "IndexNow has no host: set config.host or routes.default_url_options[:host]")
    end

    def enabled = @enabled.nil? ? Rails.env.production? : @enabled
  end
end
