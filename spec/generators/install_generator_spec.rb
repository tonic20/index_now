require "spec_helper"
require "generators/index_now/install/install_generator"

RSpec.describe IndexNow::Generators::InstallGenerator do
  let(:root) { Dir.mktmpdir }

  after { FileUtils.rm_rf(root) }

  def run_generator(*args) = described_class.start([ *args, "--quiet" ], destination_root: root)

  it "publishes a fresh key and configures the same one" do
    run_generator

    key_file = Dir[File.join(root, "public/*.txt")].sole
    key = File.basename(key_file, ".txt")
    expect(key).to match(/\A\h{32}\z/)
    expect(File.read(key_file)).to eq key
    expect(File.read(File.join(root, "config/initializers/index_now.rb"))).to include(%(config.key = "#{key}"))
  end

  it "keeps a key it is given" do
    run_generator("--key=42b1f9c9f9434c87")

    expect(File.read(File.join(root, "public/42b1f9c9f9434c87.txt"))).to eq "42b1f9c9f9434c87"
  end

  it "rejects a key IndexNow would not accept" do
    expect { run_generator("--key=short") }.to raise_error(ArgumentError, /8 to 128/)
  end

  it "copies the announcements migration" do
    run_generator

    migration = Dir[File.join(root, "db/migrate/*_create_index_now_announcements.rb")].sole
    expect(File.read(migration)).to include("create_table :index_now_announcements")
  end
end
