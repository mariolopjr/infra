---
description: Implement planned beans test-first, one worktree each, red tests from the Definition of done before any code, then green, leaving each branch ready for /review-gauntlet
argument-hint: '<bean-id...> [--on <base-id>] | --ready [parent-id]'
---

Implement each bean test-first in its own worktree. Never reviews, never
lands: `/review-gauntlet` does both.

Raw arguments: `$ARGUMENTS`

## 1. Resolve the beans

- Bean ids given: use them. `--ready`: `beans list --ready -t task` and take
  those, the current wave. `--ready <parent-id>`: only that epic's tasks
  (`--parent <id>`); a milestone means the tasks of each of its epics.
- Beans run in parallel, each through §3-§6 independently; one bean's red
  check never waits on another's green.
- Per bean read `Model:`, `Files:`, `Interface:`, `Done when:`, `Tests:`
  (`<KIND>`, missing means `behavior`), `Fuzz:` and the `Definition of done`
  boxes. A `behavior` bean with no boxes: skip it and say so; there is nothing
  to write red tests from.
- Two beans whose `Files:` overlap: run them one after the other, not in
  parallel.
- `--on <base-id>`: stack the given beans on `task/<base-id>` instead of
  main, so a bean can start before the one it needs has landed. The base
  branch must exist and its worktree be clean. Ids only, not with `--ready`:
  `--ready` never returns a bean whose blocker is still open.
- `<BASE>` = `task/<base-id>` with `--on`, else `main`.

## 2. Worktree

```bash
git worktree add .claude/worktrees/<id> -b task/<id> <BASE>
git config branch.task/<id>.stackParent task/<base-id>   # --on only; /review-gauntlet and /land read it
beans update <id> -s in-progress
```

Record, absolute: `<WT>` = `<repo>/.claude/worktrees/<id>`.

A Rust source file with inline tests counts as a test file by its test
module only: the `#[cfg(test)] mod tests { }` region
`~/.claude/hooks/test-region <file>` prints, which clippy's
`items_after_test_module` keeps at the end of the file. Below, "test file"
includes such a file, and comparing it means comparing `test-region`
output, not the file.

## Test changes

