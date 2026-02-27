$codeExtensions = @(".xml", ".cs", ".xpp")
$staged = git diff --cached --name-only --diff-filter=ACM
$allSuggestions = ""

foreach ($file in $staged) {
    $ext = [System.IO.Path]::GetExtension($file)
	$fullPath = & "$PSScriptRoot\Get-StagedFiles.ps1" -filename $file
	
	$details = & "$PSScriptRoot\GetD365ObjectInfo.ps1" $fullPath
	$filename = Split-Path -Leaf $file
	$module = $details.ModuleName
	$model = $details.ModelName
	$Object = $details.ObjectType
	
    if ($ext -notin $codeExtensions) { continue }
    if (-not (Test-Path $file))      { continue }

    $diff = git diff --cached $file
    if (-not $diff) { continue }

	$bpCommand = "J:\AosService\PackagesLocalDirectory\bin\xppbp.exe -metadata='J:\AosService\PackagesLocalDirectory' $($object):XAI_RequestCache -model=$model -module=$module"
	$bestPractice = Invoke-Expression $bpCommand
	$suggestions = $diff | claude -p "Review ONLY the changed lines (starting with '+' for added code and '-' for removed code) in this git diff. Suggest improvements for bugs or style issues or unecessary code in those lines only. Analyze $bestpractice for the changes and give a nicely curated document" --output-format text
   
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


