---
description: Evaluate a repo, or set up a new one, for agent-written code verified by behavior, not reading: gates, mutation and fuzz recipes, risk list, review profile, rules and hooks, adding only what is missing
argument-hint: '[path] [--new]'
---

Make a repo safe to verify by behavior: every check `/implement` and
`/review-gauntlet` expect exists and runs. Add only what is missing; never
replace a working gate with a preferred one.

Raw arguments: `$ARGUMENTS`. No path means the current repo. `--new`: the
repo was just created; skip the report and apply directly.

## 1. Survey

```bash
ls go.mod Cargo.toml package.json pyproject.toml project.godot justfile Makefile 2>/dev/null
just --list 2>/dev/null
ls .claude/ .claude/rules/ .golangci.* .github/workflows/ 2>/dev/null
git log --oneline -20
```

Read the README, the CI workflow, and the justfile. Run each existing gate
once and record what it printed. A gate that is red today is a finding, not
something to add on top of.

Go, Python, TypeScript and Rust are covered below; a repo with several runs each
table. Another language: report what it has against the same items, and say
its defaults are not written yet.

## 2. Checklist

### Go

Each item: present (name the file), missing, or broken (with output).

| Item | Default when missing |
|---|---|
| `test` gate | `go test -race ./...` |
| `vet` gate | `go vet ./...` |
| `lint` gate | `golangci-lint run`, with a `.golangci.yml` enabling `errcheck`, `govet`, `staticcheck`, `unused`, `ineffassign` |
| `vuln` gate | `govulncheck ./...` |
| `mutate` recipe | gremlins on the diff from a base ref |
| `fuzz` recipe | `go test -run='^$' -fuzz='^{{name}}$' -fuzztime={{time}} {{pkg}}` |
| `apidiff` recipe | `apidiff` on exported API vs a base ref; only for a library with importers |
| `.claude/review-profile.md` | see §3 |
| `.claude/risk.md` | see §4 |
| `.claude/rules/go.md` | only for a convention this repo holds that the linters do not enforce |

Tools install through mise when the repo has `mise.toml`, else `go install
<module>@latest`: `golangci-lint`, `golang.org/x/vuln/cmd/govulncheck`,
`github.com/go-gremlins/gremlins/cmd/gremlins`,
`golang.org/x/exp/cmd/apidiff`.

gremlins is pre-1.0 and its flags move. Read `gremlins unleash --help` on
the installed version and use its diff mode, so a run mutates only changed
lines:

```just
mutate base="main":
    gremlins unleash --diff {{base}}   # confirm flag name against --help
```

Run `just mutate` once on a small diff before calling it present. A recipe
that has never run is broken.

### Python

| Item | Default when missing |
|---|---|
| `test` gate | `uv run --locked pytest` |
| `lint` gate | `ruff check` and `ruff format --check` |
| `types` gate | basedpyright or pyright in strict mode |
| `cover` gate | pytest-cov, `--cov-branch --cov-fail-under=<today's number, rounded down>`; ratchets up, never down |
| `vuln` gate | `uv run --locked pip-audit` |
| layering | `import-linter` contracts for every "X never imports Y" rule the agent instructions state in prose |
| property tests | Hypothesis. Every parser, formula, and invariant the docs state gets a `@given` test. A reference implementation in reach (an upstream library, a slow obvious version) means a differential property: same input, same answer |
| `fuzz` recipe | the Hypothesis suite under a `fuzz` profile (`settings.register_profile("fuzz", max_examples=…, deadline=None)`, selected by `HYPOTHESIS_PROFILE=fuzz`), plus schemathesis against the app's OpenAPI document when it serves HTTP |
| `mutate` recipe | mutmut on the files changed since a base ref |
| `.claude/rules/python.md` | only for a convention ruff, the type checker, and import-linter do not enforce |

Tools are dev dependencies (`uv add --dev`), never runtime: `hypothesis`,
`pytest-cov`, `pip-audit`, `import-linter`, `mutmut`, `schemathesis`.
mutmut's config and CLI changed across majors (3.x reads `[tool.mutmut]` in
`pyproject.toml`): read `mutmut --help` for the installed version, scope it
to the files changed since the base, and run it once on one file before
calling it present.

### TypeScript

