require "spec_helper"

RSpec.describe "index_now.gemspec" do
  let(:gemspec) { Gem::Specification.load(File.expand_path("../index_now.gemspec", __dir__)) }

  it "ships the migration once, as the install generator's template" do
    expect(gemspec.files.grep(/announcements/)).to eq [ "lib/generators/index_now/install/templates/create_index_now_announcements.rb.tt" ]
  end
end
