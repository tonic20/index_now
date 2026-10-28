require "spec_helper"

RSpec.describe IndexNow::Announcement do
  let(:url) { "https://example.org/" }
  let(:earlier) { Time.utc(2026, 9, 1) }
  let(:later) { Time.utc(2026, 9, 15) }

  def entry(lastmod) = IndexNow::Sitemap::Entry.new(url: url, lastmod: lastmod)

  def announced(lastmod) = described_class.create!(url: url, lastmod: lastmod, announced_at: Time.current)

  it "counts a url never announced as due, dated or not" do
    expect(described_class.due([ entry(later), IndexNow::Sitemap::Entry.new(url: "https://example.org/x", lastmod: nil) ]).size).to eq 2
  end

  it "counts a url whose lastmod moved as due" do
    announced(earlier)

    expect(described_class.due([ entry(later) ])).to eq [ entry(later) ]
  end

  it "does not count an unchanged lastmod" do
    announced(later)

    expect(described_class.due([ entry(later) ])).to be_empty
  end

  it "announces an undated url once only" do
    announced(nil)

    expect(described_class.due([ entry(nil) ])).to be_empty
  end

  it "counts a url that gained a lastmod as due" do
    announced(nil)

    expect(described_class.due([ entry(later) ])).to eq [ entry(later) ]
  end

  it "records what was sent, one row per url" do
    announced(earlier)

    described_class.record!([ entry(later), IndexNow::Sitemap::Entry.new(url: "https://example.org/x", lastmod: nil) ])

    expect(described_class.pluck(:url, :lastmod)).to contain_exactly([ url, later ], [ "https://example.org/x", nil ])
  end
end
