You are comparing two versions of a repository. Use a TOP-DOWN approach:

1. IDENTIFY — fetch both versions:
   - head: `git fetch origin {{head}}` then `git diff {{base}}...{{head}} --stat`
   - if the inputs look like PR numbers, use `gh pr view <n>` and
     `gh pr diff <n>` to understand them instead
2. OVERVIEW — one paragraph: what changed between {{base}} and {{head}},
   how many files, which components/areas of the codebase are touched, and
   what the head version is trying to accomplish.
3. SOURCE BEHAVIORAL DIFFERENCES — the important part. Only for SOURCE
   files: list behavior changes (API contracts, message formats, error paths,
   config keys, safety/staleness handling, performance characteristics).
   Mark each as: behavioral / refactor-only / unclear.
   - If the repo documents a hot path (e.g. docs/architecture/hot-cold-path.md),
     call out any difference there explicitly: order/market-data/quoting
     loops, OMS-owned risk, safety gates.
4. TESTS & DOCS — one or two lines TOTAL: coverage added/removed and any doc
   drift. Do not deep-dive them.
5. PER-FILE — for SOURCE files whose behavior changed, one or two bullets
   each: what the change does and the risk of regressions.
6. VERDICT — could you merge head onto {{base}} safely? List the concrete
   concerns (file:line) a reviewer should resolve first.

Format the reply as markdown with clear sections. Be concise; prefer bullets.
Do not restate code verbatim.
