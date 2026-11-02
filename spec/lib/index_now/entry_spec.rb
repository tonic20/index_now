require "spec_helper"

RSpec.describe IndexNow::Sitemap::Entry do
  let(:url) { "https://example.org/" }

  def entry(lastmod) = described_class.new(url: url, lastmod: lastmod)

  it "is due when its url was never announced" do
    expect(entry(nil).due?({})).to be true
  end

  it "is due when its lastmod moved past the one announced" do
    expect(entry(Time.utc(2026, 10, 2)).due?(url => Time.utc(2026, 10, 1))).to be true
  end

  it "is due when it gained a lastmod it was announced without" do
    expect(entry(Time.utc(2026, 10, 1)).due?(url => nil)).to be true
  end

  it "is not due when its lastmod has not moved" do
    expect(entry(Time.utc(2026, 10, 1)).due?(url => Time.utc(2026, 10, 1))).to be false
  end

  it "is not due again without a lastmod" do
    expect(entry(nil).due?(url => nil)).to be_falsey
  end
end
