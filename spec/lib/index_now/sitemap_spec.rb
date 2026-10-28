require "spec_helper"

RSpec.describe IndexNow::Sitemap do
  def urlset(*urls)
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xhtml="http://www.w3.org/1999/xhtml">
        #{urls.join("\n")}
      </urlset>
    XML
  end

  it "reads each url's loc and lastmod" do
    SitemapsController.body = urlset(
      "<url><loc>https://example.org/</loc><lastmod>2026-09-15</lastmod></url>",
      "<url><loc>https://example.org/stats</loc><lastmod>2026-10-28T11:22:45+02:00</lastmod></url>",
      "<url><loc>https://example.org/terms</loc></url>"
    )

    expect(described_class.entries).to eq [
      IndexNow::Sitemap::Entry.new(url: "https://example.org/", lastmod: Time.utc(2026, 9, 15)),
      IndexNow::Sitemap::Entry.new(url: "https://example.org/stats", lastmod: Time.utc(2026, 10, 28, 9, 22, 45)),
      IndexNow::Sitemap::Entry.new(url: "https://example.org/terms", lastmod: nil)
    ]
  end

  it "returns one entry per url, ignoring hreflang alternates" do
    SitemapsController.body = urlset(<<~XML)
      <url>
        <loc>https://example.org/</loc>
        <xhtml:link rel="alternate" hreflang="es" href="https://example.org/es"/>
      </url>
    XML

    expect(described_class.entries.map(&:url)).to eq [ "https://example.org/" ]
  end

  it "asks the app itself for the configured path, over https on the configured host" do
    SitemapsController.body = urlset

    described_class.entries

    expect(SitemapsController.last_request.url).to eq "https://example.org/sitemap.xml"
  end

  it "falls back to the routes' default host" do
    IndexNow.config.host = nil
    Rails.application.routes.default_url_options[:host] = "example.org"
    SitemapsController.body = urlset

    described_class.entries

    expect(SitemapsController.last_request.host).to eq "example.org"
  ensure
    Rails.application.routes.default_url_options.delete(:host)
  end

  it "refuses to guess a host" do
    IndexNow.config.host = nil

    expect { described_class.entries }.to raise_error(IndexNow::Error, /no host/)
  end

  it "fails on a sitemap that is not there" do
    IndexNow.config.sitemap_path = "/sitemap"

    expect { described_class.entries }.to raise_error(IndexNow::SitemapError, %r{404 .*/sitemap})
  end

  it "fails on a redirect rather than reading it as an empty sitemap" do
    SitemapsController.answer_status = 301

    expect { described_class.entries }.to raise_error(IndexNow::SitemapError, /301/)
  end

  it "fails on a body that is not a urlset" do
    SitemapsController.body = "<!doctype html><html><body>Hello</body></html>"

    expect { described_class.entries }.to raise_error(IndexNow::SitemapError, /urlset/)
  end

  it "fails on an empty body" do
    expect { described_class.entries }.to raise_error(IndexNow::SitemapError)
  end

  it "fails on truncated xml rather than reading what is left" do
    SitemapsController.body = urlset("<url><loc>https://exa")

    expect { described_class.entries }.to raise_error(IndexNow::SitemapError)
  end

  it "lists a url once even when the sitemap repeats it" do
    SitemapsController.body = urlset(*Array.new(2) { "<url><loc>https://example.org/</loc></url>" })

    expect(described_class.entries.map(&:url)).to eq [ "https://example.org/" ]
  end

  it "keeps no more precision than a database column holds" do
    SitemapsController.body = urlset("<url><loc>https://example.org/</loc><lastmod>2026-10-28T11:22:45.123456789Z</lastmod></url>")

    expect(described_class.entries.sole.lastmod).to eq Time.utc(2026, 10, 28, 11, 22, 45, 123456)
  end

  it "reads a minute-precision lastmod, as the sitemap protocol allows" do
    SitemapsController.body = urlset("<url><loc>https://example.org/</loc><lastmod>2026-10-28T11:22+02:00</lastmod></url>")

    expect(described_class.entries.sole.lastmod).to eq Time.utc(2026, 10, 28, 9, 22)
  end

  it "leaves the caller's request state alone" do
    SitemapsController.body = urlset
    Current.tenant = "acme"

    Rails.application.executor.wrap { described_class.entries }

    expect(Current.tenant).to eq "acme"
  ensure
    Current.reset
  end

  it "names the url and the host check in a 403" do
    SitemapsController.answer_status = 403

    expect { described_class.entries }.to raise_error(IndexNow::SitemapError, %r{https://example.org/sitemap.xml.*config.hosts})
  end

  it "fails on a sitemap index" do
    SitemapsController.body = <<~XML
      <sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
        <sitemap><loc>https://example.org/sitemap-1.xml</loc></sitemap>
      </sitemapindex>
    XML

    expect { described_class.entries }.to raise_error(IndexNow::SitemapError, /sitemapindex/)
  end
end
