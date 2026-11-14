# Testing

## Philosophy

Follow standard **Ruby on Rails** testing with **Minitest** and **YAML fixtures**. Prefer the Rails defaults over custom frameworks.

- Framework: Minitest (`rails test`)
- Data: fixtures in `test/fixtures/` (`fixtures :all` in `test_helper.rb`)
- Focus on **behavior**, not implementation details

## Minimum coverage

Every feature should be covered by at least:

| Layer | Path | Focus |
|-------|------|--------|
| **Model** | `test/models/` | Validations, associations, scopes, custom methods |
| **Controller** | `test/controllers/` | HTTP status, redirects, flash, auth, success/failure paths |
| **System** | `test/system/` | Critical end-to-end user flows in the browser |


## Fixtures

- Define shared data in `test/fixtures/*.yml`
- Reference associations by fixture label (e.g. `user: one`)
- Prefer fixtures over ad-hoc `create!` for baseline records
- Do not leave tests depending on unseeded empty tables when fixtures can provide data

## Authentication in tests

Use `sign_in_as(user)` / `sign_out` from `test/test_helpers/session_test_helper.rb` in integration and controller tests:

```ruby
sign_in_as users(:one)
get companies_url
assert_response :success
```

## Conventions

- One test file per class, mirroring app structure
- Name tests with clear intent: `test "should create company"` (or `def test_should_create_company`)
- Assert response codes, redirects, flash, and meaningful DB changes — not private method internals
- System tests inherit from `ApplicationSystemTestCase`

## Running tests

```bash
bin/rails test                  # full suite
bin/rails test test/models      # models only
bin/rails test test/controllers
bin/rails test test/system
```
