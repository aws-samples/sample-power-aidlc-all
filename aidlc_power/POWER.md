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
3. If the user selects "Yes, use AI-DLC" → run **workspace detection** per `.kiro/aws-aidlc-rule-details/inception/workspace-detection.md` to determine whether the project is **greenfield** (no existing source/build files) or **brownfield** (existing code found).
4. Present the appropriate clickable phase selector:
   - **Greenfield** → 12 phases starting at _Requirements analysis and validation_.
   - **Brownfield** → 13 phases with **Reverse Engineering** added at the top, then the 12 standard phases.
5. After the user picks a phase, **silently scan the entire workspace** (not just `aidlc-docs/`) for artifacts that could inform earlier phases. The scan covers:
   - AI-DLC canonical artifacts under `aidlc-docs/`
   - Workspace-root docs (`README.md`, `ARCHITECTURE.md`, `DESIGN.md`, `REQUIREMENTS.md`, `ROADMAP.md`, RFCs, PRDs, etc.)
   - Generic doc directories (`docs/`, `documentation/`, `specs/`, `design/`, `architecture/`)
   - ADRs (`docs/adr/`, `architecture/decisions/`)
   - API specs (OpenAPI/Swagger, Protobuf, GraphQL schemas)
   - Existing Kiro specs under `.kiro/specs/`
   - Threat models and security docs (`.threatmodel/`, `SECURITY.md`)
   - Build/test/CI configs (`Dockerfile`, `.github/workflows/`, `Jenkinsfile`, package manifests)
   - Infrastructure-as-code (`terraform/`, `cdk/`, `k8s/`, `helm/`)
   - Source code, tests, monitoring, runbooks
   The agent reads what exists, summarizes briefly to the user, and uses it to inform the chosen phase. Common build/cache/vendor directories are excluded. No backfill prompt — the agent simply proceeds with whatever context is available.
6. Activate the AI-DLC workflow from the selected phase, leaning on the gathered context.
7. If the user selects "No thanks" → proceed normally without AI-DLC.
8. Once answered, the agent remembers the choice for the rest of the conversation and does not ask again.

The hook is only meaningful when the AI-DLC steering files are present. If the power is disabled or the steering files are removed, the hook's prompt check finds no files and the agent proceeds normally.

## Canonical Hook Definition

**This is the single source of truth for the AI-DLC agent hook.** Setup scripts MUST create `.kiro/hooks/aidlc-workflow-prompt.kiro.hook` with exactly this JSON content:

