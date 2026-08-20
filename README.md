# Repro: GKD 12.4.0 shows every line as changed in the unstaged diff

Support case 47699720789. Regression 12.3.1 -> 12.4.0, Windows.

## What this repo is

`crlf-blob.atm` was committed with **CRLF bytes in the blob** (`i/crlf`), with no `.gitattributes`.
That is the one condition needed: GKD 12.4.0's unstaged-diff path runs `git hash-object -w <path>`
to get the worktree side, and `hash-object` cleans CRLF unconditionally — it lacks the rule real
`git diff` has that suppresses CRLF->LF conversion when the index blob already contains CRLF. With
`core.autocrlf=true` (which GKD's own bundled gitconfig sets at system scope) the worktree side gets
rewritten to LF while the index side stays CRLF, so **every line differs**.

`lf-blob.atm` is the control: identical content, LF blob. It should always diff correctly.

**Do not add a `.gitattributes`** to this repo — it would set `text`/`eol` attributes and mask the bug.

## Steps (Windows, GKD 12.4.0)

1. Clone this repo. Do **not** set `core.autocrlf` yourself; leave whatever you have.
2. GitKraken Desktop -> Preferences -> Experimental -> **Git Executable ON**. This is required —
   the bug lives in the git-binary branch. Restart GKD.
3. Make the one-line change:
   ```
   powershell -ExecutionPolicy Bypass -File .\make-change.ps1
   ```
   (Or edit `Version = 1.0.0` -> `1.0.1` by hand in an editor that preserves CRLF.)
4. Open the repo in GKD and look at the **unstaged** diff:
   - `crlf-blob.atm` -> **every line shown as changed** (the bug)
   - `lf-blob.atm` -> only line 1 changed (correct)
5. Confirm the signature: **stage** `crlf-blob.atm`. The staged diff shows only the real change.
   Turning on "ignore leading/trailing whitespace" on the unstaged diff also collapses it to line 1.
6. Confirm the workaround: Preferences -> Experimental -> **Git Executable OFF**, restart GKD.
   The unstaged diff of `crlf-blob.atm` is now correct — this is the 12.3.1 code path.

## Ground truth

Real `git diff` is correct the whole time — the repo is not broken, the renderer is:

```
powershell -ExecutionPolicy Bypass -File .\verify.ps1
```

Point it at the bundled git to match exactly what GKD runs:

```
powershell -ExecutionPolicy Bypass -File .\verify.ps1 -Git "$env:LOCALAPPDATA\gitkraken\app-12.4.0\resources\app.asar.unpacked\git\cmd\git.exe"
```

Expected output: `real git diff` reports `1 1` for both files, while the simulated GKD path reports
all lines differing for `crlf-blob.atm` and only the genuine change for `lf-blob.atm`.

`verify.ps1` also prints the loose-object count before/after. The `-w` in `hash-object -w` is
unnecessary to compute a hash and writes an object into `.git` on every WIP diff render — a second,
separate defect (repo grows until a `gc`).
