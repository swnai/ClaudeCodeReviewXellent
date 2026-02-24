# Git Hooks — AI-Powered Pre-Commit Code Review

## Overview

These hooks run an automated Claude code review on every `git commit`, catching bugs and style issues **before** they enter your history.

---

## Files

| File | Purpose |
|------|---------|
| `pre-commit` | Shell entry-point (POSIX sh). Delegates to the PowerShell script. |
| `pre-commit.ps1` | Core logic. Calls Claude CLI to review staged changes. |

---

## How It Works

1. **`pre-commit`** — Git calls this shell script automatically on `git commit`.
   It forwards execution to `pre-commit.ps1` via:
   ```sh
   powershell.exe -ExecutionPolicy Bypass -NoProfile -File ".git/hooks/pre-commit.ps1"
   ```

2. **`pre-commit.ps1`** — For each staged file with a recognised code extension:
   - Extracts the staged diff (`git diff --cached`).
   - Sends the diff to the **Claude CLI** using the `@CSharpCodeReviewer` prompt, asking it to review only added lines (`+`).
   - If Claude responds with anything other than `LGTM`, the feedback is collected.

3. **Interactive prompt** — If any issues are found across all staged files, a Windows Forms message box appears showing all suggestions and asks:
   > **Commit anyway?** `[Yes]` / `[No]`
   - **Yes** — the commit proceeds.
   - **No** — the commit is aborted (exit code 1), giving you a chance to address the feedback.

---

## Supported File Extensions

`.js` `.ts` `.py` `.go` `.java` `.cs` `.cpp` `.c` `.rb` `.rs`

Files with other extensions are skipped silently.

---

## Requirements

| Requirement | Notes |
|-------------|-------|
| Windows | The GUI dialog uses `System.Windows.Forms` |
| PowerShell 5+ | Pre-installed on Windows 10/11 |
| [Claude CLI](https://github.com/anthropics/claude-code) (`claude`) | Must be on `PATH` |
| Git | Standard requirement for any git hook |

---

## Installation

Run the following command, replacing `<project_name>` with your project folder name, to download both hook files directly into the project's `.git/hooks/`:

**PowerShell (Windows)**
```powershell
$project = "<project_name>"
$base    = "https://raw.githubusercontent.com/swnai/ClaudeCodeReviewXellent/main"
Invoke-WebRequest "$base/pre-commit"     -OutFile "$project/.git/hooks/pre-commit"
Invoke-WebRequest "$base/pre-commit.ps1" -OutFile "$project/.git/hooks/pre-commit.ps1"
```

**bash / Git Bash**
```sh
PROJECT="<project_name>"
BASE="https://raw.githubusercontent.com/swnai/ClaudeCodeReviewXellent/main"
curl -fsSL "$BASE/pre-commit"     -o "$PROJECT/.git/hooks/pre-commit"
curl -fsSL "$BASE/pre-commit.ps1" -o "$PROJECT/.git/hooks/pre-commit.ps1"
chmod +x "$PROJECT/.git/hooks/pre-commit"
```

The hooks take effect immediately after the files are in place — no further configuration needed.

---

## Disabling the Hook Temporarily

Skip the hook for a single commit:

```sh
git commit --no-verify -m "your message"
```
