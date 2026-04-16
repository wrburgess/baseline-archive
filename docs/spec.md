# Baseline — Spec

**Codename:** Baseline
**Marketing name:** KC Tennis
**Repo (future):** `wrburgess/baseline`
**Dev domain:** `baseline.test`

## 1. What This Is

Baseline is a tennis player profile and head-to-head analysis app for Kansas City–area USTA league captains. It answers two questions:

1. **Scouting (use case A):** "When our players have met their players, what happened?"
2. **Player profile (use case D):** "What do we know about this player — ratings over time, matches, who they played and partnered with?"

It is **not** a lineup optimizer, a prediction model, or a public tennis reference site. Captains use it privately for analysis. Data entry is secondary — the product wins or loses on the quality of its analysis views, not its ingestion pipeline.

## 2. Core Decisions (Lockins from the Grill)

| Area | Decision |
|---|---|
| Data acquisition | Manual + paste-in imports for MVP; no scraping or automated sync |
| Primary use cases | (A) scouting + (D) player profile; defer lineup optimization and public reference tooling |
| Match model | Individual match line as primary; optionally linked to a `TeamMatch` fixture |
| Formats | Adult 18+, 40+, 55+, mixed, tri-level. Format-awareness required for doubles/singles and flexible scoring (standard, match-TB, fast4, pro-set, tiebreak-10, custom) |
| Score storage | Hybrid: `format` enum + structured JSON `sets` + `outcome` enum + explicit `winning_side` + cached `score_display` string |
| Ratings | Time-series `grades` table (from CourtView), keyed by system; per-match snapshot denormalized onto `match_participants` |
| NTRP eligibility | Full history: `rating_type` (S/C/A/M), status, and rationale for each change (self-rated, year-end, mid-year bump, DQ, appeal granted/denied, manual correction) |
| Competitions | `Competition` (container) + `Stage` (phase within it) + persistent `Team` + `TeamStageEntry`. Sectionals/Nationals are stages, not separate competitions. **Entire competition/stage/team layer deferred to v2.** |
| Doubles modeling | `match_participants` join table (one row per player per match). H2H cache denormalized for scouting speed |
| Per-match ratings | Snapshotted onto `match_participants` at commit time; never back-derived |
| Auth | Private captain tool. Devise + Pundit + built-in `system_permissions`. Everything role-gated, no unauthenticated surfaces |
| Match entry (MVP) | Admin CRUD only. No dedicated court-card form, no screenshot parser in v0 |
| Spreadsheet import | v1 — Roo-based template import, preview, commit |
| Screenshot OCR pipeline | v2 — deterministic TennisLink parsers with Tesseract OCR |
| H2H UX | Global search in nav + dedicated H2H page at `/head_to_heads/:a_id/:b_id` + "Compare vs…" on player page |
| H2H notes | Per-pair, captain-private, markdown body |
| Analysis fidelity | Tables only. Zero charts. Blazer handles ad-hoc visual needs |
| Player dedup | Full model: `players` + `player_aliases`, fuzzy resolution via pg_trgm, merge flow in admin, "needs disambiguation" queue. Auto-creation disallowed |
| Rating ingestion | Manual entry for MVP. UTR/WTN values captured as new `grades` rows on every observation (never in-place update) |
| External IDs | `players.ustaid`, `trid`, `utrid`, `wtnid` — all nullable, populated opportunistically |
| Gender | Required at player create |
| Birth year | Optional |
| UI stack | **Bootstrap**, themed via Sass `_variables.scss` to the Baseline design tokens (cool neutral palette, IBM Plex Sans + Mono, 3px radius, rust accent). Custom ViewComponents built on top of Bootstrap primitives. No Tailwind, no Rails Designer purchase. |
| Starting point | Fresh Rails 8.1 template (imported + scrubbed in Week 1); port data from CourtView via one-time Maintenance Task |
| Hosting | Local only. Postgres on the MacBook |

## 3. Schema

### Kept from CourtView (straight port, possibly renamed/enriched)

- `organizations` — top level (USTA, etc.)
- `sections` — USTA sections
- `districts` — USTA districts
- `leagues` — league definitions (name, age_level, gender_type, rating_range, game_format_type, ustaid, trid)
- `seasons`, `years`
- `teams` — the team record
- `team_players` — team roster (players on a team)
- `league_teams` — teams in leagues
- `players` — canonical player record
- `grades` — rating history

