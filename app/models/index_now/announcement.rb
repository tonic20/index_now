module IndexNow
  class Announcement < ActiveRecord::Base
    self.table_name = "index_now_announcements"

    def self.due(entries)
      announced = where(url: entries.map(&:url)).pluck(:url, :lastmod).to_h

      entries.select do |entry|
        next true unless announced.key?(entry.url)

        previous = announced[entry.url]
        entry.lastmod && (previous.nil? || entry.lastmod > previous)
      end
    end

    def self.record!(entries)
      return if entries.empty?

      now = Time.current
      upsert_all(entries.map { |entry| { url: entry.url, lastmod: entry.lastmod, announced_at: now } }, unique_by: :url)
    end
  end
end
