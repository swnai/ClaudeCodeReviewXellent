$codeExtensions = @(".xml", ".cs", ".xpp")
$staged = git diff --cached --name-only --diff-filter=ACM
$allSuggestions = ""

foreach ($file in $staged) {
    $ext = [System.IO.Path]::GetExtension($file)	
	$details = & "$PSScriptRoot\GetD365ObjectInfo.ps1" $file
	$filename = Split-Path -Leaf $file
	$module = $details.ModuleName
	$model = $details.ModelName
	$Object = $details.ObjectType
	
    if ($ext -notin $codeExtensions) { continue }
    if (-not (Test-Path $file))      { continue }

    $diff = git diff --cached $file
    if (-not $diff) { continue }

	$bpCommand = "J:\AosService\PackagesLocalDirectory\bin\xppbp.exe -metadata='J:\AosService\PackagesLocalDirectory' $($object):$filename -model=$model -module=$module"
	$bestPractice = Invoke-Expression $bpCommand
	$suggestions = $diff | claude -p "Review ONLY the changed lines (starting with '+' for added code and '-' for removed code) in this git diff. Suggest improvements for bugs or style issues or unecessary code in those lines only. Analyze $bestpractice for the changes and give a nicely curated document" --output-format text
   
    $allSuggestions += "=== $file ===`n$suggestions`n`n"
}

if ($allSuggestions -ne "") {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Claude Code Review - Issues Found"
    $form.WindowState = [System.Windows.Forms.FormWindowState]::Maximized
    $form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen

    $textBox = New-Object System.Windows.Forms.RichTextBox
    $textBox.Dock = [System.Windows.Forms.DockStyle]::Fill
    $textBox.Text = "$allSuggestions`nCommit anyway?"
    $textBox.ReadOnly = $true
    $textBox.Font = New-Object System.Drawing.Font("Consolas", 10)
    $textBox.ScrollBars = [System.Windows.Forms.RichTextBoxScrollBars]::Vertical

    $panel = New-Object System.Windows.Forms.Panel
    $panel.Dock = [System.Windows.Forms.DockStyle]::Bottom
    $panel.Height = 50

    $btnYes = New-Object System.Windows.Forms.Button
    $btnYes.Text = "Yes, Commit"
    $btnYes.Width = 120
    $btnYes.Location = New-Object System.Drawing.Point(10, 10)
    $btnYes.DialogResult = [System.Windows.Forms.DialogResult]::Yes

    $btnNo = New-Object System.Windows.Forms.Button
    $btnNo.Text = "No, Cancel"
    $btnNo.Width = 120
    $btnNo.Location = New-Object System.Drawing.Point(140, 10)
    $btnNo.DialogResult = [System.Windows.Forms.DialogResult]::No

    $panel.Controls.AddRange(@($btnYes, $btnNo))
    $form.Controls.AddRange(@($textBox, $panel))
    $form.AcceptButton = $btnYes
    $form.CancelButton = $btnNo

    $result = $form.ShowDialog()

    if ($result -eq [System.Windows.Forms.DialogResult]::No) {
        exit 1
    }
	if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
		exit 0
	}
  }
exit 1
