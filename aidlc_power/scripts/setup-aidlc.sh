#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
# AI-DLC Setup for Kiro — macOS / Linux
# Downloads the latest AI-DLC release, installs steering files, and writes
# the canonical agent hook defined in POWER.md.
# Usage: bash setup-aidlc.sh [workspace-path]
# ──────────────────────────────────────────────────────────────────────────────
set -euo pipefail

WORKSPACE="${1:-.}"
WORKSPACE="$(cd "$WORKSPACE" && pwd)"

GITHUB_API="https://api.github.com/repos/awslabs/aidlc-workflows/releases/latest"
TMP_DIR="$WORKSPACE/.aidlc-setup-tmp-$$"
mkdir -p "$TMP_DIR"

cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

echo "==> AI-DLC Setup for Kiro"
echo "    Workspace: $WORKSPACE"

# ── Fetch latest release info ────────────────────────────────────────────────
echo "==> Querying GitHub for latest release..."

RELEASE_JSON="$TMP_DIR/release.json"
if command -v curl &>/dev/null; then
  curl -sL -H "User-Agent: aidlc-setup" "$GITHUB_API" -o "$RELEASE_JSON"
elif command -v wget &>/dev/null; then
  wget -q --header="User-Agent: aidlc-setup" "$GITHUB_API" -O "$RELEASE_JSON"
else
  echo "ERROR: Neither curl nor wget found. Install one and retry." >&2
  exit 1
fi

