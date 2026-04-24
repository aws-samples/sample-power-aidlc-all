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

## Step 5: Create the AI-DLC Agent Hooks

After verifying the installation, create two hooks using the `createHook` tool:

### Hook 1: AI-DLC Workflow Prompt

This hook detects AI-DLC and asks the user if they want to use it.

- id: `aidlc-workflow-prompt`
- name: `AI-DLC Workflow Prompt`
- description: `Asks the user at the start of a conversation whether they want to use the AI-DLC workflow.`
- eventType: `promptSubmit`
- hookAction: `askAgent`
- outputPrompt: See below.

**Hook 1 prompt text:**

```
Before proceeding with the user's request, check if AI-DLC steering files are installed in this workspace (look for .kiro/steering/aws-aidlc-rules/core-workflow.md). If they exist and you have NOT already asked the user about AI-DLC in this conversation, you MUST use the userInput tool to present the following choice. Use reason 'general-question', question 'I see AI-DLC is set up in this workspace. Would you like to use the AI-DLC workflow for this task?', and options: [{"title": "Yes, use AI-DLC", "description": "Activate the AI-DLC workflow and choose a starting phase"}, {"title": "No thanks", "description": "Proceed normally without AI-DLC"}]. Wait for the user's response. If they choose 'Yes, use AI-DLC', immediately call the userInput tool again with reason 'general-question', question 'Which AI-DLC phase would you like to start from?', and these options: [{"title": "Requirements analysis and validation", "description": "Gather, analyze, and validate project requirements"}, {"title": "User story creation", "description": "Create user stories and acceptance criteria from requirements"}, {"title": "Application Design", "description": "Design the application architecture and component interactions"}, {"title": "Creating units of work for parallel development", "description": "Break down work into parallelizable tasks and assignments"}, {"title": "Risk assessment and complexity evaluation", "description": "Identify risks, dependencies, and estimate complexity"}, {"title": "Detailed component design", "description": "Design individual components, interfaces, and data models"}, {"title": "Code generation and implementation", "description": "Generate and implement code based on the design"}, {"title": "Build configuration and testing strategies", "description": "Set up build pipelines, test frameworks, and CI/CD"}, {"title": "Quality assurance and validation", "description": "Run tests, code reviews, and quality checks"}, {"title": "Deployment automation and infrastructure", "description": "Automate deployment and provision infrastructure"}, {"title": "Monitoring and observability setup", "description": "Set up logging, metrics, alerts, and dashboards"}, {"title": "Production readiness validation", "description": "Final checks before going live — security, performance, runbooks"}]. After the user selects a phase, follow the AI-DLC core-workflow.md steering file starting from that phase. If the user chose 'No thanks', proceed normally. If you have already asked in this conversation, do NOT ask again.
```

This hook fires on every `promptSubmit` event. It is only meaningful when the AI-DLC steering files are present in the workspace, so it naturally becomes inactive if the power is removed.

## Step 6: Next Steps

Let the user know that AI-DLC is now installed and the agent hook is active. Explain that the agent will automatically ask at the beginning of each new conversation whether they'd like to use the AI-DLC workflow. If they opt in, they'll see a clickable list of phases to choose where to start. If they decline, the agent proceeds normally.
