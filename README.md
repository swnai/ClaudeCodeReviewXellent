# ClaudeCodeReviewXellent

> AI-powered pre-commit code review using Claude CLI — catch bugs and style issues before they enter your history.

![Platform](https://img.shields.io/badge/platform-Windows-blue)
![PowerShell](https://img.shields.io/badge/PowerShell-5%2B-blue)
![Claude CLI](https://img.shields.io/badge/Claude-CLI-blueviolet)
![Git Hook](https://img.shields.io/badge/git-hook-orange)

---

## What It Does

Every time you run `git commit`, the hook automatically:

1. Collects all staged files matching the configured extensions
2. Sends each diff to **Claude CLI**, asking it to review only the added lines
3. If issues are found, shows a **Windows dialog** with Claude's feedback and asks whether to proceed

No CI pipeline, no cloud setup — it runs entirely on your machine at commit time.

---

## How It Works

```
git commit
    └── pre-commit (shell)
            └── pre-commit.ps1 (PowerShell, elevated)
                    ├── git diff --cached  →  Claude CLI
                    └── issues found?
                            ├── Yes  →  WinForms dialog  →  Commit / Abort
                            └── No   →  Commit proceeds
```

**`pre-commit`** — Git invokes this automatically. It elevates and hands off to the PowerShell script:
```sh
Start-Process powershell.exe -Verb RunAs -ArgumentList '-ExecutionPolicy Bypass -NoProfile -File ".git/hooks/pre-commit.ps1"'
```

**`pre-commit.ps1`** — For each staged file with a recognised extension:
- Extracts the diff with `git diff --cached`
- Pipes it to Claude with the prompt: *"Review ONLY the added lines — suggest fixes for bugs, style issues, or unnecessary code. If nothing is wrong, respond with: LGTM"*
- Skips the file if Claude responds with `LGTM`
- Otherwise, appends the feedback to a summary

If any feedback was collected, a Windows Forms dialog appears:

> **Claude Code Review — Issues Found**
> `[file suggestions here]`
> Commit anyway? **[Yes]** / **[No]**

- **Yes** — commit proceeds
- **No** — commit is aborted (exit code 1)

---

## Requirements

| Requirement | Notes |
|-------------|-------|
| Windows | The GUI dialog uses `System.Windows.Forms` |
| PowerShell 5+ | Pre-installed on Windows 10/11 |
| [Claude CLI](https://github.com/anthropics/claude-code) (`claude`) | Must be on `PATH` |
| Git | Required for hooks to run |

---

## Installation

Download `Install_Code_Reviewer.ps1` from this repo, then run:
```powershell
$base = "https://raw.githubusercontent.com/swnai/ClaudeCodeReviewXellent/main"
Invoke-WebRequest "$base/Install_Code_Reviewer.ps1"  -OutFile "<Path>/Install_Code_Reviewer.ps1"
```

```powershell
.\Install_Code_Reviewer.ps1 -project "<path\to\your\project>"
```

This downloads `pre-commit` and `pre-commit.ps1` from GitHub directly into `<project>\.git\hooks\`. The hook is active immediately — no further setup needed.

---

## Configuration

To change which file types get reviewed, edit the `$codeExtensions` array at the top of `pre-commit.ps1`:

```powershell
$codeExtensions = @(".xml", ".cs", ".ts", ".py")
```

Files with unlisted extensions are skipped silently.

---

## Skipping the Hook

To bypass the review for a single commit:

```sh
git commit --no-verify -m "your message"
```

---

## Repository Structure

| File | Description |
|------|-------------|
| `pre-commit` | Shell entry-point placed in `.git/hooks/` |
| `pre-commit.ps1` | Core review logic (Claude CLI + WinForms dialog) |
| `Install_Code_Reviewer.ps1` | Installer — fetches hooks into a project's `.git/hooks/` |
| `Get-StagedFiles.ps1` | Dev utility — checks whether a specific file is currently staged |
