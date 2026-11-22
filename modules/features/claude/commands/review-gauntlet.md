---
description: Review N code-complete beans to fast-forward onto main, one worktree each, through simplify, ponytail, code-review and a cold adversarial round that all apply fixes, then report what needs human eyes and how to try the behavior
argument-hint: '<bean-id...> | --ready [--pr] [focus text]'
---

Review each code-complete bean until it is ready to land on main.
Implementation happens separately, before this command (`/implement`); it
never implements. One worktree per bean, four sequential review rounds that
apply fixes, then a human-eyes pass. The user reviews behavior, not code: the
report hands them the forks needing a ruling and a `Try it` command per
Definition-of-done box. Landing is a local fast-forward after their go;
`--pr` opens PRs instead.

Raw arguments: `$ARGUMENTS`

## 1. Resolve the beans

- Bean ids given: use them. `--ready`: the beans `/implement` finished,
  i.e. `beans list -s in-progress -t task` with a worktree at
  `.claude/worktrees/<id>`. Not `beans list --ready`: that excludes
  in-progress and returns the unimplemented todo beans.
- `--pr`: §10 opens PRs instead of landing locally.
- Any text left after the ids or flag is the user's focus. Pass it to every
  round verbatim; never rewrite it.
- Models: a skill round runs on `opus` and passes no model override, so
  each skill's own fan-out keeps the models it defines. Every other agent is
  `opus`.
- Agent type: every `Agent` call here is `general-purpose`. Its `tools: *`
  carries `Skill`, which rounds 1-3 need to invoke `simplify`,
  `ponytail-review` and `code-review`. Never `Explore` or `Plan`: no `Skill`,
  no writes.
- Two beans that touch the same test project: decide file ownership now and
  write it into both beans' prompts.
- Before the coordinator adds a commit of its own to a branch (a ruling, a
  floor raise), check the other branches in the run for the same file:
  `git diff --name-only <BASE_TIP>...task/<other>`. Shared and not stacked:
  put the commit on the branch that lands last, or note the overlap in both
  reports so `/land` rebases the second one.

## 2. Locate worktrees and diff paths

Each bean's worktree already exists at `.claude/worktrees/<id>` on branch
`task/<id>`. A branch may stack on another task branch instead of main; any
number of commits on either. Resolve `<BASE>`, the branch it is reviewed
against, per bean:

1. `git config branch.task/<id>.stackParent` (set by `/implement --on`).
2. Unset: the nearest unlanded `task/*` branch whose tip is an ancestor of
   `task/<id>`, i.e. `git merge-base --is-ancestor <cand> task/<id>`, not yet
   in main, with the most commits ahead of main. Two candidates neither of
   which contains the other: stop that bean and ask. Found: record it with
   `git config branch.task/<id>.stackParent <cand>` so `/land` agrees.
3. Neither: `main`.

Git ancestry only; no GitHub PR stack is involved. A `<BASE>` that is not in
this run is still the base: the bean is reviewed against it, and `/land`
holds it until that base lands.

```bash
git -C .claude/worktrees/<id> rev-list --count <BASE>..task/<id>   # must be >= 1
git -C .claude/worktrees/<id> status --short                       # must be empty
git merge-base --is-ancestor <BASE> task/<id>                      # must hold
```

Missing worktree, dirty tree, or nothing ahead of `<BASE>`: skip that bean
and say so. Do not create or implement.

