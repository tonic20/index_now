require_relative "lib/index_now/version"

Gem::Specification.new do |spec|
  spec.name        = "index_now"
  spec.version     = IndexNow::VERSION
  spec.authors     = ["Anton Kopylov"]
  spec.summary     = "Announce a Rails app's or a static site's changed sitemap URLs to IndexNow"
  spec.description = "Reads the site's own sitemap, announces every URL whose lastmod moved since it was " \
                     "last announced to api.indexnow.org, and records what it sent so nothing is announced twice. " \
                     "A Rails engine for apps, an index_now command for static sites."
  spec.homepage    = "https://www.kopylov.net/blog/index-now-telling-search-engines-what-changed.html"
  spec.license     = "MIT"

  spec.metadata["homepage_uri"]    = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/tonic20/index_now"
  spec.metadata["changelog_uri"]   = "https://github.com/tonic20/index_now/blob/main/CHANGELOG.md"

  spec.required_ruby_version = ">= 3.3"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,exe,lib}/**/*", "README.md", "LICENSE.txt", "CHANGELOG.md"]
  end
  spec.bindir      = "exe"
  spec.executables = [ "index_now" ]

  spec.add_dependency "nokogiri", "~> 1.16"
end
