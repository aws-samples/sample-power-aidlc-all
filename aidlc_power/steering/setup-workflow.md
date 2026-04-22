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

Run the appropriate setup script:

- macOS/Linux: `bash <power-path>/scripts/setup-aidlc.sh "<workspace-root>"`
- Windows PowerShell: `powershell -ExecutionPolicy Bypass -File "<power-path>\scripts\setup-aidlc.ps1" -WorkspacePath "<workspace-root>"`
- Windows CMD: `<power-path>\scripts\setup-aidlc.bat "<workspace-root>"`

The script will:
1. Query the GitHub API for the latest AI-DLC release
2. Download the release zip to a temp directory
3. Extract the contents
4. Copy `aws-aidlc-rules/` → `.kiro/steering/aws-aidlc-rules/`
5. Copy `aws-aidlc-rule-details/` → `.kiro/aws-aidlc-rule-details/`
6. Clean up temp files
7. Print the installed version

## Step 4: Verify

After setup completes, confirm the key files exist:

- `.kiro/steering/aws-aidlc-rules/core-workflow.md`
- `.kiro/aws-aidlc-rule-details/` with subdirectories

Tell the user to check the Kiro steering panel for `core-workflow` under Workspace.

## Step 5: Create the AI-DLC Agent Hook

After verifying the installation, use the `createHook` tool to register the AI-DLC prompt hook in Kiro. Use these exact parameters:

- id: `aidlc-workflow-prompt`
- name: `AI-DLC Workflow Prompt`
- description: `Asks the user at the start of a conversation whether they want to use the AI-DLC workflow for their task.`
- eventType: `promptSubmit`
- hookAction: `askAgent`
- outputPrompt: `Before proceeding with the user's request, check if AI-DLC steering files are installed in this workspace (look for .kiro/steering/aws-aidlc-rules/core-workflow.md). If they exist and you have NOT already asked the user about AI-DLC in this conversation, ask the user: 'I see AI-DLC is set up in this workspace. Would you like to use the AI-DLC workflow for this task?' If the user says yes, follow the AI-DLC core-workflow.md steering file. If the user says no, proceed normally without AI-DLC. If you have already asked and received an answer in this conversation, do NOT ask again — just honor their earlier choice.`

This hook fires on every `promptSubmit` event. It is only meaningful when the AI-DLC steering files are present in the workspace, so it naturally becomes inactive if the power is removed.

## Step 6: Next Steps

Let the user know that AI-DLC is now installed and the agent hook is active. Explain that the agent will automatically ask at the beginning of each new conversation whether they'd like to use the AI-DLC workflow — no special prompt prefix is needed. If they decline, the agent proceeds normally.
