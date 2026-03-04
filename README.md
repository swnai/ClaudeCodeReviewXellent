# ClaudeCodeReviewXellent

> AI-powered pre-commit code review using Claude CLI — catch bugs and style issues before they enter your history.

![Platform](https://img.shields.io/badge/platform-Windows-blue)
![PowerShell](https://img.shields.io/badge/PowerShell-5%2B-blue)
![Claude CLI](https://img.shields.io/badge/Claude-CLI-blueviolet)
![Git Hook](https://img.shields.io/badge/git-hook-orange)
![D365](https://img.shields.io/badge/Dynamics_365-ready-green)

---

## What It Does

Every time you run `git commit`, the hook automatically:

1. Collects all staged files matching the configured extensions (`.xml`, `.cs`, `.xpp`)
2. Extracts Dynamics 365 object metadata (module, model, object type) from the file path
3. Runs `xppbp.exe` to collect D365 best practice findings for the changed object
4. Sends each diff — plus best practice findings — to **Claude CLI** for review
5. If issues are found, shows a **styled HTML dialog** with Claude's formatted feedback and asks whether to proceed

No CI pipeline, no cloud setup — it runs entirely on your machine at commit time.

---

## How It Works

```
git commit
    └── pre-commit (shell)
            └── pre-commit.ps1 (PowerShell)
                    └── for each staged .xml / .cs / .xpp file:
                            ├── GetD365ObjectInfo.ps1  →  module / model / object type
                            ├── git diff --cached      →  file diff
                            ├── xppbp.exe              →  best practice findings
                            └── Claude CLI (diff + findings)
                                    ├── LGTM   →  skip file
                                    └── issues →  accumulate feedback
                                            ↓
                                    ConvertTo-Html-FromMarkdown
                                            ↓
                                    WinForms WebBrowser dialog
                                            ├── Yes, Commit  →  exit 0
                                            └── No, Cancel   →  exit 1
```

**`pre-commit`** — Git invokes this automatically. It hands off to the PowerShell script:
```sh
powershell.exe -ExecutionPolicy Bypass -NoProfile -File ".git/hooks/pre-commit.ps1"
```

**`GetD365ObjectInfo.ps1`** — Called once per staged file. Parses the D365 `Metadata` folder structure to extract:
- **ModuleName** — the AX module (e.g. `MyModule`)
- **ModelName** — the model the object belongs to
- **ObjectType** — normalised type string (`class`, `table`, `form`, `enum`, etc.)

**`pre-commit.ps1`** — For each staged file with a recognised extension:
1. Calls `GetD365ObjectInfo.ps1` to resolve D365 metadata
2. Extracts the diff with `git diff --cached`
3. Runs `xppbp.exe` against the object for best practice violations
4. Pipes diff + best practice output to Claude with the prompt:
   > *"Review ONLY the changed lines — suggest fixes for bugs, style issues, or unnecessary code. Also refer to these best practice findings. Format each issue as `## <title>` separated by `---`. If nothing is wrong, respond with: LGTM"*
5. Skips the file if Claude responds with `LGTM`
6. Otherwise appends the structured feedback to a summary

If any feedback was collected, a **Markdown-to-HTML converter** renders the response into styled HTML (headings, code blocks, bold, inline code, lists, horizontal rules) and displays it in a **Windows Forms WebBrowser dialog**:

> **Claude Code Review — Issues Found**
> *(styled HTML with issue headings and code snippets)*
> **[Yes, Commit]** / **[No, Cancel]**

- **Yes, Commit** — commit proceeds (`exit 0`)
- **No, Cancel** — commit is aborted (`exit 1`)

---

## Requirements

| Requirement | Notes |
|-------------|-------|
| Windows | GUI dialog uses `System.Windows.Forms` / `WebBrowser` |
| PowerShell 5+ | Pre-installed on Windows 10/11 |
| [Claude CLI](https://github.com/anthropics/claude-code) (`claude`) | Must be on `PATH` |
| Git | Required for hooks to run |
| `xppbp.exe` | Dynamics 365 best practices analyzer at `J:\AosService\PackagesLocalDirectory\bin\` |

---

## Installation

Download `Install_Code_Reviewer.ps1` from this repo, then run:
```powershell
$base = "https://raw.githubusercontent.com/swnai/ClaudeCodeReviewXellent/main"
Invoke-WebRequest "$base/Install_Code_Reviewer.ps1" -OutFile "<Path>/Install_Code_Reviewer.ps1"
```

```powershell
.\Install_Code_Reviewer.ps1 -project "<path\to\your\project>"
```

This downloads `pre-commit`, `pre-commit.ps1`, `Get-StagedFiles.ps1`, and `GetD365ObjectInfo.ps1` from GitHub directly into `<project>\.git\hooks\`. The hook is active immediately — no further setup needed.

---

## Configuration

To change which file types get reviewed, edit the `$codeExtensions` array at the top of `pre-commit.ps1`:

```powershell
$codeExtensions = @(".xml", ".cs", ".xpp")
```

Files with unlisted extensions are skipped silently.

The path to `xppbp.exe` is hard-coded in `pre-commit.ps1`. If your D365 environment uses a different drive or path, update line 23:

```powershell
$bpCommand = "J:\AosService\PackagesLocalDirectory\bin\xppbp.exe ..."
```

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
| `pre-commit.ps1` | Core review logic — diff collection, xppbp, Claude CLI, HTML dialog |
| `GetD365ObjectInfo.ps1` | Parses D365 `Metadata` folder path to extract module, model, and object type |
| `Install_Code_Reviewer.ps1` | Installer — fetches all hook files into a project's `.git/hooks/` |
| `Get-StagedFiles.ps1` | Dev utility — checks whether a specific file is currently staged |
