# Ubuntu Compile Design

## Goal

Make this gem compile reasonably well on a modern Ubuntu Linux system with a packaged `libpulsar`, without changing gem versions or proving the live broker specs on Linux.

## Current Problem

The current `extconf.rb` logic is macOS/Homebrew-specific:

- it hard-codes `/opt/homebrew/opt/libpulsar`
- it checks headers only in that prefix
- it does not provide a Linux-friendly fallback path

That means the repo now builds on the patched macOS setup, but it is less likely to compile on Ubuntu where `libpulsar` headers and libraries normally live under system paths.

## Chosen Approach

Use a cross-platform `extconf.rb` cleanup.

This keeps the recent Ruby 3 / Rake compatibility fixes and the `libpulsar` API fixes, and only changes build discovery so Linux can find `libpulsar` without Homebrew-specific assumptions.

## Design

Update both extension entrypoints:

- `ext/bindings/extconf.rb`
- `spec/pulsar/ext/extconf.rb`

Both files should:

1. Honor explicit user overrides first:
   - `--with-pulsar-dir`
   - `--with-pulsar-include`
   - `--with-pulsar-lib`

2. Choose platform defaults only when overrides are absent:
   - macOS: prefer `/opt/homebrew/opt/libpulsar`
   - Linux: prefer system include/lib locations

3. Validate the chosen paths:
   - confirm `pulsar/Client.h` exists in the selected include path
   - confirm `have_library("pulsar")` succeeds with the selected library path

4. Keep the C++ standard requirement at `-std=c++17`

## Linux Assumptions

For Ubuntu compile-only support, assume:

- `libpulsar` runtime and headers are installed separately from Ruby gems
- common install locations are under `/usr/include` and `/usr/lib*`
- users can still override locations explicitly if their distro or local install differs

## README Changes

Add a short Ubuntu-oriented setup note in `README.md`:

- install `libpulsar` runtime/dev packages and `automake`
- run `bundle install`
- run `bundle exec rake compile`

Keep the existing macOS `mise` workaround note unchanged.

## Verification Plan

On the current machine:

1. Verify the refactored extconf still works with the current macOS/Homebrew setup.
2. Verify the existing successful compile flow still works:
   - `mise exec -- bundle _1.17.3_ exec rake compile`

For Linux-readiness in repo logic:

1. Confirm the new fallback logic no longer hard-codes Homebrew-only paths.
2. Confirm explicit `--with-pulsar-*` overrides still take precedence.

## Non-Goals

- Upgrading Bundler, Rake, Rice, or other gems
- Proving the full spec suite on Ubuntu
- Adding or updating CI in this pass
