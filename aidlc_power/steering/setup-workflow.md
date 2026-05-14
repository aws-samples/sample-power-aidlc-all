# AI-DLC Setup Workflow

Follow these steps when the user asks to set up AI-DLC in their Kiro workspace.

## Step 1: Detect the Platform

Determine the operating system by checking the system context or running:

- macOS/Linux: `uname -s`
- Windows: The shell will be PowerShell or CMD

On Windows, detect the available shell:
- Try `powershell -Command "echo ps"` — if it succeeds, use the `.ps1` script
- Otherwise fall back to the `.bat` script

## Step 2: Check Existing Installation

Run the appropriate check script from this power's `scripts/` directory:

- macOS/Linux: `bash <power-path>/scripts/check-aidlc.sh "<workspace-root>"`
- Windows: `<power-path>\scripts\check-aidlc.bat "<workspace-root>"`

If already installed, inform the user and ask if they want to update (re-run setup) or keep the current version.

## Step 3: Run Setup

**IMPORTANT**: Always pass the absolute power path as the second argument. This ensures the power's own steering files (enforcement rules) are copied correctly, regardless of how the script is invoked.

Run the appropriate setup script:

- macOS/Linux: `bash "<power-path>/scripts/setup-aidlc.sh" "<workspace-root>" "<power-path>"`
- Windows PowerShell: `powershell -ExecutionPolicy Bypass -File "<power-path>\scripts\setup-aidlc.ps1" -WorkspacePath "<workspace-root>" -PowerPath "<power-path>"`
- Windows CMD: `"<power-path>\scripts\setup-aidlc.bat" "<workspace-root>" "<power-path>"`

The script will:
1. Query the GitHub API for the latest AI-DLC release
2. Download the release zip to a temp directory inside the workspace
3. Extract the contents
4. Copy `aws-aidlc-rules/` → `.kiro/steering/aws-aidlc-rules/`
5. Copy `aws-aidlc-rule-details/` → `.kiro/aws-aidlc-rule-details/`
6. Copy this power's `steering/aidlc-*.md` files → `.kiro/steering/` (enforcement rules)
7. Write the canonical agent hook (embedded in the script, defined in POWER.md) → `.kiro/hooks/aidlc-workflow-prompt.kiro.hook`
8. Clean up temp files
9. Print the installed version

If the script output shows "WARNING: Power steering directory not found" or "WARNING: No aidlc-*.md files found", the power path was not resolved correctly. Re-run with the explicit `<power-path>` argument.

## Step 4: Verify

After setup completes, confirm the key files exist:

- `.kiro/steering/aws-aidlc-rules/core-workflow.md`
- `.kiro/aws-aidlc-rule-details/` with subdirectories
- `.kiro/steering/aidlc-userinput-enforcement.md` (always-included enforcement rules)
- `.kiro/hooks/aidlc-workflow-prompt.kiro.hook`

Tell the user to check the Kiro steering panel for `core-workflow` under Workspace.

## Step 5: Agent Hook

The hook content is embedded directly in each setup script (`setup-aidlc.sh`, `.ps1`, `.bat`). The canonical definition lives in `POWER.md` under the "Canonical Hook Definition" section.

**To modify hook behavior:**
1. Update the JSON in `POWER.md` (canonical source)
2. Sync the embedded content in all three setup scripts (the `.bat` script uses a base64-encoded copy of the same JSON)
3. Re-run setup in the user's workspace

The hook fires on `promptSubmit` and:
1. Asks the user (via `userInput` in Spec mode or markdown in Vibe mode) whether to use AI-DLC.
2. If yes, silently runs workspace detection per `.kiro/aws-aidlc-rule-details/inception/workspace-detection.md` to classify the project as **greenfield** or **brownfield**.
3. Presents the phase list tailored to the detected type — greenfield shows 12 phases, brownfield shows 13 with **Reverse Engineering** on top.

## Step 6: Next Steps

Let the user know that AI-DLC is now installed and the agent hook is active. Explain that at the beginning of each new conversation the agent will:
- Ask whether to use the AI-DLC workflow.
- If yes, detect whether the workspace is greenfield or brownfield.
- Present a phase selector appropriate to the detected type (brownfield includes **Reverse Engineering** as phase 1).

If they decline, the agent proceeds normally.
