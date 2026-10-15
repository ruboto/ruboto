# CLAUDE.md

## Project Overview

Ruboto 2 is a platform for developing Android apps using Ruby (via JRuby). It provides CLI tools for generating, building, and managing Android projects written in Ruby instead of Java. Version 2.0.0.dev, MIT licensed.

## Key Commands

```bash
# Install dependencies
bundle install

# Build gem
rake gem

# Install gem locally
rake install

# Run tests
rake test

# Run specific test
rake test TEST=test/some_test.rb

# Lint
bundle exec rubocop
```

## Project Structure

- `bin/ruboto` — Main CLI entry point
- `lib/ruboto/commands/base.rb` — CLI command definitions
- `lib/ruboto/util/` — Core utilities (setup, update, build, verify)
- `lib/ruboto/sdk_versions.rb` — Android SDK version mappings
- `assets/` — Templates for generated Android apps (Java, Ruby, resources)
- `test/` — Minitest integration tests
- `test/activity/` — Activity-specific tests (45 files)
- `rakelib/` — Additional rake tasks (API generation, stdlib deps)
- `examples/` — Example app archives

## Code Conventions

- **Ruby version**: 2.6+ target
- **Indentation**: 4 spaces
- **Style**: RuboCop enforced (see `.rubocop.yml` and `.rubocop_todo.yml`)
- **Naming**: snake_case for methods/files, CamelCase for classes
- **Android naming**: `*Activity`, `*Service`, `*BroadcastReceiver` suffixes
- **Modules**: `Ruboto::Util::Build`, `Ruboto::Util::Update`, `Ruboto::Util::Setup`, `Ruboto::Util::Verify`, `Ruboto::Commands::Base`

## Dependencies

- **Runtime**: `main` (~6.0), `rake`, `rexml`, `rubyzip`
- **Dev/Test**: `minitest`, `rubocop` + extensions

## Testing

- Framework: Minitest
- Test helper: `test/test_helper.rb` (sets up temp dirs, bundles deps)
- Matrix testing across Android API levels (19, 21, 22, 23)
- Tests split into parts for CI parallelism

## CI

- Travis CI with Android SDK
- JDK 8, multiple Android API levels
- Multi-part test matrix (TEST_PART=1of6 etc.)
