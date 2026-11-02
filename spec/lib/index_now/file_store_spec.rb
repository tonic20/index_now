require "spec_helper"

RSpec.describe IndexNow::FileStore do
  around { |example| Dir.mktmpdir { |dir| @dir = dir; example.run } }

  let(:path) { File.join(@dir, ".index_now.json") }
  let(:store) { described_class.new(path) }

  def entry(url, lastmod = nil) = IndexNow::Sitemap::Entry.new(url: "https://example.org#{url}", lastmod: lastmod)

  it "finds every url due before anything was recorded" do
    entries = [ entry("/", Time.utc(2026, 9, 15)), entry("/terms") ]

    expect(store.due(entries)).to eq entries
  end

  it "finds nothing due once it recorded them" do
    entries = [ entry("/", Time.utc(2026, 9, 15)), entry("/terms") ]
    store.record!(entries)

    expect(described_class.new(path).due(entries)).to be_empty
  end

  it "finds a url due again once its lastmod moves" do
    store.record!([ entry("/", Time.utc(2026, 9, 15)), entry("/about", Time.utc(2026, 9, 15)) ])

    expect(store.due([ entry("/", Time.utc(2026, 10, 1)), entry("/about", Time.utc(2026, 9, 15)) ]))
      .to eq [ entry("/", Time.utc(2026, 10, 1)) ]
  end

  it "keeps what it recorded before" do
    store.record!([ entry("/", Time.utc(2026, 9, 15)) ])
    store.record!([ entry("/terms", Time.utc(2026, 9, 16)) ])

    expect(store.due([ entry("/", Time.utc(2026, 9, 15)), entry("/terms", Time.utc(2026, 9, 16)) ])).to be_empty
  end

  it "writes sorted JSON that reads well in a diff" do
    store.record!([ entry("/terms"), entry("/", Time.utc(2026, 10, 28, 9, 22, 45, 123456)), entry("/about", Time.utc(2026, 9, 15)) ])

    expect(File.read(path)).to eq <<~JSON
      {
        "https://example.org/": "2026-10-28T09:22:45.123456Z",
        "https://example.org/about": "2026-09-15T00:00:00Z",
        "https://example.org/terms": null
      }
    JSON
  end

  it "writes nothing when there is nothing to record" do
    store.record!([])

    expect(File).not_to exist(path)
  end

  it "names the file when it is not JSON" do
    File.write(path, "{")

    expect { store.due([ entry("/") ]) }.to raise_error(IndexNow::Error, /\.index_now\.json/)
  end
end
