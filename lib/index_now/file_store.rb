require "json"

module IndexNow
  # What a static site announced, as { url => lastmod } in a JSON file; the counterpart of Announcement.
  class FileStore
    def initialize(path)
      @path = path
    end

    def due(entries) = entries.select { |entry| entry.due?(announced) }

    def record!(entries)
      return if entries.empty?

      recorded = announced.merge(entries.to_h { |entry| [ entry.url, entry.lastmod ] })
      write(recorded.sort.to_h.transform_values { |lastmod| lastmod&.iso8601(lastmod.usec.zero? ? 0 : 6) })
      @announced = recorded
    end

    private
      def announced
        @announced ||= File.exist?(@path) ? read : {}
      end

      def read
        JSON.parse(File.read(@path)).transform_values { |lastmod| lastmod && Time.iso8601(lastmod) }
      rescue JSON::ParserError, ArgumentError => error
        raise Error, "#{@path} is not an index_now state file: #{error.message}"
      end

      # Through a temp file, so a crash mid-write cannot leave half a file that would re-announce everything.
      def write(hash)
        File.write("#{@path}.tmp", "#{JSON.pretty_generate(hash)}\n")
        File.rename("#{@path}.tmp", @path)
      end
  end
end
