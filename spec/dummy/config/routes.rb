Rails.application.routes.draw do
  get "sitemap.xml", to: "sitemaps#show"
end