`<BASE>` not an ancestor: the base was rewritten after this branch forked, and
reviewing it now reviews stale base commits and lands their reverts. Restack
first, `git -C <WT> rebase --onto <BASE> <OLD> task/<id>`, where `<OLD>` is the
last commit of the base's old history on this branch (`git log
--oneline <BASE>...task/<id>` shows both sides). `<OLD>` unclear or a
conflict: abort, skip the bean, and ask.

Order the run's beans bottom-up by `<BASE>`; rounds still run in parallel
across the whole stack.

Read the bean's `Tests:` line as `<KIND>` (`behavior`, `refactor`, `perf`,
`chore`; missing means `behavior`) and its `Fuzz:` line. For `behavior`,
`<RED>` = `refs/tdd/<id>`, the red commit `/implement` recorded. Missing
`<RED>` on a `behavior` bean is a P0 under §8: the tests were never shown to
fail first.

Record for each bean, all absolute:

```
<WT>   = <repo>/.claude/worktrees/<id>
<BASE_TIP> = git rev-parse <BASE>   (now, before any round; §8 restacks against it)
<RANGE> = <BASE_TIP>...task/<id>   (the recorded sha, not the branch name, so a base rewritten mid-run does not leak into this diff)
<DIFF> = $CLAUDE_JOB_DIR/tmp/review-<id>.diff   (scratchpad if CLAUDE_JOB_DIR is unset)
<OUT>  = $CLAUDE_JOB_DIR/tmp/cold-<id>.md
```

Never `/tmp/review.diff`, never a bare `review.diff`. The bundled
`code-review` skill writes one fixed filename, and `$CLAUDE_JOB_DIR` is shared
by every subagent in this job, so concurrent branches clobber each other.

Mark the stage, in `<repo>`: `beans update <id> -s in-progress --tag review
--remove-tag validate`. The beans pane shows it.

Name the gates from the justfile (`just --list` in `<WT>`), don't hardcode
them. Before any test, install every toolchain the repo's lockfiles declare,
once per worktree: e.g. `mise install && uv sync && bun install
--frozen-lockfile`. A missing tool fails tests on setup, not on behavior. Run
`just vendor` once per worktree before any `just test-godot`, or the suite
exits on an empty addon dir.

## 3. Path discipline

Subagents do NOT inherit the coordinator's working directory. They start in
the repo root, where `git diff main...HEAD` is empty, and some then fall back
to `git diff HEAD~1 HEAD`, which reviews the last merge on main.

Before every round, per branch, the coordinator:

1. Rewrites `<DIFF>`: `git -C <WT> diff <RANGE> > <DIFF>`. Fix commits change
   it every round.
2. Records `<FILES>` = `git -C <WT> diff --name-only <RANGE>` and checks it
   against what the bean says it touches. Empty or unexpected: stop that
   branch and say so. Launch nothing against an unverified diff.

Every round prompt opens with this block, filled in:

> Worktree: `<WT>`. Start EVERY Bash call with `cd <WT> &&`. The range under
> review is `<RANGE>`; its diff is already at `<DIFF>`. Use that path for any
> diff file, never `/tmp/review.diff` or a bare `review.diff`.
>
> An empty `<RANGE>` means you are in the wrong directory, not that nothing
> changed. Stop and say so. Never fall back to `HEAD~1..HEAD`.
>
> Sibling agents work in other worktrees in parallel. Never touch the main
> checkout or any other worktree. Never run `beans` or edit `.beans/`; the
> coordinator owns beans. <ownership line, if any> Bean status and
> Definition-of-done checkboxes are set by `/land`: never report them as a
> finding.
>
> Do not spawn `fork` subagents; their reports go to the top-level
> coordinator, not to you, and you would wait forever.
>
> Commit your fixes as ONE new commit on `task/<id>` with a Conventional
> Commits subject naming the change, not the round. Never amend, rebase or
> squash: earlier commits are the record the later rounds diff against. No
> changes means no commit. A fix that adds or changes behavior lands with a
> test that fails without it; run it against the unfixed code first.
>
> New tests go in the file's existing `#[cfg(test)] mod tests`, appended.
> Never a second test module in a file. An existing test changes only
> under `/implement`'s Test changes rules, never to make a fix pass: its
> own `test(<scope>): <what changed>` commit with the reason in the body,
> and a row in your reply (test, file, what changed, reason). Good reasons:
> it contradicts a Definition-of-done box or bean rule, asserts internals
> the `Interface:` does not expose, is nondeterministic, pins a value only
> the implementation produces, or follows a rename or re-sign. Loosening an
> assertion or dropping a case names the box that still covers it. No good
> reason: stop and report it as a human gate.
>
> The first lines of your reply are the output of
> `git diff --name-only <RANGE>`, before anything else.