```json
{
  "enabled": true,
  "name": "AI-DLC Workflow Prompt",
  "description": "Asks the user at the start of a conversation whether they want to use the AI-DLC workflow, runs workspace detection (greenfield vs brownfield), presents clickable phase selection, gathers context from earlier-phase artifacts across the entire workspace, then proceeds.",
  "version": "1",
  "when": {
    "type": "promptSubmit"
  },
  "then": {
    "type": "askAgent",
    "prompt": "Before proceeding with the user's request, check if AI-DLC steering files are installed in this workspace (look for .kiro/steering/aws-aidlc-rules/core-workflow.md).\n\nIf they exist and you have NOT already asked the user about AI-DLC in this conversation, present the AI-DLC choice to the user.\n\n== STEP 1: Ask Yes/No ==\n\nPREFERRED: If the userInput tool is available (Spec mode), use it. Call userInput with:\n- reason: \"general-question\"\n- question: \"I see AI-DLC is set up in this workspace. Would you like to use the AI-DLC workflow for this task?\"\n- options: [{\"title\": \"Yes, use AI-DLC\", \"description\": \"Activate the AI-DLC workflow and select a starting phase\", \"recommended\": true}, {\"title\": \"No thanks\", \"description\": \"Proceed normally without AI-DLC\"}]\n\nFALLBACK: If userInput is NOT available (Vibe mode), reply with this exact markdown:\n\nI see AI-DLC is set up in this workspace. Would you like to use the AI-DLC workflow for this task?\n\n1. **Yes, use AI-DLC** - Activate the AI-DLC workflow and select a starting phase\n2. **No thanks** - Proceed normally without AI-DLC\n\nReply with the number (1 or 2) or the option name.\n\n== STEP 2: Workspace Detection (only if user chose Yes) ==\n\nIf the user selected \"Yes, use AI-DLC\" (or replied 1/yes), DO NOT present the phase list yet. First run workspace detection by loading and following .kiro/aws-aidlc-rule-details/inception/workspace-detection.md. Silently scan the workspace for existing source code files (.java, .py, .js, .ts, .jsx, .tsx, .kt, .kts, .scala, .groovy, .go, .rs, .rb, .php, .c, .h, .cpp, .hpp, .cc, .cs, .fs) and build files (pom.xml, package.json, build.gradle, Cargo.toml, go.mod, Gemfile, requirements.txt, pyproject.toml, etc.), excluding the .kiro and aidlc-docs directories. Do NOT ask the user - detect automatically.\n\n- If NO source or build files are found outside .kiro and aidlc-docs: project_type = greenfield\n- If source or build files are found: project_type = brownfield\n\n== STEP 3: Present phase selection for the detected type ==\n\nFor GREENFIELD: present 12 phases starting with \"Requirements analysis and validation\".\nFor BROWNFIELD: present 13 phases with \"Reverse Engineering\" as phase 1.\n\nPREFERRED (Spec mode): Call userInput with:\n- reason: \"general-question\"\n- question: \"Detected <greenfield|brownfield> project. Which AI-DLC phase would you like to start from?\" (substitute the detected type)\n- options for GREENFIELD: [{\"title\": \"Requirements analysis and validation\", \"description\": \"Gather, analyze, and validate project requirements\", \"recommended\": true}, {\"title\": \"User story creation\", \"description\": \"Create user stories and acceptance criteria\"}, {\"title\": \"Application Design\", \"description\": \"Design the application architecture\"}, {\"title\": \"Creating units of work for parallel development\", \"description\": \"Break down work into parallelizable tasks\"}, {\"title\": \"Risk assessment and complexity evaluation\", \"description\": \"Identify risks and estimate complexity\"}, {\"title\": \"Detailed component design\", \"description\": \"Design individual components and interfaces\"}, {\"title\": \"Code generation and implementation\", \"description\": \"Generate and implement code\"}, {\"title\": \"Build configuration and testing strategies\", \"description\": \"Set up build pipelines and test frameworks\"}, {\"title\": \"Quality assurance and validation\", \"description\": \"Run tests and code reviews\"}, {\"title\": \"Deployment automation and infrastructure\", \"description\": \"Automate deployment and provision infrastructure\"}, {\"title\": \"Monitoring and observability setup\", \"description\": \"Set up logging, metrics, and dashboards\"}, {\"title\": \"Production readiness validation\", \"description\": \"Final checks before going live\"}]\n- options for BROWNFIELD: [{\"title\": \"Reverse Engineering\", \"description\": \"Analyze existing codebase to reconstruct requirements, architecture, and design artifacts\", \"recommended\": true}, {\"title\": \"Requirements analysis and validation\", \"description\": \"Gather, analyze, and validate project requirements\"}, {\"title\": \"User story creation\", \"description\": \"Create user stories and acceptance criteria\"}, {\"title\": \"Application Design\", \"description\": \"Design the application architecture\"}, {\"title\": \"Creating units of work for parallel development\", \"description\": \"Break down work into parallelizable tasks\"}, {\"title\": \"Risk assessment and complexity evaluation\", \"description\": \"Identify risks and estimate complexity\"}, {\"title\": \"Detailed component design\", \"description\": \"Design individual components and interfaces\"}, {\"title\": \"Code generation and implementation\", \"description\": \"Generate and implement code\"}, {\"title\": \"Build configuration and testing strategies\", \"description\": \"Set up build pipelines and test frameworks\"}, {\"title\": \"Quality assurance and validation\", \"description\": \"Run tests and code reviews\"}, {\"title\": \"Deployment automation and infrastructure\", \"description\": \"Automate deployment and provision infrastructure\"}, {\"title\": \"Monitoring and observability setup\", \"description\": \"Set up logging, metrics, and dashboards\"}, {\"title\": \"Production readiness validation\", \"description\": \"Final checks before going live\"}]\n\nFALLBACK (Vibe mode):\n\nIf GREENFIELD, reply with this exact markdown:\n\nDetected: Greenfield project (no existing code).\n\nWhich AI-DLC phase would you like to start from?\n\n1. **Requirements analysis and validation** - Gather, analyze, and validate project requirements\n2. **User story creation** - Create user stories and acceptance criteria\n3. **Application Design** - Design the application architecture\n4. **Creating units of work for parallel development** - Break down work into parallelizable tasks\n5. **Risk assessment and complexity evaluation** - Identify risks and estimate complexity\n6. **Detailed component design** - Design individual components and interfaces\n7. **Code generation and implementation** - Generate and implement code\n8. **Build configuration and testing strategies** - Set up build pipelines and test frameworks\n9. **Quality assurance and validation** - Run tests and code reviews\n10. **Deployment automation and infrastructure** - Automate deployment and provision infrastructure\n11. **Monitoring and observability setup** - Set up logging, metrics, and dashboards\n12. **Production readiness validation** - Final checks before going live\n\nReply with the number (1-12) or the phase name.\n\nIf BROWNFIELD, reply with this exact markdown:\n\nDetected: Brownfield project (existing code found).\n\nWhich AI-DLC phase would you like to start from?\n\n1. **Reverse Engineering** - Analyze existing codebase to reconstruct requirements, architecture, and design artifacts\n2. **Requirements analysis and validation** - Gather, analyze, and validate project requirements\n3. **User story creation** - Create user stories and acceptance criteria\n4. **Application Design** - Design the application architecture\n5. **Creating units of work for parallel development** - Break down work into parallelizable tasks\n6. **Risk assessment and complexity evaluation** - Identify risks and estimate complexity\n7. **Detailed component design** - Design individual components and interfaces\n8. **Code generation and implementation** - Generate and implement code\n9. **Build configuration and testing strategies** - Set up build pipelines and test frameworks\n10. **Quality assurance and validation** - Run tests and code reviews\n11. **Deployment automation and infrastructure** - Automate deployment and provision infrastructure\n12. **Monitoring and observability setup** - Set up logging, metrics, and dashboards\n13. **Production readiness validation** - Final checks before going live\n\nReply with the number (1-13) or the phase name.\n\n== STEP 4: Context Gathering (silent, no user prompt) ==\n\nAfter the user picks a phase, but BEFORE executing it, silently scan the WHOLE workspace for artifacts that could inform earlier phases. Do NOT prompt the user. Do NOT ask whether to backfill. Just absorb whatever exists.\n\nIf the user picked phase N, the prior phases are 1..N-1. If N == 1, skip this step.\n\n4.1 SCAN LOCATIONS\n\nLook EVERYWHERE in the workspace, not only aidlc-docs/. Specifically:\n\nA. AI-DLC canonical location:\n   - aidlc-docs/inception/reverse-engineering/\n   - aidlc-docs/inception/requirements/\n   - aidlc-docs/inception/user-stories/\n   - aidlc-docs/inception/design/\n   - aidlc-docs/construction/units-of-work/\n   - aidlc-docs/construction/risk-assessment/\n   - aidlc-docs/construction/component-design/\n   - aidlc-docs/construction/code-generation/\n   - aidlc-docs/construction/build-config/\n   - aidlc-docs/construction/qa/\n   - aidlc-docs/operations/deployment/\n   - aidlc-docs/operations/monitoring/\n   - aidlc-docs/operations/production-readiness/\n   - aidlc-docs/aidlc-state.md (current state, if present)\n\nB. Workspace root markdown documents:\n   - README.md, ARCHITECTURE.md, DESIGN.md, REQUIREMENTS.md, ROADMAP.md, CHANGELOG.md, CONTRIBUTING.md, SECURITY.md, RFC*.md, PRD*.md\n\nC. Generic documentation directories (workspace-relative):\n   - docs/, documentation/, doc/, specs/, spec/, design/, architecture/, requirements/, rfcs/, prds/, user-stories/\n   - Any markdown, AsciiDoc (.adoc), or reStructuredText (.rst) files within these\n\nD. Architecture decision records:\n   - docs/adr/, architecture/decisions/, adr/, decisions/\n\nE. API and interface specs:\n   - openapi.yaml, openapi.yml, swagger.yaml, swagger.json, *.openapi.yaml\n   - schema.graphql, *.proto, *.thrift, *.avsc\n   - api/, schema/, schemas/, interfaces/\n\nF. Kiro-specific artifacts:\n   - .kiro/specs/ (existing Kiro specs - very high value as design context)\n   - .kiro/steering/ (project standards)\n\nG. Threat models and security:\n   - .threatmodel/, threat-model/, security/, SECURITY.md\n\nH. Build, test, and deployment configs (especially relevant for phases 8, 10, 11, 12):\n   - package.json, pom.xml, build.gradle, Cargo.toml, go.mod, pyproject.toml, requirements.txt, Gemfile, *.csproj\n   - Dockerfile, docker-compose*.yml, .dockerignore\n   - .github/workflows/, .gitlab-ci.yml, Jenkinsfile, azure-pipelines.yml, buildspec.yml\n   - terraform/, cdk/, cloudformation/, infra/, infrastructure/, deploy/, k8s/, kubernetes/, helm/\n   - Makefile, Taskfile.yml\n\nI. Source code (brownfield context, especially relevant for phases 1, 6, 7, 9):\n   - src/, lib/, app/, packages/, services/, components/, modules/, cmd/, internal/, pkg/\n   - Read enough to identify modules, public interfaces, frameworks, and entry points; do not exhaustively read every file\n\nJ. Tests (relevant for phases 9, 12):\n   - tests/, test/, __tests__/, spec/, e2e/, integration-tests/\n\nK. Operations and observability (relevant for phases 10, 11, 12):\n   - monitoring/, observability/, dashboards/, alerts/, runbooks/, sre/, ops/\n\n4.2 EXCLUSIONS\n\nNever scan or read: node_modules/, vendor/, .git/, dist/, build/, target/, out/, .next/, .nuxt/, .venv/, venv/, __pycache__/, .pytest_cache/, .mypy_cache/, coverage/, .idea/, .vscode/ (unless explicitly relevant), generated/, .terraform/, .gradle/, .cache/. Skip lockfiles and binary assets. Skip files larger than ~200KB unless they are clearly authoritative specs.\n\n4.3 EXTRACT KEY FACTS\n\nFor each phase 1..N-1, classify what was found:\n- Which scan locations contributed evidence (e.g., \"requirements: aidlc-docs/inception/requirements/, README.md, docs/requirements.md\")\n- Key facts captured: project goals, requirements, user stories, architecture decisions, components, units of work, risks, build/test setup, deploy targets, monitoring tools\n- Gaps where no evidence was found\n\nMap evidence to phases (a single document can inform multiple phases):\n- README, PRD, RFCs, requirements/* -> Requirements analysis\n- user-stories/, stories/, *.story.md -> User story creation\n- ARCHITECTURE.md, design/, architecture/, ADRs, OpenAPI/proto -> Application Design and Detailed component design\n- units-of-work/, project boards, ROADMAP.md -> Units of work\n- threat models, SECURITY.md, risk-assessment/ -> Risk assessment\n- src/, lib/, app/ -> Code generation\n- build configs, CI files, Dockerfile, package manifests -> Build configuration\n- tests/, coverage reports -> Quality assurance\n- terraform/, cdk/, k8s/, deploy/ -> Deployment automation\n- monitoring/, dashboards/, alerts/ -> Monitoring and observability\n- runbooks/, SRE docs, production-readiness/ -> Production readiness validation\n\nFor brownfield projects: aidlc-docs/inception/reverse-engineering/, if present, is your primary context for the existing codebase.\n\n4.4 BRIEF SUMMARY (one short paragraph, not a question)\n\nTell the user what context was found, e.g.: \"Found requirements (README.md + docs/requirements.md), user stories (3 in docs/user-stories/), and existing architecture notes (ARCHITECTURE.md, docs/adr/). No risk assessment or units-of-work yet. Proceeding with <selected phase> using this context.\" If nothing was found, say so once and proceed: \"No prior-phase artifacts found in the workspace. Proceeding with <selected phase> from scratch.\"\n\n== STEP 5: Proceed ==\n\nFollow .kiro/steering/aws-aidlc-rules/core-workflow.md starting from the selected phase, using the context gathered in STEP 4. Reference the existing artifacts where relevant (e.g., when running Application Design, build on the requirements and user stories already captured). For Reverse Engineering, also consult .kiro/aws-aidlc-rule-details/inception/reverse-engineering.md if present.\n\nIf the user declined AI-DLC, proceed normally.\n\nIf you have already asked in this conversation, do NOT ask again - honor their earlier choice and the gathered context.\n\nDo NOT mix the two formats. Use userInput OR markdown, never both for the same question."
  }
}
```

