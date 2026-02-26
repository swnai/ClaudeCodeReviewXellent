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
foreach ($path in $stagedFullPath) {
	if ($filename -in (Split-Path -Leaf $path)) {
		Write-Host (Join-Path $RootFolder $path)
	}
}

if (-not $stagedFullPath) {
    Write-Host "No staged files."
    exit 0
}
