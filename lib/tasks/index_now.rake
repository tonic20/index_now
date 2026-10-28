namespace :index_now do
  report = lambda do |result|
    abort "IndexNow failed: #{result.error.message}" unless result.ok?

    if result.disabled?
      puts "IndexNow is disabled in #{Rails.env}; nothing sent"
    elsif result.urls.empty?
      puts "nothing to announce"
    else
      puts "announced #{result.urls.size} url#{"s" unless result.urls.one?}"
      result.urls.each { |url| puts "  #{url}" }
    end
  end

  desc "Announce sitemap urls whose lastmod moved since they were last announced"
  task announce: :environment do
    report.call(IndexNow.announce_changes)
  end

  desc "Announce every sitemap url again, e.g. after rotating the key"
  task announce_all: :environment do
    report.call(IndexNow.announce_all)
  end

  desc "List the urls the next announce would send"
  task pending: :environment do
    urls = IndexNow.pending.map(&:url)
    puts urls.empty? ? "nothing to announce" : urls
  end
end