The coordinator compares that echoed list to `<FILES>`. Mismatch VOIDS the
whole round for that branch: re-run it. A clean result from a wrong-scope
agent is worthless, not reassuring.

After each round commits, append the round's test-change rows to the
bean's `## Test changes`, then run §8's test-change check on the new
commits. An untabled change or a bad reason: back to that round's agent
once, then an integrity failure listed under Needs you.

## 4. Rounds

Rounds run in order per branch; branches run in parallel.

Before launching any round, `df -k` the volume holding the worktrees and the
one holding the Claude temp dir (`$CLAUDE_JOB_DIR`, else `$TMPDIR`). Each
needs at least 20 GiB free, or 5 GiB per worktree in the run, whichever is
larger. Short: start nothing; report each volume's free and required GiB and
the worktree count.

`/simplify` and `/code-review` each fan out about four subagents. Past the
concurrent-subagent cap (`CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS` in settings),
fan-out degrades silently and a review reports angles it never spawned. Size
round 1 and 3 batches so branches × 5 stays under that cap.

**Round 1 — simplify** (`opus`): invoke the `simplify` skill on
`<RANGE>` and apply its fixes by committing.

**Round 2 — ponytail** (`opus`): invoke the `ponytail-review` skill on
`<RANGE>`. Apply the valid findings by committing. Never cut validation, error
handling, security, accessibility, or a single smoke test. Report applied and
declined, with a reason for each decline.

**Round 3 — code-review** (`opus`): invoke the `code-review` skill with
args `high task/<id> diff file: <DIFF>`. The branch target scopes the review
even if a Bash call lands in the wrong directory, since refs are shared across
worktrees. Then apply the findings by committing. Report applied and declined.
The skill may run its review in the background: the round prompt says to wait
for that review's final report before applying anything or replying, and
never to hand back while it runs. Before launching round 4 the coordinator
records the branch tip; a commit on `task/<id>` after round 3 reported voids
any round started on the old tip: re-run it on the new one.

**Round 4 — cold adversarial** (`Agent`, `general-purpose`, `model: "opus"`,
fresh context, report-only). See §5.

**Round 4 fixes** (`Agent`, `opus`, fresh context, separate from the
reviewer). See §6.

## 5. Round 4 — the cold reviewer

Clean results from rounds 1-3 are no reason to skip or shorten this round:
it catches what reading the diff misses, like a feature that never renders or
a test whose guarantee cannot fail.

### Establish the domain profile

Once per run, before the first round 4:

```bash
ls project.godot Cargo.toml package.json pyproject.toml go.mod 2>/dev/null
sed -n 1,20p README.md 2>/dev/null
```

If `.claude/review-profile.md` exists, use it verbatim and skip detection.
Otherwise write two lines, `<PROFILE>`, and hand them to every round 4 reviewer
unchanged:

```
Domain: <what this repo is, one sentence>. The expensive failures here are
<3-5 concrete ones, named>.
Out of scope: <categories this repo has no surface for>. Do not report them.
```

A category is out of scope only when the repo has **no surface** for it — no
listener, no credential, no untrusted input, no multi-user state. Uncertain
means in scope. Never put memory safety, data loss, or input validation out of
scope; a game corrupts saves and parses mod files like anything else.

Two illustrations, not a template. Profile the repo in front of you.

Cycle-accurate emulator core: out of scope are auth, tenant isolation, CSRF,
rate limiting, secret rotation. In scope are a bus access that reads before the
clock advances, a state machine that resumes at the wrong case, a save state
captured off the frame boundary, a ROM header parsed as if it were trusted.

Dotfiles repo of shell and templates: out of scope are auth, tenant isolation,
rate limiting. In scope are a hook that fails closed and blocks every write, an
unquoted path that word-splits under `chezmoi apply`, a template rendering a
secret into a world-readable file.

