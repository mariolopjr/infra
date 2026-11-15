---
name: brainstorm
description: Turn an idea into an agreed design before any code. Ends with a design in chat or a spec in a beans milestone, never with implementation.
argument-hint: <idea or feature>
disable-model-invocation: true
allowed-tools: Read, Agent, Bash(git:*), Bash(ls:*), Bash(rg:*), Bash(fd:*), Bash(beans:*), Bash(jq:*), AskUserQuestion
---

Design first: `$ARGUMENTS`

Read the code the change would touch before asking anything. Recent
commits and existing patterns answer most questions; the rest go to the
user. When the change reaches several independent areas, give each area
its own subagent and check the evidence each reports before relying on it. Ask everything that changes the design in one round, independent
questions grouped, your recommended answer first. Once answered, it is
settled; do not reopen it.

Scale the artifact to the change. A change to a flow that already exists in
the repo gets a short design in chat: approach, files touched, how it is
tested, and the finish line. Stop there and wait for a yes; the yes hands
off to implementation. A change that adds a subsystem, restructures how
components fit, or alters an interface others depend on gets a spec in a
milestone bean, and `/plan` comes next.

Offer alternatives only where a real trade-off exists, recommendation
first. Cut speculative scope from every option. If the idea spans several
independent subsystems, say so before refining details and split it; each
piece gets its own milestone.

## Spec

The milestone bean body is the spec; no file under `docs/`. Prefer
references to prose: name the files and functions involved, write
interfaces as signatures, state test cases as assertions. Sections:

- Goal and non-goals
- Finish line: the observable state that means done, e.g. "every caller
  uses the new client, the old one is deleted, the suite passes"
- Design: components, interfaces, data flow
- Error handling
- Testing: what is covered and how
- Constraints: versions, naming, platform rules, exact values

Resolve every open question before saving; a spec with a TBD is not done.
Mark anything you could not confirm in the code, and where you looked.

## Beans

`beans list` fails: offer `beans init`, run it only on yes; no beans, no
spec. `beans list --json -t milestone` shows the current milestones. Name
the one this spec belongs to and replace its body, or propose a new one
and create it only on yes:

```bash
beans create --json "<name>" -t milestone -d - <<'EOF'
<spec>
EOF
beans update --json <id> -d - <<'EOF'
<spec>
EOF
```

Parse the ID with `jq -r .bean.id`. One spec, one milestone: if the idea
needs two, it is two milestones, split it before writing. Never create
epics or tasks here; `/plan` owns the breakdown.

## Done

Report the milestone ID, anything left unconfirmed, and stop. Breakdown
starts with `/plan <milestone-id>`, not here.
