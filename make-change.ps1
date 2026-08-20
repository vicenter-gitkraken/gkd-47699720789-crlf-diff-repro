# Makes ONE genuine change (the version number) in each .atm file,
# preserving each file's existing line endings byte-for-byte.
# Run from the repo root:  powershell -ExecutionPolicy Bypass -File .\make-change.ps1

foreach ($f in @("crlf-blob.atm", "lf-blob.atm")) {
    $p = Join-Path $PSScriptRoot $f
    $t = [System.IO.File]::ReadAllText($p)
    $t = $t.Replace("Version = 1.0.0", "Version = 1.0.1")
    [System.IO.File]::WriteAllText($p, $t)
    $cr = ([regex]::Matches($t, "`r")).Count
    $lf = ([regex]::Matches($t, "`n")).Count
    Write-Host ("{0,-16} edited  (CR={1} LF={2})" -f $f, $cr, $lf)
}

Write-Host ""
Write-Host "Exactly one line changed in each file. Now open the repo in GitKraken Desktop."
