# GitHub Copilot Instructions for Baseline

For the full agent-facing guidance, see [`AGENTS.md`](../AGENTS.md). That file is the source of truth for project context, tech stack, conventions, and anti-patterns. This file mirrors the essentials so Copilot picks them up.

## About This Project

Baseline is a private tennis player profile and head-to-head analysis app for USTA league captains in Kansas City. Personal project, public repo. See [`docs/spec.md`](../docs/spec.md) for full scope, schema, and build sequence.

## Tech Stack

Ruby 4.0.2 / Rails 8.1 / PostgreSQL 18 / Hotwire (Turbo + Stimulus) / Bootstrap 5.3 / ViewComponent / esbuild + Sass / Devise + Pundit + built-in `system_permissions` / GoodJob. See `.tool-versions`, `Gemfile`, and `package.json` for exact versions.

## Commands

```bash
bin/setup                              # Install + db create/migrate/seed
bin/dev                                # Full dev stack (web, js, css watchers)
bundle exec rspec                      # All tests
bundle exec rubocop -a                 # Lint + auto-correct
bin/brakeman --no-pager -q             # Security scan
bin/bundler-audit check                # Vulnerable dependencies
```

## Pre-Commit Requirements

All four must pass:

1. `bundle exec rubocop -a` — zero offenses
2. `bundle exec rspec` — zero failures
3. `bin/brakeman --no-pager -q` — no warnings
4. `bin/bundler-audit check` — no vulnerabilities

## Asset Pipeline

Two separate esbuild pipelines — admin and public:

| Pipeline | JS Entry | CSS Entry | Layout | Route Prefix |
|----------|----------|-----------|--------|--------------|
| Admin | `app/javascript/admin/index.js` | `app/assets/stylesheets/admin.scss` | `admin.html.erb` | `/admin/` |
| Public | `app/javascript/public/index.js` | `app/assets/stylesheets/public.scss` | `application.html.erb` / `devise.html.erb` | `/` |

Each pipeline owns its own Stimulus Application instance and controllers.

## Architecture

- **Authorization:** Pundit with `User → SystemGroups → SystemRoles → SystemPermissions`. Every admin action must call `authorize`.
- **Forms:** tom-select for selects (`wrapper: :tom_select_label_inset`), floating labels for text (`wrapper: :floating_label_form`).
- **ViewComponents:** directory-per-component in `app/components/admin/`. Inherit from `ApplicationComponent`.
- **Models:** include concerns `Archivable`, `Loggable`, `Notifiable` where applicable.
- **Jobs:** GoodJob (Postgres-backed, no Redis).

## Anti-Patterns (Never Do)

- Never suggest React, Vue, Alpine, or other JS frameworks — Hotwire only
- Never add Tailwind — Baseline is Bootstrap-only, themed via Sass
- Never use inline JavaScript — Stimulus controllers only
- Never use fixtures — FactoryBot only
- Never use controller specs — request specs only
- Never hard-delete archivable records — use `archive!` / `unarchive!`
- Never add a global `master.key` or `credentials.yml.enc` — per-environment credentials only
- Never skip `authorize` in admin controller actions
- Never use Redis for background jobs
- Never hardcode permission checks — use Pundit policies and `access_authorized?`
- Never use `default_scope` — named scopes only
- Never reintroduce references to prior template lineage — the codebase originated from another Rails template and all references were scrubbed

## Agent Attribution

- **Commits:** `Co-Authored-By: GitHub Copilot <noreply@github.com>` (or the appropriate agent)
- **PRs / comments:** Brief attribution line

## Review Guidelines

### P0 — Must Fix
- Security issues (SQL injection, XSS, missing authorization)
- Missing `authorize` in admin actions
- Broken or meaningless tests
- Secrets in code
- Data loss risks

### P1 — Should Fix
- N+1 queries
- Missing validations
- Pattern violations
- Missing tests for new functionality

### P2 — Consider
- Naming, performance, extra edge cases

## Documentation

- [`docs/spec.md`](../docs/spec.md) — v0 engineering spec
- [`docs/designs/`](../docs/designs/) — HTML mockups
- [`CLAUDE.md`](../CLAUDE.md) / [`AGENTS.md`](../AGENTS.md) — agent guidance
- [`.claude/rules/`](../.claude/rules/) — auto-loaded rulesets
