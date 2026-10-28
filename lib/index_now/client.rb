require "net/http"
require "json"

module IndexNow
  class SubmitFailed < Error; end

  module Client
    ENDPOINT = URI("https://api.indexnow.org/indexnow").freeze
    BATCH = 10_000

    class << self
      def submit!(urls)
        return 0 if urls.empty?

        host = host_of(urls)
        urls.each_slice(BATCH) { |batch| post(host, batch) }
        urls.size
      end

      private
        def host_of(urls)
          host = URI(urls.first).host
          foreign = urls.reject { |url| URI(url).host == host }
          raise SubmitFailed, "not on #{host}, refusing to submit: #{foreign.join(", ")}" if foreign.any?

          host
        end

        def post(host, urls)
          request = Net::HTTP::Post.new(ENDPOINT)
          request["Content-Type"] = "application/json; charset=utf-8"
          request.body = JSON.generate(host: host, key: key, keyLocation: key_location(host), urlList: urls)

          response = Net::HTTP.start(ENDPOINT.host, ENDPOINT.port, use_ssl: true, open_timeout: 10, read_timeout: 20) do |http|
            http.request(request)
          end
          code = response.code.to_i
          raise SubmitFailed, failure_message(code, host) unless [ 200, 202 ].include?(code)
        end

        def key = IndexNow.config.key

        def key_location(host) = "https://#{host}/#{key}.txt"

        def failure_message(code, host)
          case code
          when 400 then "400 malformed request: the JSON body was rejected"
          when 403 then "403 key not valid: #{key_location(host)} must be reachable and contain exactly the key"
          when 422 then "422 the urls do not belong to #{host}, or the key does not match the schema"
          when 429 then "429 too many requests: rate limited as potential spam"
          else "IndexNow answered HTTP #{code}"
          end
        end
    end
  end
end
