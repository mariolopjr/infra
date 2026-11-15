#!/usr/bin/env python3
"""Token audit for a Claude Code project.

Reads local usage (ccusage) plus raw session transcripts
(~/.claude/projects/<slug>/*.jsonl) and reports where tokens went
and what to fix. Stdlib only.
"""

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
from collections import Counter
from typing import Any, TypedDict

PROJECTS_DIR = os.path.join(os.path.expanduser("~"), ".claude", "projects")
LARGE_RESULT_CHARS = 50_000
FAIL_RE = re.compile(
    r"(exit code [1-9]|command not found|error:|failed|traceback)",
    re.IGNORECASE,
)


class SessionStats(TypedDict):
    size: int
    n_assistant: int
    n_user: int
    tools: "Counter[str]"
    reads: "Counter[str]"
    bash: "Counter[str]"
    large: "list[tuple]"
    failures: "list[str]"
    n_failures: int
    hook_chars: int


def as_dict(v: Any) -> "dict[str, Any]":
    return v if isinstance(v, dict) else {}


def as_list(v: Any) -> "list[Any]":
    return v if isinstance(v, list) else []


def slugify(path: str) -> str:
    return os.path.abspath(path).replace("/", "-")


def run_ccusage(since: str, until: str) -> "list[dict[str, Any]]":
    if shutil.which("ccusage") is None:
        sys.exit("error: ccusage not found. Install it: npm i -g ccusage")
    cmd = ["ccusage", "claude", "session", "--json"]
    if since:
        cmd += ["-s", since]
    if until:
        cmd += ["-u", until]
    proc = subprocess.run(cmd, capture_output=True, text=True)
    if proc.returncode != 0:
        sys.exit("error: ccusage failed: %s" % (proc.stderr.strip() or proc.stdout.strip()))
    try:
        data = json.loads(proc.stdout)
    except json.JSONDecodeError:
        sys.exit("error: ccusage returned non-JSON output")
    return as_list(data.get("sessions"))


def find_transcript(session_id: str) -> str:
    """Locate <session_id>.jsonl under ~/.claude/projects (worktree-proof)."""
    try:
        dirs = os.listdir(PROJECTS_DIR)
    except OSError:
        return ""
    for dirname in dirs:
        cand = os.path.join(PROJECTS_DIR, dirname, session_id + ".jsonl")
        if os.path.isfile(cand):
            return cand
    return ""


def text_of(content: Any) -> str:
    if isinstance(content, str):
        return content
    parts = []
    for b in as_list(content):
        if not isinstance(b, dict):
            continue
        if isinstance(b.get("text"), str):
            parts.append(b["text"])
        elif isinstance(b.get("content"), str):
            parts.append(b["content"])
    return "\n".join(parts)


def analyze_transcript(path: str) -> SessionStats:
    stats: SessionStats = {
        "size": 0,
        "n_assistant": 0,
        "n_user": 0,
        "tools": Counter(),
        "reads": Counter(),
        "bash": Counter(),
        "large": [],
        "failures": [],
        "n_failures": 0,
        "hook_chars": 0,
    }
    try:
        stats["size"] = os.path.getsize(path)
        fh = open(path)
    except OSError:
        return stats
    with fh:
        for line in fh:
            try:
                record = json.loads(line)
            except json.JSONDecodeError:
                continue
            if not isinstance(record, dict):
                continue
            t = record.get("type")
            if t == "attachment":
                att = as_dict(record.get("attachment"))
                tag = str(att.get("hookName", "")) + str(att.get("hookEvent", ""))
                if "sessionstart" in tag.lower():
                    stats["hook_chars"] += len(json.dumps(att))
            if t == "assistant":
                stats["n_assistant"] += 1
                blocks = as_list(as_dict(record.get("message")).get("content"))
                for b in blocks:
                    if not isinstance(b, dict) or b.get("type") != "tool_use":
                        continue
                    name = str(b.get("name", "?"))
                    stats["tools"][name] += 1
                    inp = as_dict(b.get("input"))
                    if name == "Read" and inp.get("file_path"):
                        stats["reads"][str(inp["file_path"])] += 1
                    elif name == "Bash" and inp.get("command"):
                        stats["bash"][str(inp["command"])[:100]] += 1
            elif t == "user":
                stats["n_user"] += 1
                blocks = as_list(as_dict(record.get("message")).get("content"))
                for b in blocks:
                    if not isinstance(b, dict) or b.get("type") != "tool_result":
                        continue
                    txt = text_of(b.get("content"))
                    if len(txt) >= LARGE_RESULT_CHARS:
                        stats["large"].append(("?", len(txt)))
                    if FAIL_RE.search(txt[:2000]):
                        stats["failures"].append(txt[:160].replace("\n", " "))
        stats["large"].sort(key=lambda x: x[1], reverse=True)
        stats["large"] = stats["large"][:5]
        stats["failures"] = stats["failures"][:3]
        stats["n_failures"] = len(stats["failures"])
    return stats


