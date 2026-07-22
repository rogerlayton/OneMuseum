# HANDOVER — v1.0.2

## What shipped
Fresh-repo git baseline (**D-004**). The canonical repo is now
**github.com/rogerlayton/OneMuseum** (branch `main`, tag `v1.0.2`). The prior
GitHub history was deliberately abandoned (Roger's call) and archived as
**`OneMuseum-V0.11-old`**; tags `v0.11` and `v1.0.1` exist only there, not on
the new remote. HTTPS auth via `gh auth login` (browser flow) into macOS
Keychain — GitHub passwords are not accepted for git, a PAT or `gh` is needed.

**v1.0.2 is a baseline/repo-reset release, not a feature release.** The tree is
v1.0.1 plus documentation updates only (D-004, D-005, backlog/context/handover).
No application code changed. Also logged this session: **D-005** (the layered
remediation plan) as SPEC, and **B-003** (auth bypass) now recorded in the
backlog as a launch blocker.

## Next target
The **D-005 layered plan**, one increment at a time, each accepted before
coding:
1. **F-008 — dbutils error surfacing** (root layer; stop swallowing
   exceptions, surface/raise). Start here.
2. **F-009 — switchable logging** (exception + route + SQL/proc + params).
3. **F-010 — test harness** (MathGL-modelled: corpus/goldens/compare-accept-
   review runner, deliberate acceptance, docs-in-step, CI). Needs 1 & 2, plus
   a **pinned DB-fixture decision** (OneMuseum renders from MariaDB via stored
   procs — goldens can't be pure file-renders as in MathGL).

Anchor case running through all three: **B-004** — equations-lesson 500
(`markdown-katex` needs a native `katex` binary absent on the Mac). The fork
(`npm install katex` vs. client-side KaTeX/MathJax) is a real decision; own
entry when reached, don't one-line it.

## Open — awaiting Roger
- **Accept D-005 layer by layer.** The plan is agreed (SPEC); each layer's
  implementation is accepted before coding. Confirm F-008 as the first
  increment to start.
- **Verify v1.0.2 runs** in the real environment (MariaDB + env vars) — same
  eyeball as v1.0.1 (a browser list, a details page, a categories page, a
  menu). v1.0.2 is byte-identical to v1.0.1 in app code, so if v1.0.1 was
  blessed this is a formality, but note it explicitly.
- **B-004 fork ruling** when F-008/F-009 make the 500 diagnosable and we reach
  the anchor.
- **DB-fixture strategy** for F-010 (fixed seed dump vs mocked query results) —
  a decision, needed before the harness.

## Also open (parked, not blocking)
- **B-003** — auth bypass, kept for now; **must remove + history-scrub before
  public launch** (now on the public-track repo). Do not exercise; remove only
  when asked.
- F-004 asset diet (~71 MB Now-UI demo imagery; the v1.0.2 push included it),
  F-006 SQL identifier hardening (matters at public launch), F-007 snippet/POC
  housekeeping, B-002 `test_menus` defect (test-only). See docs/BACKLOG.md.
- Bigger parked items: F-001 Postgres, F-002 containerization, F-003 UI
  reframe.

## Process notes
- **Fresh session per increment** from a `git archive HEAD` zip of the
  committed state (methodology §5). This v1.0.2 tree — with these doc updates
  committed — is the correct starting archive for the F-008 session.
- Git sequences explicit: `git add .` never bare (phantom-archive scar, §4);
  `git push --tags` separately (a normal push does not send tags).
- MathGL's methodology is now absorbed into OneMuseum's docs; its HEAD zip is
  **not** needed in the next session unless a specific structural detail of its
  test runner is being copied.
- Docs and code move together in the same commit. This handover, D-004, D-005,
  and the backlog/context updates land together as the v1.0.2 doc commit.
