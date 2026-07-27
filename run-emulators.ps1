# ─────────────────────────────────────────────────────────────────────────────
# SpazaLink — start the Firebase Emulator Suite with DURABLE persistence.
#
# Data lives in ./emulator-data and is:
#   • loaded on start        (--import)
#   • saved on graceful exit (--export-on-exit, i.e. Ctrl+C)
#   • saved every 3 minutes  (the background backup loop below) so an
#     unexpected crash/power-off loses at most a few minutes.
#
# Usage:  right-click → Run with PowerShell,  or:  ./run-emulators.ps1
# Stop:   press Ctrl+C in this window (this also does a final export).
# ─────────────────────────────────────────────────────────────────────────────

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

$project  = "spazalink-d8a59"
$dataDir  = Join-Path $PSScriptRoot "emulator-data"

# Import only if a previous export exists (first run has none).
$importArg = if (Test-Path $dataDir) { "--import=$dataDir" } else { "" }

# ── Background backup: snapshot the running emulator every 3 minutes ──────────
$backup = Start-Job -ArgumentList $project, $dataDir -ScriptBlock {
    param($project, $dataDir)
    while ($true) {
        Start-Sleep -Seconds 180
        firebase emulators:export $dataDir --force --project $project *> $null
    }
}

try {
    firebase emulators:start `
        --project $project `
        --only auth,firestore,storage `
        $importArg `
        --export-on-exit=$dataDir
}
finally {
    Stop-Job  $backup -ErrorAction SilentlyContinue
    Remove-Job $backup -ErrorAction SilentlyContinue
}
