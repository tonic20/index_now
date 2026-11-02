require "spec_helper"
require "index_now/cli"

RSpec.describe IndexNow::CLI do
  let(:endpoint) { "https://api.indexnow.org/indexnow" }
  let(:key) { "0123456789abcdef0123456789abcdef" }

  around do |example|
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        Dir.mkdir("public")
        example.run
      end
    end
  end

  def sitemap(*urls)
    File.write("public/sitemap.xml", <<~XML)
      <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
        #{urls.map { |url, lastmod| "<url><loc>#{url}</loc>#{"<lastmod>#{lastmod}</lastmod>" if lastmod}</url>" }.join}
      </urlset>
    XML
  end

  def key_file = File.write("public/#{key}.txt", key)

  def run(*argv)
    out, err = StringIO.new, StringIO.new
    status = described_class.start(argv, out: out, err: err)
    [ status, out.string, err.string ]
  end

  describe "init" do
    it "writes a fresh key file into public/" do
      status, out, = run("init")

      file = Dir["public/*.txt"].sole
      expect(status).to eq 0
      expect(File.read(file)).to eq File.basename(file, ".txt")
      expect(out).to include(file)
    end

    it "keeps a key it is given" do
      run("init", "--key", key)

      expect(File.read("public/#{key}.txt")).to eq key
    end

    it "leaves an existing key file alone" do
      key_file

      status, out, = run("init")

      expect(status).to eq 0
      expect(Dir["public/*.txt"]).to eq [ "public/#{key}.txt" ]
      expect(out).to include("already")
    end

    it "rejects a key IndexNow would not accept" do
      status, _, err = run("init", "--key", "short")

      expect(status).to eq 1
      expect(err).to match(/8 to 128/)
      expect(Dir["public/*.txt"]).to be_empty
    end

    it "refuses a public directory that is not there" do
      status, _, err = run("init", "--public", "site")

      expect(status).to eq 1
      expect(err).to include("site")
    end
  end

  describe "announce" do
    before { key_file }

    it "posts what changed with the key from public/, then nothing on a second run" do
      stub_request(:post, endpoint).to_return(status: 200)
      sitemap([ "https://example.org/", "2026-09-15" ], [ "https://example.org/terms", nil ])

      status, out, = run("announce")
      _, again, = run("announce")

      expect(status).to eq 0
      expect(out).to eq "announced 2 urls\n  https://example.org/\n  https://example.org/terms\n"
      expect(again).to eq "nothing to announce\n"
      expect(WebMock).to have_requested(:post, endpoint).with { |req| JSON.parse(req.body)["key"] == key }.once
    end

    it "posts a page again once its lastmod moves" do
      stub_request(:post, endpoint).to_return(status: 200)
      sitemap([ "https://example.org/", "2026-09-15" ], [ "https://example.org/terms", "2026-09-15" ])
      run("announce")
      sitemap([ "https://example.org/", "2026-10-01" ], [ "https://example.org/terms", "2026-09-15" ])

      _, out, = run("announce")

      expect(out).to eq "announced 1 url\n  https://example.org/\n"
    end

    it "records nothing when the post fails, and exits 1" do
      stub_request(:post, endpoint).to_return(status: 403).then.to_return(status: 200)
      sitemap([ "https://example.org/", "2026-09-15" ])

      status, _, err = run("announce")

      expect(status).to eq 1
      expect(err).to match(/index_now: 403/)
      expect(File).not_to exist(".index_now.json")
      expect(run("announce")[1]).to include("https://example.org/")
    end

    it "posts every url again with --all" do
      stub_request(:post, endpoint).to_return(status: 200)
      sitemap([ "https://example.org/", "2026-09-15" ])
      run("announce")

      _, out, = run("announce", "--all")

      expect(out).to eq "announced 1 url\n  https://example.org/\n"
      expect(WebMock).to have_requested(:post, endpoint).twice
    end

    it "takes the sitemap, state file and key from options" do
      stub_request(:post, endpoint).to_return(status: 200)
      Dir.mkdir("site")
      File.write("site/map.xml", '<urlset><url><loc>https://example.org/</loc></url></urlset>')

      status, = run("announce", "--sitemap", "site/map.xml", "--state", "site/state.json", "--key", "fedcba9876543210")

      expect(status).to eq 0
      expect(File).to exist("site/state.json")
      expect(WebMock).to have_requested(:post, endpoint).with { |req| JSON.parse(req.body)["key"] == "fedcba9876543210" }
    end

    it "asks for init when public/ has no key file" do
      File.delete("public/#{key}.txt")
      sitemap([ "https://example.org/", "2026-09-15" ])

      status, _, err = run("announce")

      expect(status).to eq 1
      expect(err).to match(/no key file in public.*index_now init/)
    end

    it "ignores text files that are not key files" do
      File.write("public/robots.txt", "User-agent: *")
      File.write("public/llms-full.txt", "# Example")
      stub_request(:post, endpoint).to_return(status: 200)
      sitemap([ "https://example.org/", "2026-09-15" ])

      expect(run("announce").first).to eq 0
    end

    it "refuses to pick between two key files" do
      File.write("public/fedcba9876543210.txt", "fedcba9876543210")
      sitemap([ "https://example.org/", "2026-09-15" ])

      status, _, err = run("announce")

      expect(status).to eq 1
      expect(err).to match(/--key/)
    end

    it "names a sitemap it cannot find" do
      status, _, err = run("announce")

      expect(status).to eq 1
      expect(err).to include("public/sitemap.xml")
    end
  end

  describe "pending" do
    it "lists what announce would send, without a key, posting or recording" do
      sitemap([ "https://example.org/", "2026-09-15" ])

      status, out, = run("pending")

      expect(status).to eq 0
      expect(out).to eq "https://example.org/\n"
      expect(File).not_to exist(".index_now.json")
    end

    it "says when nothing is due" do
      sitemap

      expect(run("pending")[1]).to eq "nothing to announce\n"
    end
  end

  it "prints usage and exits 1 for an unknown command" do
    status, _, err = run("publish")

    expect(status).to eq 1
    expect(err).to include("Usage: index_now")
  end

  it "prints usage and exits 0 for --help" do
    status, out, = run("--help")

    expect(status).to eq 0
    expect(out).to include("Usage: index_now")
  end
end
