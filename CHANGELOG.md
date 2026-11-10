# Changelog

## [0.2.2] — 2026-11-10

- Point the gem homepage to the introductory blog post, keeping source code
  and changelog links on GitHub.

## [0.2.1] — 2026-11-02

- `index_now announce` no longer needs ActiveSupport to find the key file;
  0.2.0 failed with ``undefined method `sole'`` outside Rails.

## [0.2.0] — 2026-11-02

- Static sites: an `index_now` command (`init`, `pending`, `announce`,
  `announce --all`) reads the built sitemap and records what it sent in
  `.index_now.json`, with the same rule as the Rails engine.
- Rails is no longer a dependency; the engine loads only when Rails is present.
- `IndexNow::Client.submit!` takes the key as `key:`.
- The migration ships only as the install generator's template, so
  `index_now:install:migrations` can no longer add a second copy.

## [0.1.0] — 2026-10-28

- First release: announces sitemap URLs whose `lastmod` moved to IndexNow,
  records what was sent, and never raises from `IndexNow.announce_changes`.
- `index_now:announce`, `index_now:pending` and `index_now:announce_all` tasks.
- `index_now:install` generator for the key file, initializer and migration.
