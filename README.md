# AI-DLC Setup Power for Kiro

A [Kiro](https://kiro.dev) power that automates the installation of [AI-DLC](https://github.com/awslabs/aidlc-workflows) (AI-Driven Development Life Cycle) steering files into your workspace. AI-DLC is an adaptive software development workflow from AWS that guides you through inception, construction, and operations phases.

## What It Does

1. Downloads the latest AI-DLC release from GitHub
2. Installs steering files into your `.kiro/` directory
3. Registers an agent hook that, at the start of each conversation:
   - Asks whether you want to use AI-DLC
   - Runs **workspace detection** to classify the project as **greenfield** (no existing code) or **brownfield** (existing code found)
   - Presents a phase selector tailored to the detected type — brownfield projects get **Reverse Engineering** as the first phase
   - Silently scans the entire workspace (`aidlc-docs/`, root docs, `docs/`, ADRs, API specs, `.kiro/specs/`, build/IaC configs, source, tests, runbooks) for earlier-phase artifacts and uses them as context for the chosen phase

No special prompt prefix needed — the agent asks you automatically.

## Prerequisites

- [Kiro IDE](https://kiro.dev) with Powers support
- Internet access to `api.github.com` and `github.com`
- `curl` or `wget` (macOS/Linux), `curl` (Windows 10+)

## Installation

### From GitHub (Recommended)

1. Open Kiro IDE
2. Open the Powers panel → click "Add Custom Power" → click "Add power from GitHub"
3. Enter the repository URL:
   ```bash
   https://github.com/aws-samples/sample-power-aidlc-all/tree/main/aidlc_power
   ```
4. Click Install

### From Local Path

1. Clone this repository:
   ```bash
   git clone https://github.com/aws-samples/sample-power-aidlc-all.git
   ```
2. Open Kiro IDE
3. Open the Powers panel → click "Add power from Local Path"
4. Select the `aidlc_power` directory (the one containing `POWER.md`)
5. Click Install

### After Installation

1. Ask the agent: *"Set up AI-DLC"*
2. The agent runs the appropriate setup script for your platform and registers the hook

## Platform Support

| Platform | Script |
|----------|--------|
| macOS / Linux | `setup-aidlc.sh` |
| Windows (PowerShell) | `setup-aidlc.ps1` |
| Windows (CMD) | `setup-aidlc.bat` |

## How It Works

After installation, every new conversation starts with the agent checking for AI-DLC steering files. If found, it asks:

> *"I see AI-DLC is set up in this workspace. Would you like to use the AI-DLC workflow for this task?"*

- Say **no** → the agent proceeds normally.
- Say **yes** → the agent silently runs workspace detection (per `.kiro/aws-aidlc-rule-details/inception/workspace-detection.md`), classifies the project, and presents the appropriate phase list.

The agent asks once per conversation and remembers your choice.

### Greenfield phases (12)

For empty workspaces with no source or build files:

1. Requirements analysis and validation
2. User story creation
3. Application Design
4. Creating units of work for parallel development
5. Risk assessment and complexity evaluation
6. Detailed component design
7. Code generation and implementation
8. Build configuration and testing strategies
9. Quality assurance and validation
10. Deployment automation and infrastructure
11. Monitoring and observability setup
12. Production readiness validation

### Brownfield phases (13)

For workspaces with existing code, **Reverse Engineering** is added at the top:

1. **Reverse Engineering** — Analyze existing codebase to reconstruct requirements, architecture, and design artifacts
2. Requirements analysis and validation
3. User story creation
4. Application Design
5. Creating units of work for parallel development
6. Risk assessment and complexity evaluation
7. Detailed component design
8. Code generation and implementation
9. Build configuration and testing strategies
10. Quality assurance and validation
11. Deployment automation and infrastructure
12. Monitoring and observability setup
13. Production readiness validation

The agent then follows the AI-DLC workflow starting from your chosen phase. For Reverse Engineering, it also consults `.kiro/aws-aidlc-rule-details/inception/reverse-engineering.md` if available.

### Context gathering

Before running the chosen phase, the agent silently scans the **entire workspace** for artifacts that could inform earlier phases. The scan covers far more than just `aidlc-docs/`:

- **AI-DLC canonical** — `aidlc-docs/`
- **Root-level docs** — `README.md`, `ARCHITECTURE.md`, `DESIGN.md`, `REQUIREMENTS.md`, `ROADMAP.md`, RFCs, PRDs, `SECURITY.md`
- **Generic doc directories** — `docs/`, `documentation/`, `specs/`, `design/`, `architecture/`, `user-stories/`
- **Architecture decision records** — `docs/adr/`, `architecture/decisions/`, `adr/`
- **API and interface specs** — OpenAPI/Swagger, GraphQL schemas, Protobuf, Thrift, Avro
- **Kiro specs** — `.kiro/specs/`
- **Threat models and security** — `.threatmodel/`, `security/`
- **Build/test/CI** — package manifests, Dockerfile, `.github/workflows/`, Jenkinsfile, etc.
- **Infrastructure-as-code** — `terraform/`, `cdk/`, `k8s/`, `helm/`, `deploy/`
- **Source, tests, monitoring, runbooks** — for brownfield context and later phases

Common cache/vendor directories (`node_modules/`, `vendor/`, `.git/`, build outputs) are excluded. The agent briefly summarizes what it found and runs the selected phase informed by that context. If no prior artifacts exist, it simply starts from scratch. Nothing is asked.

## Installed Directory Structure

```
<project-root>/
└── .kiro/
    ├── hooks/
    │   └── aidlc-workflow-prompt.kiro.hook
    ├── steering/
    │   ├── aws-aidlc-rules/
    │   │   └── core-workflow.md
    │   └── aidlc-userinput-enforcement.md
    └── aws-aidlc-rule-details/
        ├── common/
        ├── inception/
        │   ├── workspace-detection.md
        │   └── reverse-engineering.md
        ├── construction/
        ├── extensions/
        └── operations/
```

## Updating

Ask the agent to set up AI-DLC again. The setup script overwrites existing files with the latest release.

## Uninstalling

Ask the agent to remove AI-DLC, or run the remove script manually:

```bash
# macOS / Linux
bash aidlc_power/scripts/remove-aidlc.sh "<workspace-root>"
```

## Troubleshooting

- **Network errors** — Check connectivity to `api.github.com`. If behind a proxy, set `HTTPS_PROXY`.
- **Steering files not visible** — Restart Kiro or open a new chat session.
- **Windows script execution disabled** — Run `Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned` or use the `.bat` script.
- **Wrong project type detected** — If the workspace has a single non-source artifact (like a stray `README.md`) and you'd expected greenfield, that's still classified as greenfield. If detection seems off, you can simply pick a different phase from the list manually.

## Security

- All downloads use HTTPS with TLS certificate validation
- Temp files are cleaned up automatically after installation
- The agent hook prompt is hardcoded and not user-modifiable during setup

## License

Community contribution. See [AI-DLC](https://github.com/awslabs/aidlc-workflows) for the upstream license.
