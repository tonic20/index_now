class CreateIndexNowAnnouncements < ActiveRecord::Migration[8.0]
  def change
    create_table :index_now_announcements do |t|
      t.string :url, null: false
      t.datetime :lastmod
      t.datetime :announced_at, null: false
    end
    add_index :index_now_announcements, :url, unique: true
  end
end
