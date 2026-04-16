# Baseline

A tennis player profile and head-to-head analysis app for USTA league captains.

Private captain tool for scouting and player-profile analysis. Not a lineup optimizer, not a prediction model, not a public tennis reference site.

## Stack

- **Ruby** 4.0.2 / **Rails** 8.1
- **PostgreSQL** 18 (local)
- **UI:** Bootstrap 5 themed via Sass to the Baseline design tokens (see `docs/designs/`)
- **Auth:** Devise + Pundit, role-gated via built-in `system_permissions`
- **Jobs:** GoodJob
- **Testing:** RSpec, Capybara, FactoryBot, shoulda-matchers, timecop, VCR, WebMock

## Getting Started

```bash
bin/setup                      # install gems, create db, seed
bin/rails credentials:edit --environment development
bin/dev                        # start Rails, esbuild, Sass watchers
open http://baseline.test:3000
```

Add `127.0.0.1 baseline.test` to your `/etc/hosts` (or use `localhost:3000` directly).

## Project Layout

```
app/            Rails application code
  components/   ViewComponents (Admin::* + Baseline::Ui::*)
  policies/    Pundit policies — all admin resources role-gated
config/        Rails config, routes, environments
db/            Migrations + seeds
docs/
  spec.md      The v0 spec (see this first)
  designs/     HTML mockups for player profile, H2H, admin match edit
spec/          RSpec specs (model, policy, component, system)
```

## Documentation

- [`docs/spec.md`](docs/spec.md) — v0 engineering spec, scope, schema, build sequence
- [`docs/designs/`](docs/designs/) — HTML mockups that define the visual language

## Development

- [`CLAUDE.md`](CLAUDE.md) — guidance for Claude Code sessions on this repo
- [`AGENTS.md`](AGENTS.md) — guidance for generic coding agents

## License

Private project. Not open source.
