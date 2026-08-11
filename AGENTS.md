# AGENTS.md

## Repo Snapshot

- This repo is an archived Ruby gem that wraps the Apache Pulsar C++ client through a native extension built with Rice.
- The main Ruby entrypoint is `lib/pulsar/client.rb`; it loads `pulsar/bindings`, so most meaningful changes either touch the Ruby wrappers under `lib/pulsar/` or the extension under `ext/bindings/`.
- `rake` is the real CI entrypoint. In `Rakefile`, the default task is `[:compile, :spec]`.

## Setup And Build

- This gem links against `libpulsar`; local work needs both the runtime library and C++ headers installed before `bundle install` or `rake compile` will succeed.
- `ext/bindings/extconf.rb` links with `-lpulsar` and forces `-std=c++11`.
- The README calls out one Ruby-specific prerequisite: if Ruby was not built with `--enable-shared`, native extension loading can fail. The documented example is `CONFIGURE_OPTS="--enable-shared" rbenv install <ruby-version>`.
- `bin/setup` only runs `bundle install`; it does not install system dependencies.
- The lockfile is old on purpose: `bundler ~> 1.16`, `rake ~> 10.0`, `rspec ~> 3.0`.

## Commands

- Install gem deps: `bin/setup`
- Compile the extension: `bundle exec rake compile`
- Run all specs: `bundle exec rake spec`
- Run the CI-equivalent local flow: `bundle exec rake`
- Open a local console with the library loaded: `bin/console`
- Install the gem locally: `bundle exec rake install`
- Run one spec file directly: `bundle exec rspec spec/pulsar/producer_spec.rb`

## Testing Notes

- `spec/spec_helper.rb` requires `pulsar/client`, so even Ruby-only specs expect the native extension to be built and loadable.
- Live broker coverage is in `spec/pulsar/client_spec.rb`. Those examples skip unless both `PULSAR_BROKER_URI` and `PULSAR_CLIENT_RUBY_TEST_NAMESPACE` are set.
- CI (`.travis.yml`) starts a Pulsar broker in Docker, creates tenant `ruby-client` and namespace `ruby-client/tests`, then runs `rake` with:
  - `PULSAR_BROKER_URI=pulsar://localhost:6650`
  - `PULSAR_CLIENT_RUBY_TEST_NAMESPACE=ruby-client/tests`
- `spec/pulsar/ext_spec.rb` separately recompiles the fixture extension under `spec/pulsar/ext/` with `extconf.rb` + `make clean all`; changes to error wrapping or Rice bindings should be verified there as well.

## Codebase Conventions

- The Ruby wrappers use `prepend ...::RubySideTweaks` to smooth the generated/native API instead of replacing it outright. Preserve that pattern when adapting extension-backed classes such as `Pulsar::Client` and `Pulsar::Producer`.
- Environment-based client setup lives in `Pulsar::Client.from_environment` and `Pulsar::ClientConfiguration.from_environment`. If behavior depends on env vars or Pulsar `client.conf`, verify it in those two files first.
- Topic/subscription integration tests generate random non-persistent topics to avoid collisions; follow that pattern instead of hard-coding shared topic names.

## Workflow Guardrails

- There is no repo-local lint, formatter, or typecheck config. Do not invent new verification steps in this repo; use compile/spec tasks and any focused spec you changed.
- README usage examples are incomplete by its own admission (`TODO.md`), so prefer `Rakefile`, specs, and the wrapper classes as the source of truth when docs and behavior diverge.
