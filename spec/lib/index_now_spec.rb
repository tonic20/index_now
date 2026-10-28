require "spec_helper"

RSpec.describe IndexNow do
  let(:endpoint) { "https://api.indexnow.org/indexnow" }

  def sitemap(*urls)
    SitemapsController.body = <<~XML
      <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
        #{urls.map { |url, lastmod| "<url><loc>#{url}</loc>#{"<lastmod>#{lastmod}</lastmod>" if lastmod}</url>" }.join}
      </urlset>
    XML
  end

  before { IndexNow.config.enabled = true }

  describe ".announce_changes" do
    it "posts only what changed, and nothing on a second run" do
      stub_request(:post, endpoint).to_return(status: 200)
      sitemap([ "https://example.org/", "2026-09-15" ], [ "https://example.org/stats", "2026-10-28T11:22:45+02:00" ])

      first = IndexNow.announce_changes
      second = IndexNow.announce_changes

      expect(first.urls).to eq [ "https://example.org/", "https://example.org/stats" ]
      expect(first).to be_ok
      expect(second.urls).to be_empty
      expect(WebMock).to have_requested(:post, endpoint).once
    end

    it "posts a page again once its lastmod moves" do
      stub_request(:post, endpoint).to_return(status: 200)
      sitemap([ "https://example.org/", "2026-09-15" ], [ "https://example.org/terms", "2026-09-15" ])
      IndexNow.announce_changes
      sitemap([ "https://example.org/", "2026-10-01" ], [ "https://example.org/terms", "2026-09-15" ])

      expect(IndexNow.announce_changes.urls).to eq [ "https://example.org/" ]
    end

    it "records nothing when the post fails, so the next run sends the same urls" do
      stub_request(:post, endpoint).to_return(status: 500).then.to_return(status: 200)
      sitemap([ "https://example.org/", "2026-09-15" ])
      allow(Rails.error).to receive(:report)

      failed = IndexNow.announce_changes

      expect(failed).not_to be_ok
      expect(failed.error).to be_a(IndexNow::SubmitFailed)
      expect(Rails.error).to have_received(:report).with(an_instance_of(IndexNow::SubmitFailed), anything)
      expect(IndexNow::Announcement.count).to eq 0
      expect(IndexNow.announce_changes.urls).to eq [ "https://example.org/" ]
    end

    it "reports a network timeout instead of raising" do
      stub_request(:post, endpoint).to_timeout
      sitemap([ "https://example.org/", "2026-09-15" ])
      allow(Rails.error).to receive(:report)

      expect(IndexNow.announce_changes).not_to be_ok
      expect(IndexNow::Announcement.count).to eq 0
    end

    it "reports a sitemap it cannot read instead of raising" do
      SitemapsController.answer_status = 500
      allow(Rails.error).to receive(:report)

      result = IndexNow.announce_changes

      expect(result.error).to be_a(IndexNow::SitemapError)
      expect(Rails.error).to have_received(:report).with(an_instance_of(IndexNow::SitemapError), anything)
      expect(WebMock).not_to have_requested(:post, endpoint)
    end

    it "sends and records nothing when disabled, and says what it would have sent" do
      IndexNow.config.enabled = nil
      sitemap([ "https://example.org/", "2026-09-15" ])
      allow(Rails.logger).to receive(:info)

      result = IndexNow.announce_changes

      expect(result.urls).to be_empty
      expect(Rails.logger).to have_received(:info).with(%r{disabled.*https://example.org/})
      expect(IndexNow::Announcement.count).to eq 0
    end
  end

  describe ".announce_all" do
    it "posts every url, announced before or not" do
      stub_request(:post, endpoint).to_return(status: 200)
      sitemap([ "https://example.org/", "2026-09-15" ], [ "https://example.org/terms", nil ])
      IndexNow.announce_changes

      expect(IndexNow.announce_all.urls).to eq [ "https://example.org/", "https://example.org/terms" ]
      expect(WebMock).to have_requested(:post, endpoint).twice
    end
  end

  describe ".pending" do
    it "lists what is due without posting or recording" do
      sitemap([ "https://example.org/", "2026-09-15" ])

      expect(IndexNow.pending.map(&:url)).to eq [ "https://example.org/" ]
      expect(IndexNow::Announcement.count).to eq 0
    end
  end
end
