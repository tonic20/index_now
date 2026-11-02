require "spec_helper"

RSpec.describe "index_now.gemspec" do
  let(:gemspec) { Gem::Specification.load(File.expand_path("../index_now.gemspec", __dir__)) }

  it "ships the migration once, as the install generator's template" do
    expect(gemspec.files.grep(/announcements/)).to eq [ "lib/generators/index_now/install/templates/create_index_now_announcements.rb.tt" ]
  end

  it "ships the index_now command" do
    expect(gemspec.executables).to eq [ "index_now" ]
    expect(gemspec.files).to include "exe/index_now"
  end

  it "leaves Rails to the apps that have it" do
    expect(gemspec.runtime_dependencies.map(&:name)).to eq [ "nokogiri" ]
  end
end
