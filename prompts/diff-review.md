You are reviewing a code change. Use a TOP-DOWN approach:

1. INTENT FIRST — before looking at code, determine what this change is for:
   - the branch name, commit subjects (`git log main..HEAD --oneline`), and any
     linked issue numbers
   - run `git diff --stat {{base}}...HEAD` to see the shape of the change
2. HIGH-LEVEL — summarize in a few bullets what components changed and why,
   and how they fit the project's architecture (read AGENTS.md and docs/ if
   present).
3. SOURCE FILES FIRST — deep-dive changed source files only. For each: what
   it does, what changed, whether it matches the intent, and the risk of
   regressions. Flag scope creep (files changed that do not serve the stated
   purpose).
   - If the repo documents a hot path (e.g. docs/architecture/hot-cold-path.md),
     prioritize it: order/market-data/quoting loops, OMS-owned risk, and
     safety gates come before everything else. Call out anything that would
     slow down or break the hot path.
4. TESTS & DOCS — summarize these in one or two lines TOTAL (per category,
   not per file): what coverage was added/removed, and whether any
   documentation says something that no longer matches the code. Do NOT
   deep-dive into test or doc hunks.
5. HUNK-LEVEL — only then inspect diff detail for risky SOURCE hunks
   (`git diff {{base}}...HEAD -- <file>`). Note for each risky hunk: what
   changed and why it is risky (order of evaluation, safety/staleness,
   idempotency, resource handling, breaking a contract). Skip hunks that are
   pure refactors or tests.
6. VERDICT — one short paragraph: approve / needs-work / changes-requested,
   with the 1-3 concrete items to fix if any.

Format the reply as markdown with clear sections. Be concise; prefer bullets.
Do not restate code verbatim; reference file:line for anything you call out.
