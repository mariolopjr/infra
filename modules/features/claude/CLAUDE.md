# Claude Code

- Run the smallest relevant validation after a change
- Capture a check's exit code before truncating its output: `cmd > log; echo exit=$?`, then `tail log`. A pipe into `tail` reports tail's status
- Skip unrequested docs, changelog, formatting passes
- Step needs no input from me: keep going, status notes ride in the same message as the next action. Stop and ask only for a decision that is mine or a destructive action
- Multi-step work: keep the task list in beans, or a file when the repo has none, and update it as you go. It survives summarization
- Audits and migrations: one subagent per independent area. Check each report's evidence before accepting it

## ponytail + process

Ponytail governs the diff. `/brainstorm` and `/plan` govern process and run only when invoked. On conflict, process wins

- Behavior change: failing test first, then the code. Ponytail `one runnable check, no frameworks` does not override it

## Beans

Edges store one-sided. `--blocked-by` and `--blocking` each write only their own bean, on create and on update. `--ready` and `--is-blocked` resolve either way, `--has-blocking` does not. Pass both when the reverse lookup matters

Bean work runs `/implement` → `/review-gauntlet` → `/land`: lands by local fast-forward onto main, branches may stack on branches (`--on`). No PR unless asked

## Commits

[Conventional Commits](https://www.conventionalcommits.org) in every repo: `type(scope): summary`, imperative, lowercase, no trailing period.

Types `feat`, `fix`, `docs`, `test`, `refactor`, `chore`, `ci`, `build`, `perf`. Scope is the area touched (module, package, subsystem), reusing scopes from the repo's history; omit it when the change spans areas.

One line. Add a body only when the change is not self-evident, and keep it to a sentence or two saying what changed. No test output, no file lists, no reasoning.

When the repo uses beans, end with a `Refs: <bean-id>` footer for each bean the commit works on.

## Shell

My shell is nushell. Commands I run myself (handoffs, `! <cmd>` suggestions, setup steps) are written in native nushell syntax. Wrap in `bash -c "..."` only when nushell has no reasonable equivalent

## Communication

- Say `I don't know` when evidence missing. Mark what could not be confirmed and where you looked
- Final report: what was done, what was found, what you need from me
- An answered question is settled. Do not revisit it unless asked
- Compressed, telegraphic prose. Fragments fine. No em dashes
- Technical terms exact. Code blocks unchanged. Pattern: [thing] [action] [reason]. [next step]
- Comments only for non-obvious decisions or constraints