TAG=$(grep -o '"tag_name"[[:space:]]*:[[:space:]]*"[^"]*"' "$RELEASE_JSON" | head -1 | sed 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
ASSET_URL=$(grep -o '"browser_download_url"[[:space:]]*:[[:space:]]*"[^"]*ai-dlc-rules[^"]*\.zip"' "$RELEASE_JSON" | head -1 | sed 's/.*"browser_download_url"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')

if [ -z "$ASSET_URL" ]; then
  echo "ERROR: Could not find AI-DLC rules zip in the latest release." >&2
  exit 1
fi

echo "    Latest release: $TAG"
echo "    Asset URL: $ASSET_URL"

# ── Download ─────────────────────────────────────────────────────────────────
ZIP_FILE="$TMP_DIR/aidlc-rules.zip"
echo "==> Downloading..."

if command -v curl &>/dev/null; then
  curl -sL "$ASSET_URL" -o "$ZIP_FILE"
else
  wget -q "$ASSET_URL" -O "$ZIP_FILE"
fi

# ── Extract ──────────────────────────────────────────────────────────────────
EXTRACT_DIR="$TMP_DIR/extracted"
mkdir -p "$EXTRACT_DIR"
echo "==> Extracting..."

if command -v unzip &>/dev/null; then
  unzip -qo "$ZIP_FILE" -d "$EXTRACT_DIR"
else
  tar -xf "$ZIP_FILE" -C "$EXTRACT_DIR"
fi

RULES_BASE=$(find "$EXTRACT_DIR" -type d -name "aws-aidlc-rules" | head -1)
DETAILS_BASE=$(find "$EXTRACT_DIR" -type d -name "aws-aidlc-rule-details" | head -1)

if [ -z "$RULES_BASE" ] || [ -z "$DETAILS_BASE" ]; then
  echo "ERROR: Expected directories not found in the release zip." >&2
  exit 1
fi

# ── Install steering files ───────────────────────────────────────────────────
STEERING_DEST="$WORKSPACE/.kiro/steering/aws-aidlc-rules"
DETAILS_DEST="$WORKSPACE/.kiro/aws-aidlc-rule-details"

echo "==> Installing steering files..."
rm -rf "$STEERING_DEST" "$DETAILS_DEST"
mkdir -p "$WORKSPACE/.kiro/steering"
cp -R "$RULES_BASE" "$STEERING_DEST"
cp -R "$DETAILS_BASE" "$DETAILS_DEST"

# ── Write the canonical agent hook (source of truth: POWER.md) ───────────────
HOOKS_DEST="$WORKSPACE/.kiro/hooks"
HOOK_FILE="$HOOKS_DEST/aidlc-workflow-prompt.kiro.hook"

echo "==> Installing agent hook..."
mkdir -p "$HOOKS_DEST"

cat > "$HOOK_FILE" <<'HOOK_EOF'
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
    "prompt": "Before proceeding with the user's request, check if AI-DLC steering files are installed in this workspace (look for .kiro/steering/aws-aidlc-rules/core-workflow.md).\n\nCRITICAL: You MUST STRICTLY use the userInput tool to present ALL options in this flow. Do NOT present options as plain text, markdown lists, or inline messages. Every question with choices MUST be a userInput tool call. This is non-negotiable.\n\nIf the steering files exist and you have NOT already asked the user about AI-DLC in this conversation, proceed with the steps below.\n\nSTEP A — Ask about AI-DLC:\n\nYou MUST call the userInput tool (not respond with text). Use these exact parameters:\n- reason: \"general-question\"\n- question: \"I see AI-DLC is set up in this workspace. Would you like to use the AI-DLC workflow for this task?\"\n- options: [\n    {\"title\": \"Yes, use AI-DLC\", \"description\": \"Activate the AI-DLC workflow and select a starting phase\", \"recommended\": true},\n    {\"title\": \"No thanks\", \"description\": \"Proceed normally without AI-DLC\"}\n  ]\n\nSTEP B — If user selected \"Yes, use AI-DLC\", you MUST immediately call the userInput tool again (not respond with text). Use these exact parameters:\n- reason: \"general-question\"\n- question: \"Which AI-DLC phase would you like to start from?\"\n- options: [\n    {\"title\": \"Requirements analysis and validation\", \"description\": \"Gather, analyze, and validate project requirements\"},\n    {\"title\": \"User story creation\", \"description\": \"Create user stories and acceptance criteria\"},\n    {\"title\": \"Application Design\", \"description\": \"Design the application architecture\"},\n    {\"title\": \"Creating units of work for parallel development\", \"description\": \"Break down work into parallelizable tasks\"},\n    {\"title\": \"Risk assessment and complexity evaluation\", \"description\": \"Identify risks and estimate complexity\"},\n    {\"title\": \"Detailed component design\", \"description\": \"Design individual components and interfaces\"},\n    {\"title\": \"Code generation and implementation\", \"description\": \"Generate and implement code\"},\n    {\"title\": \"Build configuration and testing strategies\", \"description\": \"Set up build pipelines and test frameworks\"},\n    {\"title\": \"Quality assurance and validation\", \"description\": \"Run tests and code reviews\"},\n    {\"title\": \"Deployment automation and infrastructure\", \"description\": \"Automate deployment and provision infrastructure\"},\n    {\"title\": \"Monitoring and observability setup\", \"description\": \"Set up logging, metrics, and dashboards\"},\n    {\"title\": \"Production readiness validation\", \"description\": \"Final checks before going live\"}\n  ]\n\nSTEP C — After user selects a phase via the userInput tool, follow the AI-DLC core-workflow.md steering file starting from that phase.\n\nIf user selected \"No thanks\" in STEP A, proceed normally without AI-DLC.\n\nIf you have already asked in this conversation, do NOT ask again — honor their earlier choice.\n\nREMINDER: All choices in this flow MUST be presented via the userInput tool. Never use plain text for option presentation."
  }
}
HOOK_EOF

echo "    Hook written to: $HOOK_FILE"

echo "==> Done! AI-DLC $TAG installed successfully."
echo ""
echo "    Steering rules:  $STEERING_DEST"
echo "    Rule details:    $DETAILS_DEST"
echo "    Agent hook:      $HOOK_FILE"
echo ""
echo "    Open the Kiro steering panel to verify 'core-workflow' is listed."
echo "    The agent will ask at the start of each conversation if you want to use AI-DLC."
