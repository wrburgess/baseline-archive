## Summary

<!-- 1–3 sentences. What does this PR do and why? -->

## Changes

<!-- Bullet list of concrete changes. File paths welcome. -->

-
-

## Technical Approach

<!-- Why did you pick this approach over alternatives? Any trade-offs worth noting? -->

## Testing

<!-- How was this verified? What specs were added/changed? -->

- [ ] `bundle exec rubocop -a` — zero offenses
- [ ] `bundle exec rspec` — zero failures
- [ ] `bin/brakeman --no-pager -q` — no warnings
- [ ] `bin/bundler-audit check` — no vulnerabilities

## Checklist

- [ ] Linked an issue (`Closes #NNN` / `Refs #NNN`) if applicable
- [ ] Touched views/components have matching theme tokens (no hardcoded colors)
- [ ] No new references to prior template lineage (see CLAUDE.md anti-patterns)
- [ ] No `master.key` or global `credentials.yml.enc` added
- [ ] All admin controller actions call `authorize`

## Screenshots / Notes

<!-- Optional. Screenshots for UI changes, migration notes, or anything a reviewer should know. -->
