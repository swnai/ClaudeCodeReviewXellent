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

function Format-InlineMd($text) {
    # HtmlEncode first so < > & are safe, then apply markdown inline patterns
    $text = [System.Web.HttpUtility]::HtmlEncode($text)
    $text = $text -replace '\*\*(.+?)\*\*', '<strong>$1</strong>'
    $text = $text -replace '__(.+?)__',      '<strong>$1</strong>'
    $text = $text -replace '\*(.+?)\*',      '<em>$1</em>'
    $text = $text -replace '_(.+?)_',        '<em>$1</em>'
    $text = $text -replace '`(.+?)`',        '<code>$1</code>'
    return $text
}

function ConvertTo-Html-FromMarkdown($markdown) {
    # Normalize CRLF and CR to LF before splitting so no stray \r remains on lines
    $lines  = ($markdown -replace "`r`n", "`n" -replace "`r", "`n") -split "`n"
    $sb     = [System.Text.StringBuilder]::new()
    $inCode = $false
    $inUL   = $false
    $inOL   = $false

    foreach ($rawLine in $lines) {
        $l = $rawLine.TrimEnd()   # strips any remaining \r or trailing spaces

        # --- fenced code block toggle ---
        if ($l -match '^```') {
            if ($inCode) {
                [void]$sb.Append("</code></pre>`n")
                $inCode = $false
            } else {
                if ($inUL) { [void]$sb.Append("</ul>`n"); $inUL = $false }
                if ($inOL) { [void]$sb.Append("</ol>`n"); $inOL = $false }
                [void]$sb.Append("<pre><code>")
                $inCode = $true
            }
            continue
        }
        if ($inCode) {
            [void]$sb.Append([System.Web.HttpUtility]::HtmlEncode($l) + "`n")
            continue
        }

        # --- === file separator === ---
        if ($l -match '^=== (.+) ===$') {
            if ($inUL) { [void]$sb.Append("</ul>`n"); $inUL = $false }
            if ($inOL) { [void]$sb.Append("</ol>`n"); $inOL = $false }
            [void]$sb.Append("<h1 class='file-hdr'>$(Format-InlineMd $Matches[1])</h1>`n")
            continue
        }

        # --- ATX headings: #, ##, ### ... ###### ---
        if ($l -match '^(#{1,6})\s+(.+)') {
            if ($inUL) { [void]$sb.Append("</ul>`n"); $inUL = $false }
            if ($inOL) { [void]$sb.Append("</ol>`n"); $inOL = $false }
            $n = $Matches[1].Length
            [void]$sb.Append("<h$n>$(Format-InlineMd $Matches[2].TrimEnd())</h$n>`n")
            continue
        }

        # --- horizontal rule ---
        if ($l -match '^-{3,}$' -or $l -match '^\*{3,}$') {
            if ($inUL) { [void]$sb.Append("</ul>`n"); $inUL = $false }
            if ($inOL) { [void]$sb.Append("</ol>`n"); $inOL = $false }
            [void]$sb.Append("<hr/>`n")
            continue
        }

        # --- unordered list: - / * / + ---
        if ($l -match '^[-*+]\s+(.+)') {
            if ($inOL) { [void]$sb.Append("</ol>`n"); $inOL = $false }
            if (-not $inUL) { [void]$sb.Append("<ul>`n"); $inUL = $true }
            [void]$sb.Append("<li>$(Format-InlineMd $Matches[1].TrimEnd())</li>`n")
            continue
        }

        # --- ordered list: 1. 2. etc. ---
        if ($l -match '^\d+\.\s+(.+)') {
            if ($inUL) { [void]$sb.Append("</ul>`n"); $inUL = $false }
            if (-not $inOL) { [void]$sb.Append("<ol>`n"); $inOL = $true }
            [void]$sb.Append("<li>$(Format-InlineMd $Matches[1].TrimEnd())</li>`n")
            continue
        }

        # close any open list before paragraph/blank content
        if ($inUL) { [void]$sb.Append("</ul>`n"); $inUL = $false }
        if ($inOL) { [void]$sb.Append("</ol>`n"); $inOL = $false }

        if ($l.Trim() -eq "") {
            [void]$sb.Append("<br/>`n")
            continue
        }

        [void]$sb.Append("<p>$(Format-InlineMd $l.Trim())</p>`n")
    }

    if ($inUL)  { [void]$sb.Append("</ul>`n") }
    if ($inOL)  { [void]$sb.Append("</ol>`n") }
    if ($inCode){ [void]$sb.Append("</code></pre>`n") }
    return $sb.ToString()
}

if ($allSuggestions -ne "") {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    Add-Type -AssemblyName System.Web

    $bodyHtml = ConvertTo-Html-FromMarkdown $allSuggestions

    $fullHtml = @"
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8"/>
  <meta http-equiv="X-UA-Compatible" content="IE=edge"/>
  <style>
    body        { font-family: Segoe UI, Arial, sans-serif; font-size: 13px; margin: 24px; color: #1a1a1a; line-height: 1.6; }
    h1.file-hdr { font-size: 1.1em; background: #0078d4; color: #fff; padding: 6px 12px; border-radius: 4px; margin: 24px 0 8px; }
    h1          { font-size: 1.5em; border-bottom: 2px solid #0078d4; padding-bottom: 4px; margin-top: 20px; }
    h2          { font-size: 1.25em; border-bottom: 1px solid #ccc; padding-bottom: 3px; margin-top: 16px; }
    h3          { font-size: 1.05em; margin-top: 12px; }
    p           { margin: 6px 0; }
    ul, ol      { padding-left: 24px; margin: 6px 0; }
    li          { margin: 3px 0; }
    pre         { background: #f5f5f5; border: 1px solid #ddd; padding: 10px 14px; border-radius: 4px; overflow-x: auto; font-family: Consolas, monospace; font-size: 12px; }
    code        { background: #f0f0f0; padding: 1px 5px; border-radius: 3px; font-family: Consolas, monospace; font-size: 12px; }
    pre code    { background: none; padding: 0; }
    hr          { border: none; border-top: 1px solid #ddd; margin: 16px 0; }
    strong      { font-weight: 600; }
  </style>
</head>
<body>
$bodyHtml
<hr/><p><strong>Commit anyway?</strong></p>
</body>
</html>
"@

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Claude Code Review - Issues Found"
    $form.WindowState = [System.Windows.Forms.FormWindowState]::Maximized
    $form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen

    $browser = New-Object System.Windows.Forms.WebBrowser
    $browser.Dock = [System.Windows.Forms.DockStyle]::Fill
    $browser.ScrollBarsEnabled = $true
    $browser.DocumentText = $fullHtml

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
    $form.Controls.AddRange(@($browser, $panel))
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
