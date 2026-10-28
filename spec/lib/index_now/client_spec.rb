require "spec_helper"

RSpec.describe IndexNow::Client do
  let(:endpoint) { "https://api.indexnow.org/indexnow" }
  let(:urls) { [ "https://example.org/", "https://example.org/terms" ] }

  it "posts the host, key, key location and urls as JSON" do
    stub_request(:post, endpoint).to_return(status: 200)

    expect(described_class.submit!(urls)).to eq 2

    expect(WebMock).to have_requested(:post, endpoint).with(
      headers: { "Content-Type" => "application/json; charset=utf-8" },
      body: { host: "example.org", key: "0123456789abcdef0123456789abcdef",
              keyLocation: "https://example.org/0123456789abcdef0123456789abcdef.txt", urlList: urls }.to_json
    )
  end

  it "takes 202 as accepted" do
    stub_request(:post, endpoint).to_return(status: 202)

    expect(described_class.submit!(urls)).to eq 2
  end

  {
    400 => /400 malformed/,
    403 => %r{403 key not valid.*https://example.org/0123456789abcdef0123456789abcdef.txt},
    422 => /422/,
    429 => /429 too many requests/,
    500 => /HTTP 500/
  }.each do |code, message|
    it "raises on #{code}" do
      stub_request(:post, endpoint).to_return(status: code)

      expect { described_class.submit!(urls) }.to raise_error(IndexNow::SubmitFailed, message)
    end
  end

  it "refuses urls on more than one host without sending anything" do
    expect { described_class.submit!(urls + [ "https://other.example/x" ]) }
      .to raise_error(IndexNow::SubmitFailed, %r{https://other.example/x})

    expect(WebMock).not_to have_requested(:post, endpoint)
  end

  it "splits more than 10,000 urls into batches" do
    stub_request(:post, endpoint).to_return(status: 200)
    many = Array.new(10_001) { |i| "https://example.org/#{i}" }

    expect(described_class.submit!(many)).to eq 10_001

    expect(WebMock).to have_requested(:post, endpoint).twice
    expect(WebMock).to have_requested(:post, endpoint).with { |req| JSON.parse(req.body)["urlList"].size == 1 }.once
  end

  it "sends nothing for no urls" do
    expect(described_class.submit!([])).to eq 0

    expect(WebMock).not_to have_requested(:post, endpoint)
  end
end
