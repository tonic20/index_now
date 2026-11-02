require "spec_helper"

RSpec.describe IndexNow::Key do
  it "generates 32 hex characters" do
    expect(described_class.generate).to match(/\A\h{32}\z/)
  end

  it "accepts 8 to 128 letters, digits or dashes" do
    expect(described_class.valid?("abc-1234")).to be true
    expect(described_class.valid?("a" * 128)).to be true
  end

  it "rejects anything else" do
    expect(described_class.valid?("abc1234")).to be false
    expect(described_class.valid?("a" * 129)).to be false
    expect(described_class.valid?("abc_12345")).to be false
    expect(described_class.valid?("abc12345\n")).to be false
  end
end
