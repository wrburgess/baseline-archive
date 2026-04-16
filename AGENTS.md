# AGENTS.md

Instructions for AI coding agents (Claude Code, Copilot, Codex, Cursor, and others) working in this repository.

## About This Project

Baseline is a private tennis player profile and head-to-head analysis app for USTA league captains in Kansas City. Personal project, public repo. See [`docs/spec.md`](docs/spec.md) for full scope, schema, and build sequence.

Two primary use cases drive everything:
- **Scouting** — "When our players have met their players, what happened?"
- **Player profile** — "What do we know about this player — ratings over time, matches, who they played and partnered with?"

It is **not** a lineup optimizer, prediction model, or public tennis reference site.

## Tech Stack

- **Ruby** 4.0.2 / **Rails** 8.1 / **PostgreSQL** 18
- **Frontend:** Hotwire (Turbo + Stimulus) + Bootstrap 5.3, themed via Sass to the Baseline design tokens. No Tailwind, no React/Vue/Alpine
- **Components:** ViewComponent; admin components under `app/components/admin/`, Baseline UI primitives under `app/components/baseline/ui/`
- **Assets:** esbuild dual-pipeline (admin + public) + Sass + Propshaft
- **Auth:** Devise (authentication) + Pundit (authorization) with built-in `system_permissions` (User → SystemGroups → SystemRoles → SystemPermissions)
- **Jobs:** GoodJob (Postgres-backed, no Redis)
- **Testing:** RSpec, Capybara, FactoryBot, shoulda-matchers, timecop, VCR, WebMock

See `.tool-versions`, `Gemfile`, and `package.json` for exact versions.

## Commands

```bash
bin/setup                              # Install + db create/migrate/seed
bin/dev                                # Full dev stack (web, js, css watchers)
bundle exec rspec                      # All tests
bundle exec rspec spec/models/foo_spec.rb:42  # Single line
bundle exec rubocop -a                 # Lint + auto-correct
bin/brakeman --no-pager -q             # Security scan
bin/bundler-audit check                # Vulnerable dependencies
```

## Pre-Commit Requirements

All four must pass before committing:

1. `bundle exec rubocop -a` — zero offenses
2. `bundle exec rspec` — zero failures
3. `bin/brakeman --no-pager -q` — no warnings
4. `bin/bundler-audit check` — no vulnerabilities

## Testing

- RSpec with FactoryBot (never fixtures)
- Request specs for controllers (not controller specs)
- Minimize mocks — use real objects where feasible
- **Permission strategy:** policy specs use real permission records; request specs stub Pundit; feature specs use `authorized_admin_setup`; component/model/job specs need no permission setup
- Coverage posture per `docs/spec.md` §10: model + policy specs are must-haves, one system spec per public page for happy paths, request specs only for endpoints with logic outside policy

## Asset Pipeline

Two completely separate pipelines — admin and public:

| Pipeline | JS Entry | CSS Entry | Layout | Route Prefix |
|----------|----------|-----------|--------|--------------|
| Admin | `app/javascript/admin/index.js` | `app/assets/stylesheets/admin.scss` | `admin.html.erb` | `/admin/` |
| Public | `app/javascript/public/index.js` | `app/assets/stylesheets/public.scss` | `application.html.erb` | `/` |

Each pipeline has its own Stimulus Application instance. Admin imports Bootstrap JS + Tom Select; public imports Bootstrap JS for the Devise sign-in layout.

## Architecture

| Concern | Admin | Public |
|---------|-------|--------|
| Base Controller | `AdminController` | `ApplicationController` |
| Auth | Devise + Pundit (role-gated) | Devise (everyone needs to sign in — no unauthenticated surfaces in v0) |
| Routes | `namespace :admin` | Root-level |
| Components | `app/components/admin/` | `app/components/baseline/ui/` (shared UI primitives) |

Key patterns:
- **Authorization:** every admin controller action calls `authorize`. Pundit policies delegate to `user.access_authorized?(resource:, operation:)`
- **Forms:** tom-select for selects (`wrapper: :tom_select_label_inset`), floating labels for text
- **Models:** include concerns `Archivable` (soft delete), `Loggable` (audit trail), `Notifiable` (events)
- **Enumerables:** module in `app/modules/` + concern in `app/models/concerns/`
- **Player resolution** (future week): exact-match cascade → pg_trgm fuzzy → manual disambiguation. See `docs/spec.md` §4
- **H2H cache refresh** (future week): GoodJob `HeadToHeadCacheRefreshJob` enqueued on `Match` commit

## Anti-Patterns (Never Do)

- Never suggest React, Vue, Alpine, or other SPA frameworks — Hotwire only
- Never add Tailwind — Baseline is Bootstrap-only, themed via Sass
- Never use inline JavaScript — Stimulus controllers only
- Never use fixtures — FactoryBot only
- Never use controller specs — request specs only
- Never hard-delete archivable records — use `archive!` / `unarchive!`
- Never add a global `master.key` or `credentials.yml.enc` — per-environment credentials only
- Never skip `authorize` in admin controller actions
- Never use Redis for background jobs — GoodJob is Postgres-backed
- Never mix admin and public assets — separate pipelines, separate Stimulus controllers
- Never hardcode permission checks — use Pundit policies and `access_authorized?`
- Never use `policy_scope` without defining `ransackable_attributes`
- Never use `default_scope` — named scopes only
- Never reintroduce references to prior template lineage — the codebase originated from another Rails template and all references were scrubbed. Keep them gone
- Prefer Rails per-environment credentials over `ENV` for application secrets. `ENV` is fine for runtime/platform vars (`DATABASE_URL`, `PORT`, `RAILS_ENV`)
- Never disable Brakeman or Bundler-Audit warnings without a documented justification comment

## Review Guidelines

### P0 — Must Fix
- Security vulnerabilities (SQL injection, XSS, missing authorization)
- Missing `authorize` call in admin controller actions
- Broken tests or tests that don't test what they claim
- Credentials or secrets in code
- Data loss risks (irreversible migrations, missing `dependent:`)

### P1 — Should Fix
- N+1 queries (use `includes` / `eager_load`)
- Missing validations for required business constraints
- Pattern violations (architecture, naming, structure)
- Missing tests for new functionality

### P2 — Consider
- Naming improvements
- Performance optimizations
- Additional edge case coverage

## Development Workflow

- All work happens on feature branches off `main`
- PRs required to merge; CI must pass
- GitHub Issues track individual tasks; a GitHub Project tracks the v0 build sequence (see `docs/spec.md` §9)
- `main` is protected — agents should not push to it directly

## Agent Attribution

- **Commits:** `Co-Authored-By: <Agent Name> <email>` trailer
- **PRs:** Agent name in the footer
- **Comments:** Attribution line (e.g., `— Claude Code (Opus 4.6)`)

If multiple agents contribute, include one `Co-Authored-By` line per agent.

## PR Instructions

- PR title: under 70 characters, descriptive
- PR body sections: Summary, Changes, Technical Approach, Testing, Checklist
- Link to issue: `Closes #NNN` or `Refs #NNN`

## Documentation

- [`docs/spec.md`](docs/spec.md) — v0 engineering spec (schema, scope, build sequence, open questions)
- [`docs/designs/`](docs/designs/) — HTML mockups defining the visual language
- [`CLAUDE.md`](CLAUDE.md) — Claude Code-specific guidance
- [`.claude/rules/`](.claude/rules/) — rulesets auto-loaded by Claude Code when editing relevant files
