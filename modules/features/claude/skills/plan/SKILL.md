---
name: plan
description: Break a beans milestone into epics and ordered tasks, as beans, ready to work through.
argument-hint: <milestone id>
disable-model-invocation: true
allowed-tools: Read, Agent, Bash(git:*), Bash(ls:*), Bash(rg:*), Bash(fd:*), Bash(beans:*), Bash(jq:*)
---

Milestone: `$ARGUMENTS`

Resolve the milestone first: `beans show --json <id>`, else pick from
`beans list --json -t milestone`. Its body is the spec. No milestone, or
no beans in the repo: stop and point to `/brainstorm`; beans are the only
record, so there is nothing to plan into.

Read the spec, then the code it names; when that code spans independent
areas, give each its own subagent and check the evidence each reports
before relying on it. Decide file structure first: what
is created, what is modified, one responsibility per file, following the
repo's existing layout. Epic and task boundaries follow from that.

An epic is a slice of the milestone that leaves the codebase working and
could be reviewed on its own: a subsystem, a layer, a migration step. One
epic is the right answer when the spec is a single subsystem; do not split
for ceremony. A task is the smallest unit inside an epic with its own
check that a reviewer could reject on its own. Fold setup, config, and
docs into the task that needs them. Order tasks so each leaves the
codebase working.

The executor is a capable engineer with the milestone open, running one
task start to finish without check-ins. Do not write its code; write what
it cannot infer. Each task body carries:

```markdown
Model: opus <low|medium|high|xhigh>
Files: <created or modified>
Interface: <produced, and consumed from earlier tasks, as signatures>
Done when: <the check that proves it, and what it shows>
Tests: <behavior | refactor | perf | chore>
Fuzz: <yes: the input fuzzed | no: one-line reason>
Decisions: <spec gaps resolved here; omit when none>

## Definition of done
- [ ] <one observable behavior: given, when, then>
```

`Done when` is the finish line: a command or test with its expected
result, never "works" or "looks right".

`Tests` decides how `/implement` runs the task. `behavior` is any change
a user or caller could observe, bug fixes included: tests are written
from the Definition of done and shown to fail before any code. `refactor`
(same behavior, new shape), `perf` (same behavior, faster; `Done when`
names the benchmark) and `chore` (deps, config, generated code) change
no test file, and the existing suite is the check. Unsure means
`behavior`.

Each Definition-of-done box is one behavior a test can fail on and a
person can try: `POST /x with an empty body returns 422`, not `handles
errors`. The red tests are written from these boxes alone, so a behavior
missing here goes untested.

`Fuzz: yes` only when the task parses or decodes input it does not
control, round-trips an encoding, or holds an invariant over a large
input space. Most tasks are `no`.

Pick effort per task. Opus 5.5 always thinks and sizes its own thinking;
effort caps it, and thinking bills as output. A retry costs more than any
effort saves:

- `low`: the plan is clear. Renames, a known pattern across files.
- `medium`: default. Well-scoped, day-to-day work.
- `high`: the change spans layers, where medium tends to fix one layer
  and stop (handler updated, second caller missed).
- `xhigh`: rare. Problems high would not crack.

Before raising effort, check the task's finish line would catch the miss;
a test through both layers is cheaper than more thinking every turn.

Draft the breakdown before creating anything, then walk the spec once:
every requirement and the milestone finish line point to a task, and
names used across tasks match. Fix the draft, then create.

## Beans

Create each epic, then its tasks in order, before the next epic:

```bash
beans create --json "<name>" -t epic --parent <milestone-id> \
  --blocked-by <previous-epic-id> -d "<scope, finish line>"

beans create --json "<name>" -t task --parent <epic-id> -s todo \
  --blocked-by <previous-task-id> -d - <<'EOF'
<task body>
EOF
```

Parse each ID with `jq -r .bean.id`. Order via `--blocked-by` on the
previous sibling; the first task in an epic omits it, and so does an epic
that does not need an earlier epic's output. Unblocked siblings are what
the implementation run hands to parallel subagents, so block only on a
real dependency. No status changes; every task stays `todo`.

## Done

Report the milestone, epic, and task IDs as a tree, any spec gap resolved
by assumption rather than evidence, and stop. Implementation is a
separate run off the beans.
