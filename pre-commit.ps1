  # .githooks/pre-commit.ps1

  $codeExtensions = @(".js", ".ts", ".py", ".go", ".java", ".cs", ".cpp", ".c", ".rb", ".rs")

  $staged = git diff --cached --name-only --diff-filter=ACM

  foreach ($file in $staged) {
      $ext = [System.IO.Path]::GetExtension($file)

      if ($ext -notin $codeExtensions) { continue }
      if (-not (Test-Path $file))      { continue }

      Write-Host ""
      Write-Host "=== Claude reviewing: $file ===" -ForegroundColor Cyan

      Get-Content $file -Raw | claude -p "Review this code and suggest improvements for bugs or style issues. Be concise. List
  suggestions as bullet points." --output-format text

      Write-Host "=================================" -ForegroundColor Cyan
  }

  Write-Host ""
  Write-Host "Claude review complete. Proceeding with commit..." -ForegroundColor Green
  exit 0