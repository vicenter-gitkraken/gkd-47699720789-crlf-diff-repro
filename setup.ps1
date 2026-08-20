# Forces the ONE condition the bug needs, independently of your machine's config:
# core.autocrlf=true at REPO-LOCAL scope. Local config beats both global and system,
# and is read by whichever git binary GKD invokes, so this removes all ambiguity.
#
#   powershell -ExecutionPolicy Bypass -File .\setup.ps1
#
# Optionally point at the git GKD bundles, to read back the same view it sees:
#   powershell -ExecutionPolicy Bypass -File .\setup.ps1 -Git "$env:LOCALAPPDATA\gitkraken\app-12.4.0\resources\app.asar.unpacked\git\cmd\git.exe"

param([string]$Git = "git")
function G { & $Git @args }

# Guard: if two commands get pasted on one line, "powershell" binds to -Git and every
# call below fails with a confusing "term not recognized". Fail loudly instead.
$probe = (& $Git --version 2>&1 | Out-String).Trim()
if ($probe -notmatch 'git version') {
    Write-Host "ERROR: -Git is not a git executable." -ForegroundColor Red
    Write-Host "  -Git = '$Git'"
    Write-Host "  got  : $probe"
    Write-Host ""
    Write-Host "Run each command on its OWN line - do not paste setup.ps1 and make-change.ps1 together."
    exit 1
}

G config core.autocrlf true
G checkout -- crlf-blob.atm lf-blob.atm     # back to baseline, discards any earlier edit

Write-Host "git       : $((G --version) -join ' ')"
Write-Host "autocrlf  :"
G config --show-origin --get-all core.autocrlf | ForEach-Object { Write-Host "    $_" }
Write-Host "  (the LAST line above wins; it must be 'true' from .git/config)"
Write-Host ""
Write-Host "eol state :"
G ls-files --eol -- crlf-blob.atm lf-blob.atm | ForEach-Object { Write-Host "    $_" }
Write-Host "  (need i/crlf w/crlf for crlf-blob.atm)"
Write-Host ""
Write-Host "Next: .\make-change.ps1, then look at the UNSTAGED diff in GitKraken Desktop."
Write-Host "Git Executable must be ON (Preferences -> Experimental) or the buggy path never runs."
