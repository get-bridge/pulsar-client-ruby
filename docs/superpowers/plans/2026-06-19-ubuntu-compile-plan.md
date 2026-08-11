# Ubuntu Compile Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the native extension build discovery work on modern Ubuntu as well as the currently fixed macOS setup.

**Architecture:** Keep the current Ruby 3, Bundler, and binding fixes intact. Only refactor the extension configuration entrypoints so they discover `libpulsar` through explicit overrides first, then platform-appropriate defaults instead of a Homebrew-only path.

**Tech Stack:** Ruby 3.1.7, Bundler 1.17.3 lockfile, Rake, rake-compiler, Rice, native C++ extension, libpulsar.

---

### Task 1: Refactor Main Extension Discovery

**Files:**
- Modify: `ext/bindings/extconf.rb`
- Test: `ext/bindings/extconf.rb` via `ruby ext/bindings/extconf.rb --with-pulsar-*` or `bundle exec rake compile`

- [ ] **Step 1: Replace the Homebrew-only path logic with override-first discovery**

Use this structure in `ext/bindings/extconf.rb`:

```ruby
require 'mkmf-rice'
require 'rbconfig'

DEFAULT_PULSAR_DIRS = if RbConfig::CONFIG['host_os'] =~ /darwin/
  ['/opt/homebrew/opt/libpulsar']
else
  ['/usr', '/usr/local']
end.freeze

def existing_dir(paths)
  paths.find { |path| path && File.directory?(path) }
end

pulsar_dir = with_config('pulsar-dir') || existing_dir(DEFAULT_PULSAR_DIRS)
include_dir, lib_dir = dir_config(
  'pulsar',
  pulsar_dir && File.join(pulsar_dir, 'include'),
  pulsar_dir && File.join(pulsar_dir, 'lib')
)

client_header = File.join(include_dir.to_s, 'pulsar', 'Client.h')

abort 'libpulsar headers not found' unless File.exist?(client_header)
abort 'libpulsar library not found' unless have_library('pulsar')

$CXXFLAGS += ' -std=c++17 '

create_makefile('pulsar/bindings')
```

- [ ] **Step 2: Confirm explicit overrides still win over defaults**

Run:

```bash
ruby -e 'require "mkmf"; p with_config("pulsar-dir")'
```

Expected: `nil` without args, and a string value if extconf is run with `--with-pulsar-dir=...`.

- [ ] **Step 3: Verify macOS extconf still resolves the current Homebrew install**

Run:

```bash
mise exec -- bundle _1.17.3_ exec ruby ext/bindings/extconf.rb
```

Expected: successful header/library checks and `creating Makefile`.


### Task 2: Refactor Fixture Extension Discovery

**Files:**
- Modify: `spec/pulsar/ext/extconf.rb`
- Test: `spec/pulsar/ext/extconf.rb`

- [ ] **Step 1: Mirror the same discovery logic in the fixture extension**

Use the same code pattern as Task 1, but keep the final makefile target unchanged:

```ruby
create_makefile('bindings')
```

- [ ] **Step 2: Verify the fixture extconf still succeeds on the current machine**

Run:

```bash
mise exec -- bundle _1.17.3_ exec ruby spec/pulsar/ext/extconf.rb
```

Expected: successful header/library checks and `creating Makefile`.


### Task 3: Document Ubuntu Compile Setup

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Add a short Ubuntu note to the Development section**

Add a compact note near the existing dependency/setup section such as:

```markdown
On Ubuntu, install the Pulsar client runtime and headers plus build tools before running Bundler. For example:

```bash
sudo apt-get update
sudo apt-get install -y automake libpulsar-dev libpulsar
```

If your distro installs `libpulsar` outside standard system paths, pass the location through extconf options such as `--with-pulsar-dir=/custom/prefix`.
```

- [ ] **Step 2: Keep the macOS `mise` note intact**

Do not remove the existing macOS-specific `mise` workaround; just extend the section so both setups are documented.


### Task 4: Re-verify Current Compile Flow

**Files:**
- Modify: none
- Test: native compile flow

- [ ] **Step 1: Run the current compile flow end-to-end**

Run:

```bash
mise exec -- bundle _1.17.3_ exec rake compile
```

Expected: compile completes and produces `lib/pulsar/bindings.bundle`.

- [ ] **Step 2: Verify the built extension still loads**

Run:

```bash
mise exec -- bundle _1.17.3_ exec ruby -e 'require "pulsar/client"; puts Pulsar::Client::VERSION'
```

Expected: prints the gem version.

- [ ] **Step 3: Commit**

```bash
git add ext/bindings/extconf.rb spec/pulsar/ext/extconf.rb README.md docs/superpowers/specs/2026-06-19-ubuntu-compile-design.md docs/superpowers/plans/2026-06-19-ubuntu-compile-plan.md
git commit -m "build: make libpulsar discovery cross-platform"
```
