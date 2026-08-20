# Shows what real git thinks, then simulates the GKD 12.4.0 unstaged-diff code path
# (getFilteredWorkdirFileContents = `git hash-object -w` + `git show`).
#
# Run from the repo root:
#   powershell -ExecutionPolicy Bypass -File .\verify.ps1
# To test with the git that GKD bundles (the one that matters), pass its path:
#   powershell -ExecutionPolicy Bypass -File .\verify.ps1 -Git "$env:LOCALAPPDATA\gitkraken\app-12.4.0\resources\app.asar.unpacked\git\cmd\git.exe"

param([string]$Git = "git")

function G { & $Git @args }

$probe = (& $Git --version 2>&1 | Out-String).Trim()
if ($probe -notmatch 'git version') {
    Write-Host "ERROR: -Git is not a git executable." -ForegroundColor Red
    Write-Host "  -Git = '$Git'"
    Write-Host "  got  : $probe"
    Write-Host ""
    Write-Host "Run each command on its OWN line."
    exit 1
}

Write-Host "git          : $((G --version) -join ' ')"
Write-Host "autocrlf     : $((G config --show-origin core.autocrlf) -join ' ')"
Write-Host ""

$loose_before = (Get-ChildItem -Path ".git\objects" -Recurse -File -ErrorAction SilentlyContinue |
                 Where-Object { $_.DirectoryName -notmatch "pack|info" }).Count

foreach ($f in @("crlf-blob.atm", "lf-blob.atm")) {
    Write-Host "--- $f"
    Write-Host "  ls-files --eol : $((G ls-files --eol -- $f) -join ' ')"
    $ns = (G diff --numstat -- $f) -join ' '
    Write-Host "  real git diff  : $ns   <-- ground truth"

    $idx = (G rev-parse ":$f").Trim()
    $new = (G hash-object -w -- $f).Trim()
    G show $idx > "$env:TEMP\a.txt"
    G show $new > "$env:TEMP\b.txt"
    $d = (Compare-Object (Get-Content "$env:TEMP\a.txt") (Get-Content "$env:TEMP\b.txt")).Count
    $total = (G show $idx | Measure-Object -Line).Lines
    Write-Host "  GKD 12.4.0 path: $d differing lines of $total"
    if ($idx -ne $new -and $d -gt 2) {
        Write-Host "  >> BUG: workdir side was re-cleaned, whole file reads as changed" -ForegroundColor Red
    } else {
        Write-Host "  >> ok: only the genuine change" -ForegroundColor Green
    }
    Write-Host ""
}

$loose_after = (Get-ChildItem -Path ".git\objects" -Recurse -File -ErrorAction SilentlyContinue |
                Where-Object { $_.DirectoryName -notmatch "pack|info" }).Count
Write-Host "loose objects: $loose_before -> $loose_after   (the -w in hash-object -w writes garbage into .git on every diff render)"
