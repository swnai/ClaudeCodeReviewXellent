$codeExtensions = @(".xml")
$staged = git diff --cached --name-only --diff-filter=ACM
$allSuggestions = ""

foreach ($file in $staged) {
    $ext = [System.IO.Path]::GetExtension($file)
	$fullPath = & "$PSScriptRoot\Get-StagedFiles.ps1" -filename $file
    if ($ext -notin $codeExtensions) { continue }
    if (-not (Test-Path $file))      { continue }

    $diff = git diff --cached $file
    if (-not $diff) { continue }
	
    $suggestions = $diff | claude -p "Review ONLY the added lines (starting with '+') in this git diff. Suggest improvements for bugs or style issues or unecessary code in those lines only. If nothing is wrong, respond with: LGTM" --output-format text
    
	if ($suggestions -match "LGTM") { continue }
    $allSuggestions += "=== $file ===`n$suggestions`n`n"
}

if ($allSuggestions -ne "") {
    Add-Type -AssemblyName System.Windows.Forms

    $result = [System.Windows.Forms.MessageBox]::Show(
        "$allSuggestions`nCommit anyway?",
        "Claude Code Review - Issues Found",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )

    if ($result -eq [System.Windows.Forms.DialogResult]::No) {
        exit 1
    }
}

exit 0

