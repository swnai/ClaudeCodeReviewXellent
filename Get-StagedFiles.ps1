param(
	[string]$filename
)

$RootFolder = "J:\git\AX7"

$gitDir = Join-Path $RootFolder ".git"

if (-not (Test-Path $gitDir)) {
    Write-Error "No .git directory found in: $RootFolder"
    exit 1
}

$stagedFullPath = git -C $RootFolder diff --name-only --cached
$stagedFiles = Split-Path -Leaf $stagedFullPath

if (-not $stagedFiles) {
    Write-Host "No staged files."
    exit 0
}

if ($filename -in $stagedFiles) {
    Write-Host (Join-Path $RootFolder $stagedFullPath)
}
