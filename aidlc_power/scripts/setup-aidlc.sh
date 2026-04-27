#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
# AI-DLC Setup for Kiro — macOS / Linux
# Downloads the latest AI-DLC release, installs steering files, and writes
# the canonical agent hook defined in POWER.md.
# Usage: bash setup-aidlc.sh [workspace-path] [power-path]
# ──────────────────────────────────────────────────────────────────────────────
set -euo pipefail

WORKSPACE="${1:-.}"
WORKSPACE="$(cd "$WORKSPACE" && pwd)"

# Resolve power path — prefer explicit argument, fall back to BASH_SOURCE
if [ -n "${2:-}" ]; then
  POWER_PATH="$(cd "$2" && pwd)"
else
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  POWER_PATH="$(dirname "$SCRIPT_DIR")"
fi

GITHUB_API="https://api.github.com/repos/awslabs/aidlc-workflows/releases/latest"
TMP_DIR="$WORKSPACE/.aidlc-setup-tmp-$$"
mkdir -p "$TMP_DIR"

cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

echo "==> AI-DLC Setup for Kiro"
echo "    Workspace:  $WORKSPACE"
echo "    Power path: $POWER_PATH"

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

# ── Install steering files (AI-DLC rules from release) ───────────────────────
STEERING_DEST="$WORKSPACE/.kiro/steering/aws-aidlc-rules"
DETAILS_DEST="$WORKSPACE/.kiro/aws-aidlc-rule-details"

echo "==> Installing AI-DLC steering files..."
rm -rf "$STEERING_DEST" "$DETAILS_DEST"
mkdir -p "$WORKSPACE/.kiro/steering"
cp -R "$RULES_BASE" "$STEERING_DEST"
cp -R "$DETAILS_BASE" "$DETAILS_DEST"

# ── Install this power's own steering files (enforcement rules) ──────────────
POWER_STEERING_SRC="$POWER_PATH/steering"

echo "==> Installing power's steering files..."
echo "    Looking in: $POWER_STEERING_SRC"

if [ ! -d "$POWER_STEERING_SRC" ]; then
  echo "    WARNING: Power steering directory not found: $POWER_STEERING_SRC" >&2
  echo "    Pass the power path as the 2nd argument if auto-detection fails." >&2
else
  POWER_STEERING_COUNT=$(find "$POWER_STEERING_SRC" -maxdepth 1 -name "aidlc-*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
  if [ "$POWER_STEERING_COUNT" -eq 0 ]; then
    echo "    WARNING: No aidlc-*.md files found in $POWER_STEERING_SRC" >&2
    echo "    Files present in steering directory:" >&2
    ls -la "$POWER_STEERING_SRC" >&2 || true
  else
    for steering_file in "$POWER_STEERING_SRC"/aidlc-*.md; do
      [ -e "$steering_file" ] || continue
      cp -f "$steering_file" "$WORKSPACE/.kiro/steering/"
      echo "    Installed: $(basename "$steering_file")"
    done
  fi
fi

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
    "prompt": "Before proceeding with the user's request, check if AI-DLC steering files are installed in this workspace (look for .kiro/steering/aws-aidlc-rules/core-workflow.md).\n\nIf they exist and you have NOT already asked the user about AI-DLC in this conversation, present the AI-DLC choice to the user.\n\nPREFERRED: If the userInput tool is available (Spec mode), use it. Call userInput with:\n- reason: \"general-question\"\n- question: \"I see AI-DLC is set up in this workspace. Would you like to use the AI-DLC workflow for this task?\"\n- options: [{\"title\": \"Yes, use AI-DLC\", \"description\": \"Activate the AI-DLC workflow and select a starting phase\", \"recommended\": true}, {\"title\": \"No thanks\", \"description\": \"Proceed normally without AI-DLC\"}]\n\nFALLBACK: If userInput is NOT available (Vibe mode), reply with this exact markdown:\n\nI see AI-DLC is set up in this workspace. Would you like to use the AI-DLC workflow for this task?\n\n1. **Yes, use AI-DLC** — Activate the AI-DLC workflow and select a starting phase\n2. **No thanks** — Proceed normally without AI-DLC\n\nReply with the number (1 or 2) or the option name.\n\nIf the user selects \"Yes, use AI-DLC\" (or replies 1/yes), present the phase selection next.\n\nPREFERRED: Call userInput with:\n- reason: \"general-question\"\n- question: \"Which AI-DLC phase would you like to start from?\"\n- options: [{\"title\": \"Requirements analysis and validation\", \"description\": \"Gather, analyze, and validate project requirements\"}, {\"title\": \"User story creation\", \"description\": \"Create user stories and acceptance criteria\"}, {\"title\": \"Application Design\", \"description\": \"Design the application architecture\"}, {\"title\": \"Creating units of work for parallel development\", \"description\": \"Break down work into parallelizable tasks\"}, {\"title\": \"Risk assessment and complexity evaluation\", \"description\": \"Identify risks and estimate complexity\"}, {\"title\": \"Detailed component design\", \"description\": \"Design individual components and interfaces\"}, {\"title\": \"Code generation and implementation\", \"description\": \"Generate and implement code\"}, {\"title\": \"Build configuration and testing strategies\", \"description\": \"Set up build pipelines and test frameworks\"}, {\"title\": \"Quality assurance and validation\", \"description\": \"Run tests and code reviews\"}, {\"title\": \"Deployment automation and infrastructure\", \"description\": \"Automate deployment and provision infrastructure\"}, {\"title\": \"Monitoring and observability setup\", \"description\": \"Set up logging, metrics, and dashboards\"}, {\"title\": \"Production readiness validation\", \"description\": \"Final checks before going live\"}]\n\nFALLBACK (Vibe mode): Reply with this exact markdown:\n\nWhich AI-DLC phase would you like to start from?\n\n1. **Requirements analysis and validation** — Gather, analyze, and validate project requirements\n2. **User story creation** — Create user stories and acceptance criteria\n3. **Application Design** — Design the application architecture\n4. **Creating units of work for parallel development** — Break down work into parallelizable tasks\n5. **Risk assessment and complexity evaluation** — Identify risks and estimate complexity\n6. **Detailed component design** — Design individual components and interfaces\n7. **Code generation and implementation** — Generate and implement code\n8. **Build configuration and testing strategies** — Set up build pipelines and test frameworks\n9. **Quality assurance and validation** — Run tests and code reviews\n10. **Deployment automation and infrastructure** — Automate deployment and provision infrastructure\n11. **Monitoring and observability setup** — Set up logging, metrics, and dashboards\n12. **Production readiness validation** — Final checks before going live\n\nReply with the number (1-12) or the phase name.\n\nAfter the user selects a phase, follow the AI-DLC core-workflow.md steering file starting from that phase.\n\nIf the user declined AI-DLC, proceed normally.\n\nIf you have already asked in this conversation, do NOT ask again — honor their earlier choice.\n\nDo NOT mix the two formats. Use userInput OR markdown, never both for the same question."
  }
}
HOOK_EOF

echo "    Hook written to: $HOOK_FILE"

echo "==> Done! AI-DLC $TAG installed successfully."
echo ""
echo "    Steering rules:   $STEERING_DEST"
echo "    Rule details:     $DETAILS_DEST"
echo "    Power steering:   $WORKSPACE/.kiro/steering/ (aidlc-*.md files)"
echo "    Agent hook:       $HOOK_FILE"
echo ""
echo "    Open the Kiro steering panel to verify 'core-workflow' is listed."
echo "    The agent will ask at the start of each conversation if you want to use AI-DLC."
