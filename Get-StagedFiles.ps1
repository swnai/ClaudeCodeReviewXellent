param(
	[string]$filename
)

$RootFolder = "J:\git\AX7"

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

if ($filename -in $stagedFiles) {
    Write-Host (Join-Path $RootFolder $filename)
}
