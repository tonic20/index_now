# index_now

Tells search engines which pages of a Rails app changed, through
[IndexNow](https://www.indexnow.org), so they recrawl them without waiting.

It reads the app's own sitemap, announces every URL whose `<lastmod>` moved
since it last announced that URL, and records what it sent. Running it when
nothing changed sends nothing, so it is safe to call as often as you like.

**What it reaches:** `api.indexnow.org` shares each submission with Bing (which
also backs ChatGPT search and Copilot), Yandex, Seznam, Naver and Yep.
**Google is not an IndexNow participant**; nothing here affects Google.

## Install

```ruby
gem "index_now"
```

```sh
bin/rails generate index_now:install   # or --key=<existing key>
bin/rails db:migrate
```

The generator writes:

- `public/<key>.txt`: the key file the engines fetch to verify you own the host.
  The key is not a secret; commit it.
- `config/initializers/index_now.rb`
- a migration for `index_now_announcements`, one row per URL announced.

```ruby
IndexNow.configure do |config|
  config.key = "…"
  config.host = "example.com"          # defaults to routes.default_url_options[:host]
  config.sitemap_path = "/sitemap.xml" # the default
  config.enabled = Rails.env.production? # the default
end
```

The sitemap is requested in-process (`Rails.application.call`) as
`https://<host><sitemap_path>`, so the host must pass `config.hosts`.

## The rule

A URL is announced when it has never been announced, or when its `<lastmod>`
is newer than the one last announced for it. A URL with no `<lastmod>` is
announced once and never again, so give every page you want re-announced a
`<lastmod>`:

- **Copy:** a date you bump by hand when the page's text changes. Never the
  deploy time; that announces every page on every deploy.
- **Data:** the time the data behind the page last changed.

`<sitemapindex>` files are not supported.

## Triggering it

```ruby
IndexNow.announce_changes # => #<data IndexNow::Result urls=[…], error=nil>
```

Call it after the data is committed: the sitemap is read on a separate thread
and connection. It never raises: a failure is logged, reported through `Rails.error`, and
returned as `result.error`. Nothing is recorded for a URL until the POST that
carried it succeeded, so the next call retries it.

**After a deploy** (for copy), from `.kamal/hooks/post-deploy`:

```sh
if [ "$KAMAL_DESTINATION" = "production" ]; then
  bin/kamal app exec -d production --reuse --primary "bin/rails index_now:announce" || true
fi
```

**After the app changes data** (for data pages), from the job that wrote it:

```ruby
def perform
  Stats.rebuild!
  IndexNow.announce_changes
end
```

## Tasks

```sh
bin/rails index_now:pending       # what the next announce would send
bin/rails index_now:announce      # send it; exits 1 on failure, says so when disabled
bin/rails index_now:announce_all  # send every sitemap URL again
```

## Rotating the key

Rename `public/<old key>.txt` to the new key, put the same key in its body and in
`config.key`, deploy, check `https://<host>/<key>.txt` answers 200, then run
`index_now:announce_all`.

## License

MIT
