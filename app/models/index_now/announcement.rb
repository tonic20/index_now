module IndexNow
  class Announcement < ActiveRecord::Base
    self.table_name = "index_now_announcements"

    def self.due(entries)
      announced = where(url: entries.map(&:url)).pluck(:url, :lastmod).to_h
      entries.select { |entry| entry.due?(announced) }
    end

    def self.record!(entries)
      return if entries.empty?

      now = Time.current
      upsert_all(entries.map { |entry| { url: entry.url, lastmod: entry.lastmod, announced_at: now } }, unique_by: :url)
    end
  end
end