### Enriched `grades` (additions)

```
rationale            string (enum)   # self_rated | year_end_computer | early_start_bump |
                                       mid_year_bump | three_strike_dq | appeal_granted |
                                       appeal_denied | manual | unknown_legacy
previous_grade_id    bigint          # self-referential; prior grade this one succeeds
source               string (enum)   # manual | parser_tennislink | bulk_import_courtview
```

### Enriched `players` (additions)

```
preferred_name   string    # nickname ("Bob" vs first_name "Robert")
birth_year       integer   # optional; supersedes age_range string when present
```

### New tables for MVP (v0)

**`player_aliases`**
```
player_id        bigint FK
alias_string     string
source           string (enum)   # captain_entered | parser_observed | imported
confidence       float
```

**`matches`**
```
played_on            date
event_name           string           # "Spring 2025 Adult 40+ 4.0 — Week 3", "Plaza Open", etc.
format               string (enum)    # singles | doubles
rules_format         string (enum)    # best_of_3_standard | best_of_3_match_tb | fast4 |
                                         pro_set_8 | pro_set_10 | match_tb_10 | match_tb_7 | custom
outcome              string (enum)    # completed | retired | defaulted | walkover | timed
winning_side         string (enum)    # home | away | null (for no-winner outcomes)
sets                 jsonb            # [{home, away, tb_home?, tb_away?}, ...]
score_display        string           # denormalized, e.g. "6-4 3-6 10-8"
notes                text
team_match_id        bigint FK null   # linked to TeamMatch (v2); null for standalone
league_id            bigint FK null   # quick backref for MVP; full stage graph in v2
```

**`match_participants`**
```
match_id                     bigint FK
player_id                    bigint FK
side                         string (enum)   # home | away
position                     integer         # 1 | 2 (position 2 null for singles)
partner_id                   bigint FK null  # denormalized: other participant on same side
won                          boolean         # derived at commit; used for fast queries

# rating snapshots at time of match
usta_rating_at_match         decimal
usta_rating_type_at_match    string
utr_rating_at_match          decimal null
wtn_rating_at_match          decimal null
tr_rating_at_match           decimal null
```

**`head_to_head_notes`**
```
player_a_id   bigint FK   # enforced player_a_id < player_b_id (canonical ordering)
player_b_id   bigint FK
body          text         # markdown
author_id     bigint FK    # users.id
```

**`head_to_head_caches`** (denormalized for scouting speed)
```
player_a_id         bigint FK   # always the lower ID
player_b_id         bigint FK   # always the higher ID
format              string (enum)   # all | singles | doubles
wins_a              integer
wins_b              integer
last_played_on      date
total_matches       integer
computed_at         datetime
```

### Deferred to v2

`competitions`, `stages`, `team_stage_entries`, `team_matches`, `match_imports`, screenshot/OCR infrastructure.

## 4. Subsystems

### H2H cache refresh (GoodJob)

On every `Match` commit → enqueue `HeadToHeadCacheRefreshJob(player_a_id, player_b_id)` for every `(a, b)` pair in the match's participants. Job recomputes three cache rows (all / singles / doubles) via aggregation queries on `match_participants`. Idempotent.

### Player resolution (admin + future importers)

When a name string needs to resolve to a Player:
1. Exact match on `usta_id` (if known) → auto-link.
2. Exact match on `first_name + last_name` → single hit auto-proposes; multiple hits require disambiguation.
3. Exact match on `player_aliases.alias_string` → same as above.
4. Fuzzy match via pg_trgm (score ≥ 0.75) → top 5 candidates.
5. No match → captain creates new player manually.

### Merge flow (admin-only)

`Admin::Players::MergeController` — select two players, transactionally re-points `match_participants`, `grades`, `player_aliases`, `team_players`, `head_to_head_notes` from `source` to `target`, creates an alias for the merged player's name, deletes the source record.

### Search (pg_trgm)

Global search in top nav. Indexes on `players.first_name`, `players.last_name`, `players.preferred_name`, `player_aliases.alias_string`. Autocomplete shows Player + affiliation + current NTRP + last-played date.

## 5. Pages (v0)

### Public