### Reviewer prompt

After the §3 block:

> `<PROFILE>`
>
> User focus: `<FOCUS>`. Bean: `<id>`; read it for the Definition of done.
>
> You are the cold pass. Simplify, ponytail and code-review already ran. Do
> not invoke `code-review` or `simplify`; review directly. Read-only: never
> leave the tree modified.
>
> 1. Run every gate yourself (`just vendor` first if `just test-godot` is one)
>    and report the numbers you observed. A gate you could not run is
>    UNVERIFIED, never passing.
> 2. Verify each Definition-of-done box against the code and by execution,
>    not the commit message. Mark each CONFIRMED or REFUTED with evidence,
>    and give each a `Try it`: the one command the user runs to see that
>    behavior themselves, and what it prints when it holds. A box about
>    something a user sees (a page, a screen, a rendered view) is verified by
>    rendering it: the repo's smoke recipe, else a headless browser that loads
>    the page and fails on a console error. A curl of the API behind it
>    proves nothing about the page.
> 3. Mutation testing is the core. A `mutate` recipe in the justfile: run it
>    scoped to `<RANGE>` and report its `killed/total`. None: mutate the
>    changed logic by hand (flip conditions, off-by-one bounds, drop calls,
>    swap constants) in a scratch copy, never in the worktree: `git -C <WT>
>    worktree add --detach $CLAUDE_JOB_DIR/tmp/mut-<id> task/<id>`, removed
>    when done. Install every toolchain the repo's lockfiles declare in it
>    before any test (e.g. `mise install && uv sync && bun install
>    --frozen-lockfile`). Confirm each mutant applied (`git diff --stat` non-empty)
>    before running the relevant tests, and reset the copy after each. Either way name and explain every survivor. `<KIND>` other
>    than `behavior`: survivors are pre-existing coverage gaps, P2 not P1.
>    Bean says `Fuzz: yes`: a `Fuzz*` target with seed corpus must exist for
>    the named input; run it (`fuzz` recipe, else `go test -fuzz=<name>
>    -fuzztime=30s`). Missing target or a crash is P0. `Fuzz: no`: skip.
>    `<KIND>` is `perf`: run the bean's benchmark on `<BASE>` and on `task/<id>`
>    and report both; no gain is P1.
> 4. Findings: `file:line`, severity P0 blocks merge / P1 fix before release /
>    P2 note, the concrete failure scenario, and for each fix an ACCEPTANCE
>    MUTATION: the specific mutation that must turn a test RED once fixed.
> 5. REJECTED: every candidate you considered and dropped, with the reason,
>    so a later round does not re-raise it.
>
> Write your full report to `<OUT>` in ONE Write call, whose last line is
> exactly `--- END OF REPORT ---`. Then reply to me with three lines and
> nothing else: your verdict, how many findings you filed, and that path. Do
> not paste the report into your reply.

The three-line reply is the liveness signal. A reviewer that dies before
writing leaves no file, and only the reply distinguishes that from one with
nothing to report.

### Merge rules

Read `<OUT>`. Check it ends with the sentinel and carries the finding count
the reply claimed; missing, unterminated or short means re-run the reviewer.
Never act on a three-line reply alone. Then, in order:

1. **Drop anything with no `file:line`.** An ungrounded finding did not follow
   instructions.
2. **Drop findings that presuppose surface this repo does not have** — the
   `Out of scope` line of `<PROFILE>`. A finding naming a real code path stays
   even if its category is listed. One line each under Deferred, so a wrong
   profile is visible rather than silent.
3. **Safety outranks brevity.** A cut on validation, error handling,
   security, or accessibility lines is dropped. Note it under Deferred.
4. Flat-number the survivors `[1]`, `[2]`… P0 first, then P1, then P2.
5. Every P0 and P1 goes to §6. P2 goes to the report.

## 6. Round 4 fix agents

Before launching, record `<PRE>` = `git -C <WT> rev-parse task/<id>`, the
commit the reviewer saw. §7 diffs against it.