| Item | Default when missing |
|---|---|
| `test` gate | vitest |
| `lint` gate | the linter the toolchain already ships (oxlint, eslint) |
| `types` gate | `tsc --noEmit` with `strict: true` |
| `cover` gate | `@vitest/coverage-v8` with thresholds at today's numbers |
| `vuln` gate | the package manager's audit (`bun audit`, `npm audit`) |
| property tests | fast-check (`@fast-check/vitest`) for pure logic: parsers, formatters, option builders, reducers |
| `fuzz` recipe | the fast-check suite with `numRuns` raised through an env var |
| `mutate` recipe | Stryker (`@stryker-mutator/core`, `@stryker-mutator/vitest-runner`), `--mutate` set to the changed files, `--incremental` |
| `.claude/rules/typescript.md` | only for a convention the linter and `tsc` do not enforce |

Stryker under a non-npm runner (bun, vite-plus) may not resolve the vitest
runner: run it once on one file before calling it present.

### Rust

| Item | Default when missing |
|---|---|
| `test` gate | `cargo nextest run --workspace` (plus `cargo test --doc`; nextest skips doctests) |
| `lint` gate | `cargo fmt --check` and `cargo clippy --workspace --all-targets -- -D warnings`, lints set in `[workspace.lints]`: `clippy::pedantic` warn; `unwrap_used`, `expect_used`, `indexing_slicing`, `cast_possible_truncation` deny in logic crates |
| `cover` gate | `cargo llvm-cov nextest --fail-under-lines <today's number, rounded down>`; ratchets up, never down |
| `vuln` gate | `cargo deny check` (advisories, licenses, bans, sources), with a `deny.toml` |
| test layout | unit tests inline at the end of the file they test (`#[cfg(test)] mod tests { }`; clippy's `items_after_test_module` under `-D warnings` keeps nothing after it), integration tests in `tests/`. `tdd-guard` and the gauntlet freeze the inline module by region (`~/.claude/hooks/test-region`) |
| property tests | proptest. Every rule, parser and invariant the docs state gets a `proptest!`; a slow obvious version in reach means a differential property |
| `fuzz` recipe | `cargo +nightly fuzz run {{target}} -- -max_total_time={{secs}}`, targets in `fuzz/`; `bolero` instead when fuzz targets should also run as plain tests on stable |
| `mutate` recipe | cargo-mutants on the diff from a base ref, through nextest, scoped with `--package` to logic crates (below) |
| `verify` recipe | optional: `cargo kani` proof harnesses for invariants a bounded check can cover; `cargo +nightly miri test` when the crate has `unsafe` |
| `.claude/rules/rust.md` | only for a convention clippy and the crate layout do not enforce |

Tools install through mise when the repo has `mise.toml`, else `cargo
binstall` (falling back to `cargo install --locked`): `cargo-nextest`,
`cargo-llvm-cov`, `cargo-deny`, `cargo-mutants`, `cargo-fuzz`; `kani-verifier`
only with a `verify` recipe.

```just
mutate base="main" pkg="core":
    git diff {{base}} > target/mutants.diff
    cargo mutants --in-diff target/mutants.diff --test-tool nextest --package {{pkg}}   # confirm flags against --help
```

Run `just mutate` once on a small diff before calling it present: a mutant is
a rebuild, so an unscoped run takes hours.

Engine projects (Bevy, gdext): split the workspace so the gates stay fast.

- A logic crate (rules, simulation, data) with no engine dependency. Fuzz,
  mutation, proptest and Kani target it; this is where behavior beans land.
- A thin engine crate for systems, rendering, input and assets. Bevy systems
  are tested headless: `App::new().add_plugins(MinimalPlugins)`, insert
  resources and entities, `app.update()`, then assert on the `World`.
- A determinism property: same seed and input stream, same state after N
  fixed steps. It catches unordered systems and wall-clock time leaking into
  the simulation.
- Compile time is the loop's cost. Apply the engine's documented fast-compile
  setup (Bevy: `opt-level = 1` for the dev profile, `3` for dependencies,
  `dynamic_linking` in dev only), never in release or CI.

## 3. Review profile

`/review-gauntlet` §5 reads `.claude/review-profile.md` verbatim. Two lines,
in the shape §5 defines: the domain and its 3-5 expensive failures, then the
categories this repo has no surface for. Derive both from the code, not the
README's ambitions.

## 4. Risk list

`.claude/risk.md` lists signals that make a hunk worth a human reading. The
gauntlet's human-eyes pass flags every match as `impact`. Start from the language
defaults, cut what this repo has no surface for, and add its own hot paths
by name:

```markdown
# Risk signals

Hunks matching any line are read by a human. Everything else is verified by
behavior only.

<Go>
- `go.mod`, `go.sum`: new dependency or version bump; `just vuln` must pass
- exported API changed (`just apidiff`)
- new import of `unsafe`, `os/exec`, `syscall`, `reflect`, `crypto/*`,
  `database/sql`, `net/http`
- new `go` statement, channel, `sync.*`, `atomic.*`
- `**/migrations/**`, `*.sql`, code that writes or deletes persisted data
- `.github/**`, `justfile`, `Makefile`, `Dockerfile`, `.golangci.yml`: the
  gates themselves
- new `//nolint`, `t.Skip`, `//go:build ignore`, `_ =` on an error
- edits to an existing `_test.go`
- skip: files headed `// Code generated ... DO NOT EDIT`; regenerate and
  diff instead

<Python>
- `pyproject.toml` `dependencies` or `uv.lock`: new runtime dependency or bump
- new import of `subprocess`, `os.system`, `pickle`, `ctypes`, or a call to `eval`/`exec`
- new `threading`, `asyncio` task, or `multiprocessing` use
- new `# type: ignore`, `# noqa`, `pytest.mark.skip`/`xfail`, bare `except`
- edits to an existing `tests/**` file or snapshot

<TypeScript>
- `package.json` `dependencies` or the lockfile
- new `any`, `as unknown as`, `// @ts-ignore`, `eslint-disable`, `.skip`/`.only`
- `dangerouslySetInnerHTML`, `eval`, `new Function`
- skip: generated API types; regenerate and diff instead

<Rust>
- `Cargo.toml` dependencies or features, `Cargo.lock` bumps, `build.rs`;
  `just vuln` must pass
- new `unsafe`, `extern`, `static mut`, `unsafe impl Send`/`Sync`,
  `std::process`, `std::mem::transmute`
- new `#[allow(...)]`, `#[ignore]`, `unwrap()`/`expect()` outside tests
- new `thread::spawn`, `Mutex`, `RwLock`, atomics, async runtime
- panics reachable across an FFI or engine callback boundary
- engine crate: system ordering (`.before`, `.after`, sets, schedules),
  wall-clock time in simulation code, entity despawn paths, save formats
- edits to an existing `tests/**` or inline `#[cfg(test)] mod tests`

<all>
- `.github/**`, `justfile`, `mise.toml`, tool configs: the gates themselves
- every path the repo's agent instructions name as a human gate
- <repo hot paths, by path>
```

Keep only the blocks for the languages the repo uses; the `<…>` headings are
not part of the file.

## 5. Hooks

`tdd-guard` is global and only acts in a worktree `/implement` marked, so
there is nothing to enable per repo. Propose a project hook in
`.claude/settings.json` only for a failure this repo has actually shown, in
its history, step 1's gate output, or an open `prevention` bean (`beans
list --tag prevention`; `/land` files those from gauntlet runs). Candidates:

- `PostToolUse` on Edit|Write running `gofmt -l` on the edited `.go` file,
  when `lint` keeps failing on formatting.
- `Stop` running `go vet ./...`, when agents finish with a broken build.
- `PostToolUse` running `ruff format`, the TS formatter, or `rustfmt
  --edition <edition>` on the edited file, when `lint` keeps failing on
  formatting.
- `Stop` running `cargo check --workspace`, when agents finish with a broken
  build.

None qualifies: say so. A hook nobody needed is latency on every tool call.

## 6. Agent instructions

`AGENTS.md` (or `CLAUDE.md`) is what every agent in the repo reads. Check it
against this workflow and propose edits, never a wholesale rewrite:

- Work runs `/implement` → `/review-gauntlet` → `/land`, landing by local
  fast-forward. Sections telling agents to open, stack, or answer PRs
  contradict that: replace them with one pointer to the commands, keeping
  the repo's PR title and body rules only for `--pr`.
- TDD is stated, with the repo's test command.
- The gate commands named match the justfile, including any added here.
- Human gates are listed by path, so `risk.md` and the gauntlet's Needs you
  can cite them.
- Layering rules stated in prose that a linter could enforce (import-linter,
  forbidigo, depguard): propose the lint and cut the prose to a pointer.
- Bean bodies carry the `/plan` task shape (`Tests:`, `Fuzz:`, a `##
  Definition of done` checklist). Prose-only definitions of done or extra
  completion gates: list the beans, and convert only on approval.

## 7. Report, apply

Without `--new`, report first and ask once which items to apply:

```
| item | state | action |
|------|-------|--------|
| test | present (justfile:3), 142/142 | none |
| mutate | missing | add recipe, install gremlins |
| risk.md | missing | write from defaults, cut db lines (no database) |
| PostToolUse gofmt | skip | lint has passed on the last 20 commits |
```

Apply the approved items, then run every gate and recipe it added and show
the output. Do not commit; the user commits.
