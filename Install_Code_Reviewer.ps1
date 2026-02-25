param(
    [Parameter(Mandatory=$true)]
    [string]$project
)

$base = "https://raw.githubusercontent.com/swnai/ClaudeCodeReviewXellent/main"

Invoke-WebRequest "$base/pre-commit"     -OutFile "$project/.git/hooks/pre-commit"
Invoke-WebRequest "$base/pre-commit.ps1" -OutFile "$project/.git/hooks/pre-commit.ps1"