One fresh agent per branch, never the reviewer. After the §3 block, hand it
the numbered P0/P1 list and the reviewer's REJECTED list, and:

> For each finding: apply the ACCEPTANCE MUTATION to the fixed code and
> confirm the named test goes RED, revert it, confirm GREEN, and confirm
> `git status --short` is clean. A fix whose mutation stays green is not done.
> Then run every gate: any other test red means the fix is not done, even
> one in a file you never touched. Commit the fixes as one commit.
>
> Do not relitigate the REJECTED list. Do not fix P2s or anything not listed.
> Do not reword a DoD box to make it pass; if its wording must change, stop
> and report it as a human-gate question.
>
> Reply with, per finding: fixed or not, the mutation, and red seen yes/no.

A finding without `red seen: yes` is not fixed. Re-run it once; then carry it
to the report as open.

## 7. Round 5 — only when the rules say so

Per branch, after its round 4 fixes. First match wins; no judgment call:

1. Any **P0** was fixed → **round 5 required.** P0 fixes touch the most
   fragile code, which is where a fix-induced bug lives.
2. `git -C <WT> diff --name-only <PRE> task/<id>` lists a file no fixed
   finding named → **round 5 required.** Scope creep during fixing is its own
   bug source.
3. Otherwise → **not required.** Say so in the output with the rule number.

Round 5 re-runs round 4 only: a fresh cold reviewer (§5, same `<PROFILE>`),
then fresh fix agents (§6). Add to the reviewer prompt:

> This is a re-check. The fix delta is `git diff <PRE> task/<id>`. Confirm
> each fixed finding is closed by running its ACCEPTANCE MUTATION, then attack
> the delta for regressions. Findings outside the delta only if they are P0.
> Carried forward, do not re-raise: <REJECTED list>.

Also re-run round 3 `code-review` first, before the cold reviewer, when rule 2
fired. Never re-run simplify or ponytail: fixes add guards and error handling,
ponytail is built to flag added code as cuttable, and re-running it oscillates
between deleting and re-adding the same guard.

Cap is one extra round. A P0 that survives round 5 means the change needs
redesign, not a third pass of patches: do not land that branch, list it
under Needs you with the surviving findings.

## 8. Verify

Wait for every branch to finish round 4 fixes and any round 5.

**Restack first**, bottom-up. A base that gained fix commits leaves its
children on the old tip. Per stacked branch whose `git rev-parse <BASE>` no
longer equals `<BASE_TIP>`, in its own worktree:

```bash
git -C <WT> rebase --onto <BASE> <BASE_TIP> task/<id>   # moves only this branch's own commits
```

Then set `<BASE_TIP>` to the new base tip before restacking that branch's own
children. Per-branch `--onto`, not `rebase --update-refs`: every branch in the
stack is checked out in a worktree. A conflict: `git rebase --abort`, list the
branch under Needs you, and skip its children's verify. `<RED>` keeps
pointing at the pre-rebase red commit; the test-change diff below compares
file contents, so it still holds.

Then, per branch, the coordinator itself:

1. Re-runs every gate on the final commit. Never reuse a number an agent
   reported. A gate that fails blocks that branch; say so.
2. Checks test integrity by `<KIND>`. Test files are per language (`*_test.go`;
   `test_*.py`, `*_test.py`; `*.test.*`, `*.spec.*`; `tests/**/*.rs`, `**/tests.rs`).
   Any other `.rs` file counts by its inline test module only: compare
   `git show <rev>:<file> | ~/.claude/hooks/test-region -` across revs, never
   the whole file, since the code above the module is meant to change.
   - every kind: each removed or changed test line between `<RED>`
     (other kinds: `<BASE_TIP>`) and `task/<id>` belongs to a row in the
     bean's `## Test changes`, and the row gives a reason from
     `/implement`'s Test changes list. Lines that only add tests need no
     row. The suite passes on `task/<id>`.
   - `behavior`: the red tests no row changed fail on `<RED>`.
   - other kinds: the suite passes on `<BASE>`.
   - other kinds whose range changes test files because the bean moves the
     test runner or framework: a port, not a P0, when every test name on
     `<BASE>` still exists on `task/<id>` and the suite passes on both. List
     it under Needs you as a `decision` with any test name that did not
     survive, and continue to §9.

   An untabled change or a bad reason is a P0 the fix agents may not
   resolve by editing tests: the spec changed silently. List it under
   Needs you.

