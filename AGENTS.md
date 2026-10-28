# AGENTS.md

Rules for AI agents working on the `index_now` gem.

## What this gem is

It announces a Rails app's changed pages to IndexNow. The app's own sitemap is
the only input: a URL is due when it was never announced or its `<lastmod>`
moved past the one last announced. `index_now_announcements` holds one row per
URL announced.

## Layout

- `lib/index_now.rb`: configuration and the entry points (`pending`,
  `announce_changes`, `announce_all`).
- `lib/index_now/sitemap.rb`: in-process sitemap read.
- `lib/index_now/client.rb`: the POST to `api.indexnow.org`.
- `app/models/index_now/announcement.rb`: what is due, and recording it.
- `lib/generators/index_now/install/`: key file, initializer, migration.
- `spec/`: RSpec against `spec/dummy` (SQLite). Host apps run Postgres too.

## Rules

1. **An announcement never breaks its caller.** `announce_changes` rescues,
   reports to `Rails.error` and returns the error. Deploy hooks and data jobs
   call it.
2. **Never re-announce an unchanged URL.** Engines learn to ignore hosts that
   do. A row is written only after its POST succeeded.
3. **Ruby 3.3 floor:** no `it` block parameter.
4. Keep everything under `IndexNow::`. No host-app constants.
5. Comments only for what code and names cannot say; two lines at most.

## Versioning and release

- SemVer. Bump `lib/index_now/version.rb` and add a dated `CHANGELOG.md`
  section with every feature or fix.
- After the release commit lands on `main`: `git tag -a vX.Y.Z -m "vX.Y.Z"`
  and push the tag.
- Do **not** run `gem push`: it needs the maintainer's RubyGems MFA. Build with
  `gem build index_now.gemspec` and hand the `.gem` off.

## Before declaring done

- [ ] `bundle exec rspec` green
- [ ] version bumped, CHANGELOG updated
