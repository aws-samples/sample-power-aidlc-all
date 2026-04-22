---
name: "aidlc-setup"
displayName: "AI-DLC Setup for Kiro"
description: "Download and configure AI-DLC (AI-Driven Development Life Cycle) steering files in your Kiro workspace. Works cross-platform on macOS, Linux, and Windows (PowerShell or CMD)."
keywords: ["aidlc", "ai-dlc", "ai-driven", "development lifecycle", "steering", "workflow", "setup", "adaptive workflow"]
author: "Community"
---

# AI-DLC Setup Power for Kiro

## Overview

This power automates the setup of [AI-DLC](https://github.com/awslabs/aidlc-workflows) steering files in your Kiro workspace. AI-DLC is an intelligent software development workflow from AWS that adapts to your needs, maintains quality standards, and keeps you in control.

The power ships with cross-platform shell scripts that handle downloading the latest release, extracting it, and placing the steering files in the correct Kiro directory structure. It works on macOS, Linux, and Windows (auto-detects PowerShell vs CMD).

## When to Load Steering Files

- Setting up AI-DLC or asking about AI-DLC installation → `setup-workflow.md`

## Scripts

The `scripts/` directory contains:

| Script | Platform | Description |
|--------|----------|-------------|
| `setup-aidlc.sh` | macOS / Linux | Downloads latest AI-DLC release and installs Kiro steering files |
| `setup-aidlc.ps1` | Windows (PowerShell) | Same functionality for PowerShell |
| `setup-aidlc.bat` | Windows (CMD) | Same functionality for CMD prompt |
| `check-aidlc.sh` | macOS / Linux | Checks if AI-DLC is already installed |
| `check-aidlc.bat` | Windows | Checks if AI-DLC is already installed |
| `remove-aidlc.sh` | macOS / Linux | Removes AI-DLC steering files |
| `remove-aidlc.bat` | Windows | Removes AI-DLC steering files |

## Onboarding

When the user asks to set up AI-DLC, read the `setup-workflow.md` steering file for the step-by-step guided workflow. The workflow will:

1. Detect the operating system
2. Check if AI-DLC is already installed
3. Run the appropriate platform script to download and install
4. Verify the installation

## Agent Behavior — Proactive AI-DLC Prompt

During setup, the agent registers a Kiro agent hook (via `createHook`) that fires on every `promptSubmit` event. The hook instructs the agent to:

1. Check if AI-DLC steering files are installed in the workspace.
2. If installed and the user hasn't been asked yet in this conversation, ask: *"I see AI-DLC is set up in this workspace. Would you like to use the AI-DLC workflow for this task?"*
3. If the user says yes → activate the AI-DLC workflow as defined in `core-workflow.md`.
4. If the user says no → proceed normally without AI-DLC.
5. Once answered, the agent remembers the choice for the rest of the conversation and does not ask again.

The hook is only meaningful when the AI-DLC steering files are present. If the power is disabled or the steering files are removed, the hook's prompt check finds no files and the agent proceeds normally.

## Post-Installation Usage

After installation, the agent will proactively ask the user at the beginning of each new conversation whether they'd like to use the AI-DLC workflow for their task. No special prompt prefix is needed. When the user opts in, the AI-DLC workflow activates and guides them through:

1. **Inception Phase** — Determines WHAT to build and WHY
2. **Construction Phase** — Determines HOW to build it
3. **Operations Phase** — Deployment and monitoring

## Expected Directory Structure

```
<project-root>/
├── .kiro/
│   ├── steering/
│   │   └── aws-aidlc-rules/
│   │       └── core-workflow.md
│   └── aws-aidlc-rule-details/
│       ├── common/
│       ├── inception/
│       ├── construction/
│       ├── extensions/
│       └── operations/
```

## Troubleshooting

### Network errors during download
- Verify internet connectivity
- Check access to `https://api.github.com` and `https://github.com`
- If behind a corporate proxy, set `HTTPS_PROXY` / `https_proxy`

### Steering files not visible in Kiro
- Restart Kiro or open a new chat session
- Confirm `.kiro/steering/aws-aidlc-rules/core-workflow.md` exists

### Windows: "execution of scripts is disabled"
- Run: `Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned`
- Or use the `.bat` script instead

### Updating AI-DLC
Re-run the setup script. It overwrites existing files with the latest release.