def static_prefix(repo: str) -> "tuple[list[tuple[str, int]], int]":
    """Measure the always-loaded prefix: CLAUDE.md/AGENTS.md + skills."""
    rows = []
    total = 0
    for name in ("CLAUDE.md", "AGENTS.md"):
        p = os.path.join(repo, name)
        if os.path.islink(p):
            rows.append((name + " -> " + os.readlink(p), 0))
        elif os.path.isfile(p):
            try:
                n = os.path.getsize(p)
            except OSError:
                continue
            rows.append((name, n))
            total += n
    for root, _dirs, files in os.walk(repo):
        if ".git" in root.split(os.sep):
            continue
        for f in files:
            if f == "SKILL.md":
                p = os.path.join(root, f)
                try:
                    n = os.path.getsize(p)
                except OSError:
                    continue
                rows.append((os.path.relpath(p, repo), n))
                total += n
    return rows, total


def fmt(n: Any) -> str:
    try:
        n = int(n)
    except (TypeError, ValueError):
        return "?"
    return "%d" % n if n < 10000 else "%dk" % round(n / 1000)


def recommend(sess: "dict[str, Any]", a: SessionStats) -> "list[str]":
    recs = []
    repeats = [(p, c) for p, c in a["reads"].items() if c >= 3]
    if repeats:
        top = sorted(repeats, key=lambda x: x[1], reverse=True)[:3]
        recs.append(
            "Repeated reads (%s) — fold into CLAUDE.md or a Skill so it is read once."
            % ", ".join("`%s` x%d" % (p, c) for p, c in top)
        )
    if a["n_failures"] >= 3:
        recs.append(
            "%d failed tool results — verify commands with a one-shot dry run "
            "before looping; tighten allowed tools." % a["n_failures"]
        )
    if a["large"]:
        recs.append(
            "Large tool results (%s) — use rg/head/targeted paths; add "
            ".claudeignore for build dirs."
            % ", ".join("%dKB" % (c // 1024) for _, c in a["large"])
        )
    if a["hook_chars"] > 10_000:
        recs.append(
            "SessionStart hook injects ~%dKB per session — trim hook output; "
            "it is re-read on every compact." % (a["hook_chars"] // 1024)
        )
    out_t = sess.get("outputTokens", 0) or 0
    in_t = (sess.get("inputTokens", 0) or 0) + (sess.get("cacheReadTokens", 0) or 0)
    if out_t and in_t and out_t > in_t * 0.5:
        recs.append(
            "Output-heavy (out %s vs in %s) — set a concise-output rule; "
            "delegates return summaries, not dumps." % (fmt(out_t), fmt(in_t))
        )
    if sess.get("cacheReadTokens", 0) == 0 and in_t > 100_000:
        recs.append(
            "No cache reads — prefix churned mid-session. Keep CLAUDE.md/MCP "
            "list stable within a session."
        )
    agent_n = a["tools"].get("Agent", 0) + a["tools"].get("Task", 0)
    if agent_n >= 5:
        recs.append(
            "%d subagent calls — cheap triage belongs on Haiku/local "
            "(omlx), summaries back only." % agent_n
        )
    if not recs:
        recs.append("No dominant waste pattern. Split long sessions with /clear.")
    return recs


def fallback_transcripts(slug: str, top: int) -> "list[tuple[str, int]]":
    """Largest raw transcripts for slug dirs (incl. worktree suffixes)."""
    found: "list[tuple[str, int]]" = []
    try:
        dirs = os.listdir(PROJECTS_DIR)
    except OSError:
        return found
    for dirname in dirs:
        if not dirname.startswith(slug):
            continue
        d = os.path.join(PROJECTS_DIR, dirname)
        if not os.path.isdir(d):
            continue
        try:
            files = os.listdir(d)
        except OSError:
            continue
        for f in files:
            if f.endswith(".jsonl"):
                p = os.path.join(d, f)
                try:
                    found.append((p, os.path.getsize(p)))
                except OSError:
                    continue
    found.sort(key=lambda x: x[1], reverse=True)
    return found[: max(top, 0)]


def main() -> None:
    ap = argparse.ArgumentParser(description="Audit a project's Claude token spend")
    _ = ap.add_argument("--dir", default=".", help="project directory (default: cwd)")
    _ = ap.add_argument("--top", type=int, default=5, help="costliest sessions to dissect")
    _ = ap.add_argument("--since", default="", help="ccusage start date (YYYYMMDD)")
    _ = ap.add_argument("--until", default="", help="ccusage end date (YYYYMMDD)")
    _ = ap.add_argument("--output", default="", help="write markdown report to file")
    args = ap.parse_args()

    repo = os.path.abspath(args.dir)
    slug = slugify(repo)
    sessions = run_ccusage(args.since, args.until)
    mine = [s for s in sessions if str(s.get("projectPath", "")).startswith(slug)]
    mine.sort(key=lambda s: s.get("totalCost", 0), reverse=True)

    L = []
    L.append("# Token audit: %s" % repo)
    L.append("")
    L.append("Slug `%s`, %d session(s) in range." % (slug, len(mine)))
    tot_cost = sum(s.get("totalCost", 0) for s in mine)
    tot_tok = sum(s.get("totalTokens", 0) for s in mine)
    L.append("Total: $%.2f, %s tokens." % (tot_cost, fmt(tot_tok)))
    L.append("")

    rows, prefix_total = static_prefix(repo)
    L.append("## Static prefix (loaded every turn)")
    L.append("")
    if rows:
        for name, n in rows:
            L.append("- `%s` %sB" % (name, fmt(n)))
        L.append("- **Prefix total ~%sB (~%s tokens)**" % (fmt(prefix_total), fmt(prefix_total // 4)))
    else:
        L.append("- No CLAUDE.md/AGENTS.md/SKILL.md found.")
    L.append("")

    if not mine:
        L.append("No billed ccusage sessions for this slug. Falling back to")
        L.append("raw transcripts (sidechain/hook-only sessions have no cost).")
        L.append("")
        for tpath, size in fallback_transcripts(slug, args.top):
            a = analyze_transcript(tpath)
            L.append("## Transcript `%s` — %dKB, unbilled" % (os.path.basename(tpath)[:8], size // 1024))
            L.append("")
            top_tools = ", ".join("%s x%d" % (k, v) for k, v in a["tools"].most_common(6))
            L.append(
                "- %d assistant / %d user turns, tools: %s"
                % (a["n_assistant"], a["n_user"], top_tools or "none")
            )
            if a["hook_chars"]:
                L.append("- hook/attachment payload: ~%dKB" % (a["hook_chars"] // 1024))
            L.append("")
            L.append("Fixes:")
            for r in recommend({}, a):
                L.append("- %s" % r)
            L.append("")
        if len(L) <= 12:
            L.append("No transcripts either. Check `ls ~/.claude/projects/ | grep %s`." % slug[-24:])
    for s in mine[: max(args.top, 0)]:
        sid = str(s.get("sessionId", "?"))
        L.append("## Session `%s` — $%.2f" % (sid[:8], s.get("totalCost", 0)))
        L.append("")
        L.append(
            "- tokens %s (in %s, cache-read %s, cache-create %s, out %s), models: %s"
            % (
                fmt(s.get("totalTokens", 0)),
                fmt(s.get("inputTokens", 0)),
                fmt(s.get("cacheReadTokens", 0)),
                fmt(s.get("cacheCreationTokens", 0)),
                fmt(s.get("outputTokens", 0)),
                ", ".join(s.get("modelsUsed", [])) or "?",
            )
        )
        tpath = find_transcript(sid)
        a = analyze_transcript(tpath) if tpath else None
        if a is None or (a["n_assistant"] == 0 and a["n_user"] == 0):
            L.append("- transcript not found under ~/.claude/projects.")
            L.append("")
            L.append("Fixes:")
            L.append("- Transcript pruned. Rely on ccusage totals above.")
        else:
            top_tools = ", ".join("%s x%d" % (k, v) for k, v in a["tools"].most_common(6))
            L.append(
                "- transcript %dKB, %d assistant / %d user turns, tools: %s"
                % (a["size"] // 1024, a["n_assistant"], a["n_user"], top_tools or "none")
            )
            if a["n_failures"]:
                L.append("- failed tool results: %d" % a["n_failures"])
            L.append("")
            L.append("Fixes:")
            for r in recommend(s, a):
                L.append("- %s" % r)
        L.append("")

    report = "\n".join(L) + "\n"
    if args.output:
        try:
            with open(args.output, "w") as fh:
                _ = fh.write(report)
        except OSError as e:
            sys.exit("error: cannot write %s: %s" % (args.output, e))
        print("wrote %s" % args.output)
    else:
        print(report, end="")


if __name__ == "__main__":
    main()
