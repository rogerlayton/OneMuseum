# CHANGES — v1.0.2

Fresh-repo git baseline. **Documentation-only**; no application code changed.
The tree is v1.0.1 plus the doc updates below. Implements **D-004**; records
**D-005** (SPEC) and **B-003**.

## Git baseline (D-004)
- Canonical repo is now **github.com/rogerlayton/OneMuseum** (branch `main`,
  tag `v1.0.2`).
- Prior GitHub history deliberately abandoned and archived as
  **`OneMuseum-V0.11-old`** (Roger's call). Tags `v0.11` and `v1.0.1` survive
  only there, not on the new remote.
- Local tree was an extracted zip with no `.git`; started fresh via `git init`
  rather than clone-and-overlay (avoids the mixed-state trap). See D-004 for
  the full rationale and consequences.

## Documentation
- **D-004** added (fresh-repo baseline, honest record of abandoned history).
- **D-005** added as SPEC — the layered remediation plan: F-008 error surfacing
  -> F-009 switchable logging -> F-010 test harness (MathGL-modelled, adapted
  for DB-backed rendering; needs a pinned DB-fixture decision).
- **BACKLOG:** version plan updated (v1.0.1 shipped, v1.0.2 baseline, D-005
  sequence next); F-008 promoted to NEXT UP; F-009, F-010, B-004 added; new
  **Security / launch blockers** section records **B-003** (auth bypass, kept
  for now, must remove + scrub before public).
- **CONTEXT:** current state updated to v1.0.2 + new repo.
- **HANDOVER-v1.0.2.md** added in the established skeleton.

## Not changed
- No application code, templates, SQL, or dependencies. `requirements*.txt`,
  `onemuseum/**`, `tests/**`, `SQL/**` are byte-identical to v1.0.1.

---

## Commit sequence (docs land together, per methodology §2)

Run from the repo root, after copying the updated `docs/` and `updates/` files
into the tree:

```
git add docs/DECISIONS.md docs/BACKLOG.md docs/CONTEXT.md \
        updates/HANDOVER-v1.0.2.md updates/CHANGES-v1.0.2.md
git commit -m "v1.0.2 docs — D-004 fresh-repo baseline; D-005 layered plan (SPEC); B-003 logged"
git push
```

> Note: `v1.0.2` was already tagged at the baseline push. This doc commit lands
> on top of it. If you want the tag to point at the *documented* tree, move it:
> `git tag -f v1.0.2 && git push --tags --force` — optional, Roger's call.
> (Leaving the tag on the initial commit is also fine; the docs are on `main`.)
