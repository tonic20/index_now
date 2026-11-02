require "optparse"
require "index_now"

module IndexNow
  # `index_now` for a static site: its built sitemap is the input, a JSON file remembers what was announced.
  class CLI
    def self.start(argv, out: $stdout, err: $stderr) = new(out, err).start(argv)

    def initialize(out, err)
      @out, @err = out, err
      @options = { public: "public", state: ".index_now.json" }
    end

    def start(argv)
      case parser.parse(argv)
      in _ if @options[:help] then usage(@out, 0)
      in [ "init" ] then init
      in [ "pending" ] then pending
      in [ "announce" ] then announce
      else usage(@err, 1)
      end
    rescue StandardError => error
      @err.puts "index_now: #{error.message}"
      1
    end

    private
      def init
        raise Error, "#{public_dir}/ is not a directory" unless Dir.exist?(public_dir)

        if (existing = key_files.first)
          @out.puts "#{existing} already holds the key"
        else
          path = File.join(public_dir, "#{valid(@options[:key] || Key.generate)}.txt")
          File.write(path, File.basename(path, ".txt"))
          @out.puts "wrote #{path}: deploy it with the site, then run `index_now announce`"
        end
        0
      end

      def pending
        urls = store.due(entries).map(&:url)
        @out.puts(urls.empty? ? "nothing to announce" : urls)
        0
      end

      def announce
        key = self.key
        sent = @options[:all] ? entries : store.due(entries)
        urls = sent.map(&:url)
        Client.submit!(urls, key: key)
        store.record!(sent)

        if urls.empty?
          @out.puts "nothing to announce"
        else
          @out.puts "announced #{urls.size} url#{"s" unless urls.one?}"
          urls.each { |url| @out.puts "  #{url}" }
        end
        0
      end

      def entries = @entries ||= Sitemap.parse(File.read(sitemap), from: sitemap)

      def store = @store ||= FileStore.new(@options[:state])

      def public_dir = @options[:public]

      def sitemap = @options[:sitemap] || File.join(public_dir, "sitemap.xml")

      def key
        return valid(@options[:key]) if @options[:key]

        files = key_files
        raise Error, "no key file in #{public_dir}/: run `index_now init`, or pass --key" if files.empty?
        raise Error, "#{files.join(" and ")} are all key files: pass --key" if files.size > 1

        File.basename(files.sole, ".txt")
      end

      # A key file is <key>.txt holding exactly that key; other text files (robots.txt, llms.txt) are not.
      def key_files
        Dir[File.join(public_dir, "*.txt")].sort.select do |path|
          name = File.basename(path, ".txt")
          Key.valid?(name) && File.read(path).strip == name
        end
      end

      def valid(key)
        raise Error, "an IndexNow key is 8 to 128 letters, digits or dashes" unless Key.valid?(key)

        key
      end

      def usage(io, status)
        io.puts parser
        status
      end

      def parser
        @parser ||= OptionParser.new do |o|
          o.banner = <<~TEXT
            Usage: index_now <command> [options]

            Announces a static site's changed pages to IndexNow, from its built sitemap.

            Commands:
              init        write a key file into the public directory
              pending     list the urls the next announce would send
              announce    send them, and record what was sent

            Options:
          TEXT
          o.on("--public DIR", "the built site (default: public)") { |v| @options[:public] = v }
          o.on("--sitemap PATH", "the sitemap (default: <public>/sitemap.xml)") { |v| @options[:sitemap] = v }
          o.on("--state PATH", "what was announced (default: .index_now.json)") { |v| @options[:state] = v }
          o.on("--key KEY", "the IndexNow key (default: the key file in <public>)") { |v| @options[:key] = v }
          o.on("--all", "announce: send every url, e.g. after rotating the key") { @options[:all] = true }
          o.on("-h", "--help", "show this") { @options[:help] = true }
        end
      end
  end
end
