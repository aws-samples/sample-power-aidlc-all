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

During setup, the power installs an agent hook file into `.kiro/hooks/aidlc-workflow-prompt.kiro.hook`. The hook fires on every `promptSubmit` event and instructs the agent to:

1. Check if AI-DLC steering files are installed in the workspace.
2. If installed and the user hasn't been asked yet in this conversation, present a clickable choice via the `userInput` tool asking whether to use AI-DLC.
3. If the user selects "Yes, use AI-DLC" → present a second clickable phase selector to choose where to start, then activate the AI-DLC workflow from that phase.
4. If the user selects "No thanks" → proceed normally without AI-DLC.
5. Once answered, the agent remembers the choice for the rest of the conversation and does not ask again.

The hook is only meaningful when the AI-DLC steering files are present. If the power is disabled or the steering files are removed, the hook's prompt check finds no files and the agent proceeds normally.

## Canonical Hook Definition

**This is the single source of truth for the AI-DLC agent hook.** Setup scripts MUST create `.kiro/hooks/aidlc-workflow-prompt.kiro.hook` with exactly this JSON content:

```json
{
  "enabled": true,
  "name": "AI-DLC Workflow Prompt",
  "description": "Asks the user at the start of a conversation whether they want to use the AI-DLC workflow, then presents clickable phase selection options.",
  "version": "1",
  "when": {
    "type": "promptSubmit"
  },
  "then": {
    "type": "askAgent",
    "prompt": "Before proceeding with the user's request, check if AI-DLC steering files are installed in this workspace (look for .kiro/steering/aws-aidlc-rules/core-workflow.md).\n\nIf they exist and you have NOT already asked the user about AI-DLC in this conversation, present the AI-DLC choice to the user.\n\nPREFERRED: If the userInput tool is available (Spec mode), use it. Call userInput with:\n- reason: \"general-question\"\n- question: \"I see AI-DLC is set up in this workspace. Would you like to use the AI-DLC workflow for this task?\"\n- options: [{\"title\": \"Yes, use AI-DLC\", \"description\": \"Activate the AI-DLC workflow and select a starting phase\", \"recommended\": true}, {\"title\": \"No thanks\", \"description\": \"Proceed normally without AI-DLC\"}]\n\nFALLBACK: If userInput is NOT available (Vibe mode), reply with this exact markdown:\n\nI see AI-DLC is set up in this workspace. Would you like to use the AI-DLC workflow for this task?\n\n1. **Yes, use AI-DLC** — Activate the AI-DLC workflow and select a starting phase\n2. **No thanks** — Proceed normally without AI-DLC\n\nReply with the number (1 or 2) or the option name.\n\nIf the user selects \"Yes, use AI-DLC\" (or replies 1/yes), present the phase selection next.\n\nPREFERRED: Call userInput with:\n- reason: \"general-question\"\n- question: \"Which AI-DLC phase would you like to start from?\"\n- options: [{\"title\": \"Requirements analysis and validation\", \"description\": \"Gather, analyze, and validate project requirements\"}, {\"title\": \"User story creation\", \"description\": \"Create user stories and acceptance criteria\"}, {\"title\": \"Application Design\", \"description\": \"Design the application architecture\"}, {\"title\": \"Creating units of work for parallel development\", \"description\": \"Break down work into parallelizable tasks\"}, {\"title\": \"Risk assessment and complexity evaluation\", \"description\": \"Identify risks and estimate complexity\"}, {\"title\": \"Detailed component design\", \"description\": \"Design individual components and interfaces\"}, {\"title\": \"Code generation and implementation\", \"description\": \"Generate and implement code\"}, {\"title\": \"Build configuration and testing strategies\", \"description\": \"Set up build pipelines and test frameworks\"}, {\"title\": \"Quality assurance and validation\", \"description\": \"Run tests and code reviews\"}, {\"title\": \"Deployment automation and infrastructure\", \"description\": \"Automate deployment and provision infrastructure\"}, {\"title\": \"Monitoring and observability setup\", \"description\": \"Set up logging, metrics, and dashboards\"}, {\"title\": \"Production readiness validation\", \"description\": \"Final checks before going live\"}]\n\nFALLBACK (Vibe mode): Reply with this exact markdown:\n\nWhich AI-DLC phase would you like to start from?\n\n1. **Requirements analysis and validation** — Gather, analyze, and validate project requirements\n2. **User story creation** — Create user stories and acceptance criteria\n3. **Application Design** — Design the application architecture\n4. **Creating units of work for parallel development** — Break down work into parallelizable tasks\n5. **Risk assessment and complexity evaluation** — Identify risks and estimate complexity\n6. **Detailed component design** — Design individual components and interfaces\n7. **Code generation and implementation** — Generate and implement code\n8. **Build configuration and testing strategies** — Set up build pipelines and test frameworks\n9. **Quality assurance and validation** — Run tests and code reviews\n10. **Deployment automation and infrastructure** — Automate deployment and provision infrastructure\n11. **Monitoring and observability setup** — Set up logging, metrics, and dashboards\n12. **Production readiness validation** — Final checks before going live\n\nReply with the number (1-12) or the phase name.\n\nAfter the user selects a phase, follow the AI-DLC core-workflow.md steering file starting from that phase.\n\nIf the user declined AI-DLC, proceed normally.\n\nIf you have already asked in this conversation, do NOT ask again — honor their earlier choice.\n\nDo NOT mix the two formats. Use userInput OR markdown, never both for the same question."
  }
}
```

The setup scripts embed this exact JSON content and write it directly to the workspace — they do NOT read from any separate hook file. To modify the hook behavior, update the JSON embedded in the setup scripts (`setup-aidlc.sh`, `setup-aidlc.ps1`, `setup-aidlc.bat`) and keep this POWER.md in sync.

## Post-Installation Usage

After installation, the agent will proactively ask the user at the beginning of each new conversation whether they'd like to use the AI-DLC workflow for their task. No special prompt prefix is needed. When the user opts in, they are presented with a clickable phase selector to choose where to start:

1. **Requirements analysis and validation**
2. **User story creation**
3. **Application Design**
4. **Creating units of work for parallel development**
5. **Risk assessment and complexity evaluation**
6. **Detailed component design**
7. **Code generation and implementation**
8. **Build configuration and testing strategies**
9. **Quality assurance and validation**
10. **Deployment automation and infrastructure**
11. **Monitoring and observability setup**
12. **Production readiness validation**

The agent then follows the AI-DLC core workflow starting from the selected phase, guiding the user through:

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
