---
description: Apply rulings to gauntlet-reviewed beans, fast-forward them onto main locally, and file the accepted prevention items as beans
argument-hint: '<bean-id...> [rulings text]'
---

Land beans `/review-gauntlet` reported ready. Works from any session: the
report appended to each bean is the whole input.

Raw arguments: `$ARGUMENTS`. Ids first; any text after them is rulings, e.g.
`1 use fail fast, 3 rename to format, strike P2`.

## 1. Preconditions

Per bean, all must hold, else skip it and say why:

- The bean body has the gauntlet report (`<!-- human-eyes -->` marker) and it
  lists no open P0, integrity failure, or REDESIGN.
- `<WT>` = `<repo>/.claude/worktrees/<id>` exists on `task/<id>`, clean.
- The main checkout is on `main` and clean outside `.beans/`. Dirty
  elsewhere: stop everything; never stash the user's work. Bean edits (the
  gauntlet reports, status) stay uncommitted: each bean's landing commit
  takes its own bean files (§3).
- `<BASE>` = `git config branch.task/<id>.stackParent`, else `main`. A
  stacked bean lands only after its base: the base is in this call (land it
  first; order the call bottom-up) or already in main (`git merge-base
  --is-ancestor <BASE> main`). Otherwise skip it and name the base.

Before any ruling, record per stacked child of a bean being landed (any
branch whose `stackParent` is `task/<id>`, in this call or not):
`<FORK>` = `git merge-base task/<id> task/<child>`, where the child's own
commits start.

A PR exists for the branch (`gh pr view task/<id>`): also read its comments
for rulings.

## 2. Rulings

**Silence is approval**: a number nobody mentioned is settled, do not re-raise
it. Ask only when a ruling is ambiguous about *which* number.

Per ruled number, in `<WT>`, by one fresh `general-purpose` agent per bean:
stay inside the blast radius (a ruling on `1` authorizes that decision, not a
refactor of its file), commit with a Conventional Commits subject, never
amend. Then the coordinator re-runs the gates and the gauntlet's §8 integrity
check itself and reports what they printed. A ruling that changes an
existing test is a change to the spec: confirm with the user first, and
add it to the bean's test-change table with the ruling as its reason. New tests a
ruling needs are appended to the file's existing `mod tests`, never a
second test module.

Tick each box in the bean report (`beans update <id> --body-replace-old
--body-replace-new`, only the text between the markers) and append what
changed or why it was left alone.

## 3. Land

One commit per bean on main: the branch's commits are squashed, and the
bean edits that close it ride in the same commit. Beans land one at a time,
bottom-up.

Main's `.beans/` is the only real copy; a branch's is a stale snapshot. A
rebase conflict only under `.beans/` takes main's side and continues; any
other conflict aborts. After the rebase, drop whatever bean edits the branch
still carries, so the squash brings code only:

```bash
git -C <WT> rebase main             # main moved: re-run gates and §8 before landing
# conflict only in .beans/: git -C <WT> checkout --ours -- .beans && git -C <WT> add .beans && GIT_EDITOR=true git -C <WT> rebase --continue
git -C <WT> diff --quiet main -- .beans || { git -C <WT> checkout main -- .beans && git -C <WT> commit -m "chore(beans): keep main's beans"; }
git -C <repo> merge --squash task/<id>
```

Then, in `<repo>`, before committing:

1. File this bean's prevention items (§4).
2. Close the bean: `beans update <id> -s completed --remove-tag validate`.
   Its parent, when every child of that parent is now `completed` (`beans
   list --parent <parent> --json`), closes too; walk up the same way.
3. Stage the bean files this landing touched, nothing else under `.beans/`:
   `git -C <repo> add .beans/<id>--*.md`, plus each closed parent and each
   new prevention bean.
4. Commit once. Subject: Conventional Commits naming what the bean delivers,
   not the bean title verbatim; type from the work (`feat`/`fix` for
   `behavior`, else the bean's kind). Body: one sentence when the change is
   not self-evident, then one line per test-change row in the bean
   (`Test changed: <test>: <reason>`), since the squash drops the commits
   that carried them. Footer: `Refs: <id>` per closed bean.
5. `git -C <repo> diff --quiet task/<id> HEAD -- . ':!.beans'` must hold:
   the commit carries exactly the branch's code. Not equal: stop and report;
   never reset main yourself.

The commit fails (signing, hook): leave it staged, hand the user the commit
command, stop the run.

Before removing the branch, move each of its stacked children onto main,
in the child's own worktree, so they keep only their own commits:

```bash
git -C <child WT> rebase --onto main <FORK> task/<child>
git -C <repo> config --unset branch.task/<child>.stackParent
```

A conflict: `git rebase --abort`, leave the child on `task/<id>`'s last tip,
keep `task/<id>` instead of deleting it, and list the child under Needs you.
A child rebased onto main has a new base: its gauntlet gates no longer hold,
so re-run its gates and the gauntlet's §8 integrity check before it lands,
in this call or later.

```bash
git -C <repo> worktree remove <WT>
git -C <repo> branch -D task/<id>   # -D: squashed, so not an ancestor of main; step 5 proved it landed
git -C <repo> update-ref -d refs/tdd/<id>
```

Every `beans` call in this command runs in `<repo>`, never in `<WT>`.
Bean edits left after the last landing (skipped beans' reports, rulings
ticked on them) stay uncommitted for their own landing.

A rebase conflict or a gate failing after rebase: stop that bean, report it,
land the rest. Never push main; that stays the user's call. A PR branch: push
the ruling commits and stop; the user merges the PR.

## 4. Prevention

Every `## Prevent` item the user did not strike becomes work, filed during
§3 so it lands in the bean's commit:

- rungs 1-5 (repo-local): `beans create --json "<guard>" -t task --tag
  prevention -s todo -d -` with a body in `/plan`'s task shape. The recurrence
  condition goes in `Decisions:`, and the Definition of done holds one box:
  the original failure, reproduced, is now caught. `Tests:` is `chore` for a
  lint, rule or doc line, `behavior` for a hook or test.
- `global`: do not file it in this repo. List it under Needs you with the
  dotfiles file it belongs in.

Skip an item an open `prevention` bean already covers.

## 5. Output

```
Landed: <id> (<n> commits squashed into <short sha>)
Restacked onto main: <child ids>
Rulings applied: <id> 1, 3; left: 2 (reason)
Prevention beans: <new ids, one line each>

Needs you:
- <id>: <skipped and why, conflict, global prevention item>
```
