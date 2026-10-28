require_relative "lib/index_now/version"

Gem::Specification.new do |spec|
  spec.name        = "index_now"
  spec.version     = IndexNow::VERSION
  spec.authors     = ["Anton Kopylov"]
  spec.summary     = "Announce a Rails app's changed sitemap URLs to IndexNow"
  spec.description = "Reads the app's own sitemap, announces every URL whose lastmod moved since it was " \
                     "last announced to api.indexnow.org, and records what it sent so nothing is announced twice."
  spec.homepage    = "https://github.com/tonic20/index_now"
  spec.license     = "MIT"

  spec.metadata["homepage_uri"]    = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"]   = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.required_ruby_version = ">= 3.3"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,db,lib}/**/*", "README.md", "LICENSE.txt", "CHANGELOG.md"]
  end

  spec.add_dependency "rails", "~> 8.0"
  spec.add_dependency "nokogiri", "~> 1.16"
end
