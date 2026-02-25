param(
    [string]$RootFolder
)

if (-not $RootFolder) {
    Write-Error "Usage: .\Get-StagedFiles.ps1 -RootFolder <path>"
    exit 1
}

$gitDir = Join-Path $RootFolder ".git"

if (-not (Test-Path $gitDir)) {
    Write-Error "No .git directory found in: $RootFolder"
    exit 1
}

$stagedFiles = git -C $RootFolder diff --name-only --cached

if (-not $stagedFiles) {
    Write-Host "No staged files."
    exit 0
}

foreach ($file in $stagedFiles) {
    Write-Host (Join-Path $RootFolder $file)
}
