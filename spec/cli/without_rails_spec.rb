require "spec_helper"
require "open3"

RSpec.describe "index_now without Rails" do
  let(:root) { File.expand_path("../..", __dir__) }

  def ruby(*args, chdir: root) = Open3.capture3(RbConfig.ruby, "-I#{root}/lib", *args, chdir: chdir)

  it "loads without pulling Rails in" do
    out, err, status = ruby("-e", 'require "index_now"; print defined?(Rails).inspect, " ", defined?(IndexNow::Engine).inspect')

    expect(status).to be_success, err
    expect(out).to eq "nil nil"
  end

  it "runs the index_now command" do
    Dir.mktmpdir do |dir|
      Dir.mkdir(File.join(dir, "public"))
      File.write(File.join(dir, "public/sitemap.xml"), "<urlset><url><loc>https://example.org/</loc></url></urlset>")

      out, err, status = ruby("#{root}/exe/index_now", "pending", chdir: dir)

      expect(status).to be_success, err
      expect(out).to eq "https://example.org/\n"
    end
  end

  it "finds the key file and announces, without ActiveSupport" do
    Dir.mktmpdir do |dir|
      Dir.mkdir(File.join(dir, "public"))
      File.write(File.join(dir, "public/sitemap.xml"), "<urlset/>")
      File.write(File.join(dir, "public/0123456789abcdef.txt"), "0123456789abcdef")

      out, err, status = ruby("#{root}/exe/index_now", "announce", chdir: dir)

      expect(status).to be_success, err
      expect(out).to eq "nothing to announce\n"
    end
  end
end