- **Global search bar** (top nav, always present): `/` focuses, arrow-key nav, Enter selects
- **`/players/:id`** — Player profile:
  - Header: name, preferred_name, gender, age_range / birth_year if known, affiliation, external IDs (USTA, WTN, Tennis Record)
  - Current ratings grid: NTRP (value, type, status, effective date), WTN dynamic + singles, Tennis Record, UTR placeholders
  - Ratings history table: chronological rows (date, system, value, type, status, rationale)
  - Match history table: date, format (S/D), event, partner, opponents, score, W/L, opponent rating at match. Ransack-filterable. Pagy-paginated.
  - Frequent opponents table (count, W/L vs each)
  - Frequent partners table (count, W/L with each, doubles only)
- **`/head_to_heads/:a_id/:b_id`** — H2H:
  - Header: both names, ratings side by side
  - Aggregate record bar: "A leads 4–2" with format toggle (all / singles / doubles)
  - Context strip: first meeting, most recent, rating deltas then→now
  - Match list table: all matches between them
  - Per-pair scouting notes (markdown, captain-editable)
- **H2H URL is symmetric** — both `/head_to_heads/:a/:b` and `/head_to_heads/:b/:a` resolve; canonical ordering uses lower ID for cache key and notes

### Admin

- `Admin::Players` — index + new/edit + merge
- `Admin::Matches` — index + new/edit (nested `match_participants`)
- `Admin::Grades` — timeline view, inline edit, create
- `Admin::PlayerAliases` — observe/add aliases
- `Admin::HeadToHeadNotes` — index; edit lives on the public H2H page behind captain role
- "Needs disambiguation" queue — Ransack index filtered to ambiguous/low-confidence players

## 6. Auth & Permissions

- Devise for authentication
- Pundit for authorization
- Built-in `system_permissions` + `system_roles` for role definitions (`admin`, `captain`)
- **No unauthenticated surfaces in v0.** Every route requires login; Pundit enforces role checks.
- `Player.user_id` nullable FK so player-accounts can be introduced in a future release without migration pain. Not used in v0.

## 7. Data Migration from CourtView

One-time `Maintenance Task` — `MaintenanceTasks::MigrateFromCourtview` — reads the old CourtView Postgres (local MacBook). For MVP the task is re-runnable against a staging copy; final cutover is a single production run.

**Mapping outline:**

| CourtView | Baseline | Notes |
|---|---|---|
| `organizations` | `organizations` | 1:1 |
| `sections` | `sections` | 1:1 |
| `districts` | `districts` | 1:1 |
| `leagues` | `leagues` | 1:1 |
| `teams` | `teams` | 1:1 |
| `team_players` | `team_players` | 1:1 |
| `league_teams` | `league_teams` | 1:1 |
| `seasons`, `years` | `seasons`, `years` | 1:1 |
| `players.*` | `players.*` | Straight port; `age_range` preserved; `preferred_name` null; `birth_year` parsed from `age_range` only if it contains a clean birth year, else null |
| `grades.*` | `grades.*` | Straight port; `rationale: "unknown_legacy"`; `previous_grade_id` null |
| (no source) | `matches`, `match_participants`, `player_aliases`, `head_to_head_notes`, `head_to_head_caches` | Empty at migration; populated via admin CRUD post-cutover |

**Decisions needed during migration (tactical, not design):**

- `current_utrd_rating` vs `current_utrs_rating` meaning — confirm during implementation whether "d" means dynamic (UTR parlance) or doubles, and "s" means singles. UTR convention says UTR_d = doubles, UTR_s = singles — but "dynamic" interpretation also exists. Resolve by reading a few existing CourtView rows against a known player's UTR page.
- `current_usta_rating_type` and `current_usta_rating_status` string values → enum translation table. Likely values in CourtView: "C", "S", "A", "M" and "active", "DQ", etc. Confirm during implementation.

## 8. Scope — v0 / v1 / v2

### v0 — "Captains can scout"

**Schema:**
- Port existing CourtView tables into Baseline's new migration files (one initial migration).
- Add `matches`, `match_participants`, `player_aliases`, `head_to_head_notes`, `head_to_head_caches`.
- Enrich `grades` (rationale, previous_grade_id, source) and `players` (preferred_name, birth_year).

**Data:**
- One-time CourtView → Baseline migration runs clean.

