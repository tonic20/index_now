require "spec_helper"
require "rake"

RSpec.describe "index_now rake tasks" do
  before(:all) { Rails.application.load_tasks if Rake::Task.tasks.none? { |t| t.name == "index_now:announce" } }

  before do
    IndexNow.config.enabled = true
    SitemapsController.body = <<~XML
      <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"><url><loc>https://example.org/</loc><lastmod>2026-09-15</lastmod></url></urlset>
    XML
  end

  def run(name)
    Rake::Task[name].reenable
    Rake::Task[name].invoke
  end

  it "announce prints what it sent" do
    stub_request(:post, "https://api.indexnow.org/indexnow").to_return(status: 200)

    expect { run("index_now:announce") }.to output(%r{announced 1 url\n  https://example.org/}).to_stdout
  end

  it "announce says when there was nothing to send" do
    stub_request(:post, "https://api.indexnow.org/indexnow").to_return(status: 200)
    run("index_now:announce")

    expect { run("index_now:announce") }.to output(/nothing to announce/).to_stdout
  end

  it "announce exits non-zero on failure" do
    stub_request(:post, "https://api.indexnow.org/indexnow").to_return(status: 403)
    allow(Rails.error).to receive(:report)

    expect { run("index_now:announce") }.to raise_error(SystemExit) { |exit| expect(exit.status).to eq 1 }
      .and output(/403/).to_stderr
  end

  it "announce says when it is disabled rather than up to date" do
    IndexNow.config.enabled = false

    expect { run("index_now:announce") }.to output(/disabled/).to_stdout
  end

  it "pending lists what would go without sending it" do
    expect { run("index_now:pending") }.to output(%r{https://example.org/}).to_stdout

    expect(IndexNow::Announcement.count).to eq 0
  end

  it "announce_all sends everything again" do
    stub_request(:post, "https://api.indexnow.org/indexnow").to_return(status: 200)
    run("index_now:announce")

    expect { run("index_now:announce_all") }.to output(/announced 1 url/).to_stdout
  end
end
