# AI-DLC Setup Power for Kiro [Multi OS]

A [Kiro](https://kiro.dev) power that automates the installation of [AI-DLC](https://github.com/awslabs/aidlc-workflows) (AI-Driven Development Life Cycle) steering files into your workspace. AI-DLC is an adaptive software development workflow from AWS that guides you through inception, construction, and operations phases.

## What It Does

1. Downloads the latest AI-DLC release from GitHub
2. Installs steering files into your `.kiro/` directory
3. Registers an agent hook that asks whether you want to use AI-DLC at the start of each conversation

No special prompt prefix needed — the agent asks you automatically.

## Prerequisites

- [Kiro IDE](https://kiro.dev) with Powers support
- Internet access to `api.github.com` and `github.com`
- `curl` or `wget` (macOS/Linux), `curl` (Windows 10+)

## Installation

1. Install this power in Kiro
2. Ask the agent: *"Set up AI-DLC"*
3. The agent runs the appropriate setup script for your platform and registers the hook

## Platform Support

| Platform | Script |
|----------|--------|
| macOS / Linux | `setup-aidlc.sh` |
| Windows (PowerShell) | `setup-aidlc.ps1` |
| Windows (CMD) | `setup-aidlc.bat` |

## How It Works

After installation, every new conversation starts with the agent checking for AI-DLC steering files. If found, it asks:

> *"I see AI-DLC is set up in this workspace. Would you like to use the AI-DLC workflow for this task?"*

- Say **yes** → the AI-DLC workflow activates (Inception → Construction → Operations)
- Say **no** → the agent proceeds normally

The agent only asks once per conversation.

## Installed Directory Structure

```
<project-root>/
└── .kiro/
    ├── steering/
    │   └── aws-aidlc-rules/
    │       └── core-workflow.md
    └── aws-aidlc-rule-details/
        ├── common/
        ├── inception/
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
bash power-aidlc-setup/scripts/remove-aidlc.sh "<workspace-root>"
```

## Troubleshooting

- **Network errors** — Check connectivity to `api.github.com`. If behind a proxy, set `HTTPS_PROXY`.
- **Steering files not visible** — Restart Kiro or open a new chat session.
- **Windows script execution disabled** — Run `Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned` or use the `.bat` script.

## Security

- All downloads use HTTPS with TLS certificate validation
- Temp files are cleaned up automatically after installation
- The agent hook prompt is hardcoded and not user-modifiable during setup
- See `.threatmodel/` for the full STRIDE-based threat model

## License

Community contribution. See [AI-DLC](https://github.com/awslabs/aidlc-workflows) for the upstream license.
