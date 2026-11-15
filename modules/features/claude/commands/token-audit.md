---
description: Audit a project's Claude token spend from local sessions and report fixes
argument-hint: '[--top N] [--since YYYYMMDD] [--output <file>] [--dir <repo>]'
disable-model-invocation: true
allowed-tools: Bash, Read
---

Run the audit script against the target repo (default: cwd), read the
report, then apply fixes as below. Stdlib only; needs `ccusage` on PATH
(`npm i -g ccusage`).

Raw arguments: `$ARGUMENTS`

```sh
python3 ~/.claude/scripts/token-audit.py --dir <repo> [--top 5] [--since YYYYMMDD] [--until YYYYMMDD] [--output token-audit.md]
```

What it does: pulls billed usage via `ccusage claude session --json`,
filters to the repo slug (worktree-proof), dissects the costliest raw
transcripts under `~/.claude/projects/<slug>/`, and measures the static
prefix (`CLAUDE.md` + skills). Falls back to raw transcripts when sessions
carry no billed usage.

After the report: apply fixes in priority order, one per change — repeated
reads become a Skill/CLAUDE.md entry, large results get `rg`/`head` and
`.claudeignore`, hook bloat gets trimmed at the source, output-heavy work
gets a concise-output rule and delegate summaries. Re-run to confirm the
next audit moves.