Tests are the spec, but a spec can be wrong. After red, an existing test
(red's own or older) may change only with a stated reason, never to make
code pass. Good reasons, each naming the box, rule or member involved:

- it contradicts a Definition-of-done box or a bean rule
- it asserts internals the `Interface:` does not expose
- it is nondeterministic (time, order, randomness)
- `regen`: a pin whose value only the implementation produces
- it adapts a call site to a signature the bean renames or re-signs

Not reasons: the code is easier another way, the assertion is hard to meet.
A change that loosens an assertion or drops a case names the box that still
covers it. Each change goes in its own `test(<scope>): <what changed>`
commit, before the code that relies on it, with the reason in the body, and
in the agent's reply as a row: test, file, what changed, reason. The
coordinator appends every row, red's and later ones, to the bean under
`## Test changes`, which `/review-gauntlet` raises as `decision` flags and
`/land` carries into the commit.

Before any test, install every toolchain the repo's lockfiles declare, in
`<WT>`: e.g. `mise install && uv sync && bun install --frozen-lockfile`. A
fresh worktree has no venv or `node_modules`, and a test that shells out to a
missing tool fails on setup, not on behavior.

Gates come from the justfile (`just --list` in `<WT>`). No justfile: say so
and use the language default (`go vet ./... && go test -race ./...`).

Every agent is `general-purpose`, whose `tools: *` carries `Skill`. Every
agent prompt opens with:

> Worktree: `<WT>`. Start EVERY Bash call with `cd <WT> &&`. Never touch the
> main checkout or another worktree. Do not spawn `fork` subagents. Commit
> with a Conventional Commits subject; never amend or rebase. Never run
> `beans` or edit `.beans/`: the worktree's copy is stale, the coordinator
> owns beans.

The coordinator runs every `beans` call in `<repo>`, never in `<WT>`.

## 3. `behavior`: red

One fresh agent per bean, `opus` at the bean's effort. It gets the bean body,
not the plan or other beans:

> Write tests from the Definition of done, one or more per box, each named
> for the behavior it pins. Then list every rule the bean body states
> outside the boxes (`Decisions:`, `Interface:` docs, prose like "rests at
> night", "a fed predator ignores prey") and give each one a test too, under
> the box it serves. A rule with no red test now gets its test in green,
> never seen failing. Test through the `Interface:` signatures, the way a
> caller would, not through internals. Read the code around `Files:` to know
> how to call it.
>
> Write no implementation. Where a signature does not exist yet, add it as a
> stub so the tests compile and fail on an assertion: return the do-nothing
> value (empty system body, `Default::default()`, the input unchanged, `0`,
> `None`, empty list). A panicking stub (Go `panic("unimplemented")`, Rust
> `todo!()`, Python `raise NotImplementedError`, TS `throw new
> Error("unimplemented")`) only where the signature has no such value; say
> which. Nothing else outside test files and inline test modules.
>
> Rust: unit tests go in the one `#[cfg(test)] mod tests { }` at the end of
> the file they test: add to it when it exists, create it when it does not,
> never a second test module in the file. Integration tests go in `tests/`.
>
> Existing tests the bean forces to change are changed here, in the red
> commit, never later. Find them: run the suite against your stubs, grep
> `Files:` callers, and read every box and `Decisions:` line that changes or
> removes behavior. Allowed, each tied to the box, rule or removed member
> that forces it:
>
> - changed: an assertion whose expected value the bean changes. It must
>   fail against the current code, like a new test.
> - adapted: a call site, fixture or type for a member the bean renames,
>   removes or re-signs. Assertions stay as they are; it compiles against
>   your stubs.
> - deleted: a test of code the bean deletes, and only that.
> - regen: a pin whose new value only the implementation can produce
>   (content hash, snapshot, reference file). Leave the old value; green
>   regenerates exactly these lines.
>
> Commit them as their own commit, `test(<scope>): change tests for <bean>`,
> before the new tests. A change no box, rule or removed member forces is
> a human gate, stop and report it, unless the repo's rules (CLAUDE.md,
> AGENTS.md) allow editing existing tests: then make it, tabled with the
> reason the repo allows it.
>
> A test that bans a token repo-wide (grep finds no X) exempts `.beans/` and
> its shared test-name prefix (`tests/test_no_*`), not only its own file, so a
> later test that must name the token does not trip it.
>
> Commit as `test(<scope>): <behavior>`. Reply with each box and the test
> names that cover it, then each body rule outside the boxes and its test,
> and quote one failing assertion message per test. Then a table of every
> existing test touched: test, `changed|adapted|deleted|regen`, the box,
> rule or member that forces it, and the file of each `regen` row.

The coordinator then checks, itself:

1. The build and the repo's static gates pass on the red commit: Go `go vet
   ./...`; Python `ruff check` and the type checker; TS `tsc --noEmit` and the
   linter. A test that fails to compile proves nothing.
2. Every new test fails on an assertion, not a setup error, and not a stub
   panic unless the agent named that stub as having no do-nothing value. A
   panic proves the stub ran, not that the assertions can fail. A new test
   that passes cannot fail: the behavior already exists or the test is
   empty. Stop that bean and ask.
3. Every box maps to at least one test, and every rule the bean body states
   outside the boxes has one too.
4. Outside test files and inline test modules the commit holds only stubs.
5. Every removed or changed line in test files and each `.rs` file's
   `test-region` belongs to a test in the agent's table, and each row names a
   box, rule or removed member that forces it; no second test module in a
   Rust file. `changed` rows fail now, `deleted` rows test only code the bean
   deletes. An untabled change, or a row the bean does not force: stop the
   bean and ask, never routed around by a re-run.

Any check fails: one fresh red re-run with the failure named, then stop the
bean and report. On pass, append the agent's table to the bean under
`## Test changes`, and:

```bash
git -C <WT> update-ref refs/tdd/<id> HEAD
```

`<SPEC>` = the test files the red commits changed, `git -C <WT> diff
--name-only <BASE> refs/tdd/<id>` filtered to test files and every `.rs`
file for which `test-region` prints a region.

## 4. `behavior`: green

One fresh agent, never the red one, `opus` at the bean's effort:

> Make the red tests pass: `<SPEC>`. Replace every stub. Regenerate the
> `regen` pins from the implementation. A test you believe is wrong: change
> it only under the Test changes rules below, in its own commit, and table
> it. A change you cannot give a good reason for is a human gate: stop and
> report it with the box it contradicts.
>
> <the Test changes section, verbatim>
>
> You may add tests for branches the boxes do not cover: appended to the
> file's existing `mod tests`, never a second test module in a Rust file.
> Each test you add was never seen red: break the code it pins (a named
> mutation), watch it fail, restore the code, and name the test, its
> mutation and why the red phase missed it in your reply, not the commit
> body; the coordinator writes them to the bean.
>
> `Fuzz: yes`: add a `Fuzz*` target for the named input with seed corpus
> entries in a new test file, and run it for 30s. `Fuzz: no`: none.
>
> Run every gate and report the numbers. Commit as `feat|fix(<scope>): ...`.
> Reply with the test-change table, or `no test changes`.

## 5. Other kinds: `refactor`, `perf`, `chore`

No red phase. Before the agent starts, the coordinator runs the suite on
`<BASE>` in `<WT>` and records the result; a red suite on `<BASE>`: stop and
say so.

Then one fresh agent:

> Implement the bean. The existing suite is the spec and must pass. A
> refactor keeps behavior, so a test changes only to follow a rename,
> removal or re-sign the bean makes, or for a reason under the Test changes
> rules below; each in its own commit and tabled. Reply with the table, or
> `no test changes`.
>
> <the Test changes section, verbatim>
>
> `perf`: run `Done when`'s benchmark before your
> first change and after your last, and report both.
>
> A bean that adds a rule or convention (a doc line, lint, rule file): before
> writing it, grep the code for places that already break it. Fix the ones
> inside `Files:`; list the rest in your reply with `file:line`, so they go
> to a follow-up bean instead of landing beside a rule they contradict.

## 6. Verify and report

Per bean, the coordinator itself:

1. Re-runs every gate. Never reuse an agent's numbers.
2. Test changes: every removed or changed line in a test file (for `.rs`,
   its `test-region` output) between `refs/tdd/<id>` (other kinds: `<BASE>`)
   and `HEAD` belongs to a row in the agent's table, and each row gives a
   reason from the Test changes list. Untabled change or a bad reason: back
   to the agent once, then stop the bean and list it under Needs you. Append
   the rows to the bean under `## Test changes`. `behavior`: the `<SPEC>`
   tests pass.
3. `behavior`: every test added after the red commit is named in the green
   agent's reply, with its mutation; append them to the bean. One that is not:
   back to the green agent once.
4. `behavior` with a `mutate` recipe: run it on the diff from `<BASE>` for
   each package the bean changed, and report `caught/total`. Each missed
   mutant goes back to the green agent once, to kill with a test (appended,
   seen red under that mutant) or to name as equivalent with the reason.
   What survives that goes in the report; review should not be the first to
   find it.
5. `git -C <WT> status --short` is empty.

The bean stays `in-progress`. Only `/land` sets `completed`, after the
user's rulings and any `Gate: human`.

```
| bean | kind | red | test changes | green | gates | mutation | spec |
|------|------|-----|--------------|-------|-------|----------|--------|
| <id> | behavior | 6 tests, 6 failing | red: 2 changed, 5 adapted, 1 regen; green: 1 changed | 6/6 pass, 2 added | test 142/142, lint ok | 40/42, 2 equivalent | 1 change tabled |

Next: /review-gauntlet <ids that passed>

Needs you:
- <id>: <test change without a good reason, test that could not fail, red suite on base>
```

The test-change table goes to `/review-gauntlet` as an item for human eyes,
not a stop.