## 9. Human-eyes pass

Rounds 1-5 find defects. This pass finds the lines where **the code is
internally consistent either way** and only the user can say which is right,
so review time goes to the forks, not the whole diff. Skip branches that
failed §8 or ended in REDESIGN; nothing here is worth a human's time on a
change that still has defects.

Sources for `decision` flags: the implementation ran in another session, so
find its transcripts by worktree. A session started in `<WT>` matches by
`cwd`; a subagent matches when its first user message names `<WT>`,
`task/<id>`, or a prompt file named for the bean (`-<id>.`), so reviewers of
other beans in the same session drop out. Prompt files the coordinator writes
carry the bean id in their name:

```bash
grep -l "\"cwd\":\"<WT>\"" ~/.claude/projects/*/*.jsonl
for f in ~/.claude/projects/*/*/subagents/*.jsonl; do
  jq -rs 'map(select(.type == "user"))[0].message.content
    | if type == "string" then . else map(.text? // "") | join(" ") end' "$f" 2>/dev/null \
    | grep -qF -e "<WT>" -e "task/<id>" -e "-<id>." && echo "$f"
done
```

Plus the bean, the commit message, and every round's report. No transcript
found: run on the diff alone and mark the list diff-only.

One `Agent` per branch (`general-purpose`, `model: "opus"`, fresh context,
read-only), all branches in one message; none fans out. One per branch, not
one per class: the classes land on overlapping hunks, so parallel charters
only produce duplicates. After the §3 block (minus the commit line):

> Read the diff, the bean `<id>`, the round reports `<OUT>` and the earlier
> rounds' applied/declined lists, and these transcripts: `<TRANSCRIPTS>`.
> Filter each with `jq -c 'select(.type == "assistant" or .type == "user")'`
> first; `attachment` lines are most of the bytes and none of the reasoning.
> User focus: `<FOCUS>`.
>
> You are not looking for bugs. Four classes:
>
> - `decision` — a defensible approach chosen over another defensible one, a
>   spec gap filled without asking, a deviation from the bean, a `ponytail:`
>   corner cut, a reviewer finding a round declined, or a row of the bean's
>   `## Test changes` (one flag each, with its reason). **Name the rejected
>   alternative.** Without it there is no decision to rule on.
> - `impact` — saves, credentials, money, destructive operations, migrations,
>   anything with a rollback story. Flagged because being wrong is expensive.
>   `.claude/risk.md` exists: every hunk matching a signal there is `impact`.
> - `unverified` — a non-trivial branch, parser, or loop with no test, a
>   mutation survivor, or a check that was skipped, stubbed, or could not run.
> - `taste` — naming, API shape, file boundaries, whether an abstraction earns
>   its place. No correct answer; only the user's preference.
>
> Do not re-raise a fixed finding or one in a REJECTED list.
>
> Rank by one question: *would a different answer change the code?*
> `decision > impact > unverified > taste`. Keep the main list to what gets
> read in one pass; everything else goes to one `Also touched` line.
>
> Every flag needs a repo-relative `file:line` and enough to rule on without
> opening the file.
>
> Then, separately, prevention. From the transcripts and round reports, find
> what went wrong during implementation or review that **can happen again**:
> a P0/P1 a mechanical check would have caught, an integrity failure, a gate
> an agent broke and fixed, a command it retried after a wrong guess, a
> convention it missed. A one-off slip with no repeatable condition is not one;
> drop it. For each, name the condition that makes it recur and the cheapest
> guard that stops it, first rung that holds:
>
> 1. lint or compiler rule (`.golangci.yml`, `clippy.toml`)
> 2. test
> 3. hook in the repo's `.claude/settings.json`
> 4. path-scoped `.claude/rules/*.md`, loaded only when a matching file is read
> 5. `AGENTS.md` or `CLAUDE.md` line, paid in context every session
> 6. `global`: the failure is in `/implement` or this command, or applies to
>    every repo; the fix goes in the dotfiles
>
> Check the existing rules, hooks, lint config and open `prevention` beans
> (`beans list --tag prevention`) first; covered already means drop it.
>
> Return only the two markdown sections below.