**Features:**
- Admin CRUD: Players, Matches, Grades, PlayerAliases, HeadToHeadNotes, merge flow, needs-disambiguation queue.
- Public: global search, `/players/:id`, `/head_to_heads/:a_id/:b_id`.
- H2H cache refresh on Match commit.
- Bootstrap themed to Baseline design tokens via Sass overrides. Custom ViewComponents (`Baseline::Ui::*`) wrap Bootstrap primitives (`.table`, `.btn-group`, `.badge`, `.card`, `.accordion`, Popper tooltips) and add the bits Bootstrap lacks (RatingsGrid, ScoreGrid, info-dot tooltip, ParticipantCard, AdminMasthead).

**Explicitly not in v0:**
- Competitions, Stages, TeamStageEntries, TeamMatches (v2).
- Any match importer (spreadsheet → v1; screenshot OCR → v2).
- Court-card entry form (admin form is entry form for v0).
- UTR rating ingestion flow (manual field only).
- Charts, timelines, visualizations.
- Notification triggers (no collaboration events exist in v0 worth notifying on).

### v1 — "Easier bulk entry"

Roo-based spreadsheet import: captain downloads template, fills rows, uploads, preview screen shows parsed data + player resolution, commit button.

### v2 — "Nice-to-haves"

Screenshot OCR + deterministic TennisLink parsers, Competition/Stage/TeamMatch modeling with team-context scouting, UTR rating ingestion path.

## 9. Build Sequence (v0)

Rough week-by-week for weekend/evening pace. Absolute durations vary; ordering is the thing.

1. **Week 1** — Repo init: import a fresh Rails 8.1 template (Bootstrap stack, Devise + Pundit + `system_permissions`, GoodJob, ViewComponent, RSpec/Capybara/FactoryBot). Theme Bootstrap via Sass: design tokens (cool neutral palette, rust accent, 3px radius), IBM Plex Sans + Mono via Google Fonts. Devise + `system_permissions` wiring. Smoke test: `bin/setup`, `bin/rails s`, sign in, admin renders cleanly with Baseline theming.
2. **Week 2** — Schema: port CourtView tables (modified), add new tables, write migrations. Seed a few players and grades by hand to test. Base ActiveRecord models, validations, factories.
3. **Week 3** — Data migration task: write `MaintenanceTasks::MigrateFromCourtview` against a CourtView DB copy. Iterate until clean.
4. **Week 4** — Admin: Players CRUD, Grades CRUD, merge flow, aliases, needs-disambiguation queue. Pundit policies per resource.
5. **Week 5** — Public shell: global search + player profile page. Cash in on the data migration — this is the first page that's satisfying to use.
6. **Week 6** — Matches: Admin CRUD for Match + MatchParticipant (nested). H2H cache refresh job. Add real matches through the UI.
7. **Week 7** — H2H page + per-pair notes. Compare-vs search on player page. Cache validated with real data.
8. **Week 8** — Polish: empty states, search perf, Pundit coverage, RSpec for critical paths, Pagy on everything paginatable.

v0 shippable at week 8. Adjust pace to calendar.

## 10. Testing Posture

The stack ships RSpec, Capybara, FactoryBot, shoulda-matchers, timecop, VCR, WebMock. For v0 at hobby pace:

- **Model specs** — validations, key scopes, resolution algorithm, H2H cache refresh logic. Must-have.
- **Policy specs** — one per Pundit policy. Cheap and critical for a role-locked app.
- **System specs** — one "happy path" per public page (search → player profile, player profile → H2H, admin match create). Thin coverage; Capybara is slow, don't over-invest.
- **Request specs** — skip for v0 unless a specific endpoint has logic outside a policy.
- **H2H cache job** — unit-tested with real data fixtures.

No coverage threshold. Fix bugs by adding a spec, not by targeting a number.

## 11. Deferred / Open Questions

These were raised during the grill and intentionally not resolved:

- **Venue / court surface tracking on matches** — not in v0 schema. Add as `venue_id` FK + surface enum later if analysis demands it.
- **Recent-form dots, shared-partners analysis, per-player notes, frequent-opponents-by-rating splits** — analysis polish, post-v0.
- **Notification triggers** — none in v0. First candidates (post-v0): notify captain when a merge proposal needs review; notify when an import has errors.
- **Rating-at-time-of-match for legacy CourtView `grades`** — the data migration carries values forward, but CourtView has no matches, so no retroactive snapshots are computable. Matches entered post-migration use current-known ratings as their snapshots.

---

*This spec is the output of a 22-question grill session. Changes post-lockin need a new grill, not a silent edit.*
