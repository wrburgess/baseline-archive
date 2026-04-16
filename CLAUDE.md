# CLAUDE.md

Baseline is a private tennis player profile and head-to-head analysis app for USTA league captains in Kansas City. Built for scouting (use case A: "what happened when our players met theirs?") and player profiles (use case D: "what do we know about this player?").

Personal project. Public repo. Not open source — private use only.

See [`docs/spec.md`](docs/spec.md) for the engineering spec, scope, schema, and build sequence. All v0 work is captain-only — no unauthenticated surfaces. See [`docs/designs/`](docs/designs/) for the visual language (cool neutral palette, IBM Plex Sans + Mono, 3px radius, rust accent).

## Stack

- Ruby 4.0.2 / Rails 8.1 / PostgreSQL 18
- Bootstrap 5 themed via Sass to the Baseline design tokens — no Tailwind
- Devise + Pundit with built-in `system_permissions` (User → SystemGroups → SystemRoles → SystemPermissions)
- GoodJob for background jobs
- esbuild dual-pipeline (admin + public bundles), Propshaft
- ViewComponent for the component layer; custom `Baseline::Ui::*` components wrap Bootstrap primitives
- RSpec / Capybara / FactoryBot / shoulda-matchers / timecop / VCR / WebMock

## Quality Expectations

- Research the codebase before proposing solutions — read existing code, don't guess from file names
- Check if Rails conventions or established gems already solve the problem before building custom
- Explain why you chose an approach over alternatives — in assessments, plans, and PR descriptions
- Never declare work done until rubocop + rspec + brakeman + bundler-audit pass
- Testing is a first-class deliverable. Model specs + policy specs are must-haves; system specs for happy paths only. Don't chase coverage numbers — write tests that protect against regressions
- Run tests as you develop, not just before committing

## Anti-Patterns (Never Do)

- Never hard-delete archivable records — use `archive!` / `unarchive!`
- Never add a global `master.key` or `credentials.yml.enc` — per-environment credentials only (`bin/rails credentials:edit --environment development`)
- Never skip `authorize` in admin controller actions
- Never add Tailwind — Baseline is Bootstrap-only, themed via Sass
- Never introduce new references to prior template lineage (the codebase started from another Rails template; all references to that template were scrubbed and must stay gone)

Domain-specific anti-patterns auto-load from `.claude/rules/` when touching relevant files:
- `.claude/rules/backend.md` — models, controllers, jobs, authorization, gem preferences
- `.claude/rules/frontend.md` — JavaScript, views, components, assets
- `.claude/rules/testing.md` — specs, factories, definition of done
- `.claude/rules/security.md` — credentials, scanning, secrets
- `.claude/rules/migrations.md` — database migrations, strong_migrations
- `.claude/rules/self-review.md` — quality checklist before declaring done

## Required Workflow

Before committing or pushing:

```bash
bundle exec rubocop -a
bundle exec rspec
bin/brakeman --no-pager -q
bin/bundler-audit check
```

All four must pass.

## Development Workflow

- Work happens on feature branches off `main`; PRs required to merge
- CI runs rubocop + rspec on every PR (`.github/workflows/ci.yml`)
- GitHub Issues track work; GitHub Projects tracks weeks (see the v0 build sequence in `docs/spec.md` §9)

## Permissions and Autonomy

- **Feature branches:** Full autonomy — commit, edit, refactor without asking. Only ask for requirement clarification
- **`main` branch:** Ask before any changes. Check first: `git branch --show-current`
- **Core business logic** (auth, data integrity, match scoring, H2H aggregation): flag to the HC and work synchronously
- **Standard patterns** (CRUD, admin views, test generation, refactoring): work autonomously per branch permissions

## Commit and PR Standards

- Commit messages: summary line + detailed body (what, why, approach, decisions)
- PRs: Summary, Changes, Technical Approach, Testing, Checklist sections
- Reference related issues: `Closes #123` / `Refs #123`

## Key Commands

```bash
bin/setup                                      # install + db setup
bin/dev                                        # Rails + esbuild + Sass watchers
bin/rails credentials:edit --environment development
bundle exec rspec                              # run specs
bundle exec rubocop -a                         # autocorrect lint
bin/kamal deploy                               # production deploy (when configured)
```

## Architecture Pointers

- **Authorization** — Pundit policies delegate to `user.access_authorized?(resource:, operation:)`. Role seed data in `db/seeds/system_permissions.rb`
- **Asset pipeline** — Two esbuild bundles: `app/javascript/admin/index.js` and `app/javascript/public/index.js`. Two Sass roots: `app/assets/stylesheets/admin.scss` and `public.scss`
- **ViewComponents** — Admin namespace under `app/components/admin/`; Baseline UI primitives will live under `app/components/baseline/ui/` as they're built
- **Design tokens** — Source of truth in `docs/designs/*.html` `:root` CSS vars. Mapped to Bootstrap Sass variables in `app/assets/stylesheets/_baseline_tokens.scss`