Same file-list echo and void rule as every round.

## 10. Report, ping

Append one report per branch to its bean (`beans update <id> --body-append
-`, run in `<repo>`, never in `<WT>`), so it outlives the worktree. With `--pr` it is the PR body instead.
Then `beans update <id> --remove-tag review --tag validate`: reviewed,
waiting on the user's try-it and `/land`. It
opens with the §9 section, then `Try it`, then the gauntlet's own notes:
human-gate questions, DoD boxes whose wording had to change, unfixed
findings, P2s, mutation survivors.

```markdown
<!-- human-eyes -->
## Needs human eyes

Nothing here is a bug. Each one is a fork where the code works either way.

- [ ] **1. decision** · `src/net/retry.rs:120`
  Chose retry with backoff, 3 attempts, over fail fast and let the caller retry.
  The caller already holds a timeout, so retrying here stays bounded. ~4 lines to switch.
- [ ] **2. taste** · `src/util/fmt.rs:8`
  Named it `render` to match the trait; `format` reads better but shadows std.

Also touched: `src/lib.rs` (re-export), `src/util/fmt.rs` (formatting only)

Reply with the numbers you want changed. Unmentioned numbers are accepted.
<!-- /human-eyes -->

<!-- prevent -->
## Prevent

- [ ] **P1. lint** · recurs whenever a handler returns an error unchecked
  Agent dropped the `Close` error in `store/file.go:40`; round 3 caught it.
  Enable `errcheck` in `.golangci.yml`.

Strike the numbers you reject. The rest become `prevention` beans on land.
<!-- /prevent -->

## Try it

Run from `<WT>`. Each line is one Definition-of-done box.

- [ ] Empty body is rejected: `go run ./cmd/api & curl -s -XPOST localhost:8080/x -d ''` → `422`

## Gauntlet
<table from §11 for this branch, then the notes above>
```

Nothing qualifies: keep the section with `Nothing needs a ruling.` (and
`Nothing to prevent.`) so the report records the pass ran. Diff-only: say so under the heading.

With `--pr` only, open all PRs together:

```bash
git -C <WT> push -u origin task/<id>
gh pr create --head task/<id> --base <BASE> --title "<first commit subject>" \
  --body-file $CLAUDE_JOB_DIR/tmp/pr-<id>.md
```

After the last report is written, ping the user once (`PushNotification`).

## 11. Output

```
| bean | base | sha | simplify | ponytail | code-review | cold | round 5 | mutation | integrity | gates | eyes |
|------|------|-----|----------|----------|-------------|------|---------|----------|-----------|-------|------|
| <id> | main | <short> | 3 applied | 2 applied, 1 declined | 1 applied | 1 P0, 2 P1 fixed | rule 1: clean | 18/21 | 2 test changes tabled | test 142/142, lint ok | 2 decision, 1 taste, 1 prevent |

Ready to land (try it, then `/land <id> [rulings]`):
- <id>: <worktree path>, report in bean

Needs you:
- <id>: <human-gate question, changed DoD box, integrity failure, or REDESIGN, one line each>

Deferred:
- <dropped by merge rules 2-3, one line each>
```

A voided round shows as `void, re-run` with the re-run's result. A gate the
coordinator could not run shows `UNVERIFIED`, never a number.

## 12. Rulings and landing

`/land` applies rulings and lands, from this session or a later one; the
report in the bean is all it needs. Rulings replied here before then: run
`/land <id> <rulings>` with them. Never land on silence.