The setup scripts embed this exact JSON content and write it directly to the workspace — they do NOT read from any separate hook file. To modify the hook behavior, update the JSON embedded in the setup scripts (`setup-aidlc.sh`, `setup-aidlc.ps1`, `setup-aidlc.bat`) and keep this POWER.md in sync.

## Post-Installation Usage

After installation, the agent will proactively ask the user at the beginning of each new conversation whether they'd like to use the AI-DLC workflow for their task. No special prompt prefix is needed. When the user opts in, the agent runs **workspace detection** (following `.kiro/aws-aidlc-rule-details/inception/workspace-detection.md`) to classify the project as **greenfield** or **brownfield**, then presents the appropriate phase selector. Once a phase is chosen, the agent silently scans the **entire workspace** — `aidlc-docs/`, root-level docs, `docs/`, `specs/`, ADRs, API/IDL specs, `.kiro/specs/`, threat models, build configs, IaC directories, source, tests, runbooks — for artifacts produced by earlier phases, builds context from what it finds, and proceeds with that context informing the selected phase.

### Greenfield phases (12)

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

### Brownfield phases (13)

1. **Reverse Engineering** — Analyze existing codebase to reconstruct requirements, architecture, and design artifacts
2. **Requirements analysis and validation**
3. **User story creation**
4. **Application Design**
5. **Creating units of work for parallel development**
6. **Risk assessment and complexity evaluation**
7. **Detailed component design**
8. **Code generation and implementation**
9. **Build configuration and testing strategies**
10. **Quality assurance and validation**
11. **Deployment automation and infrastructure**
12. **Monitoring and observability setup**
13. **Production readiness validation**

The agent then follows the AI-DLC core workflow starting from the selected phase, guiding the user through:

1. **Inception Phase** — Determines WHAT to build and WHY (includes Reverse Engineering for brownfield)
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
│       │   ├── workspace-detection.md
│       │   └── reverse-engineering.md
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
