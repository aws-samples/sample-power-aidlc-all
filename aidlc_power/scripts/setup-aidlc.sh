#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
# AI-DLC Setup for Kiro — macOS / Linux
# Downloads the latest AI-DLC release and installs steering files.
# Usage: bash setup-aidlc.sh [workspace-path]
# ──────────────────────────────────────────────────────────────────────────────
set -euo pipefail

WORKSPACE="${1:-.}"
WORKSPACE="$(cd "$WORKSPACE" && pwd)"

GITHUB_API="https://api.github.com/repos/awslabs/aidlc-workflows/releases/latest"
TMP_DIR="$(mktemp -d)"

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

# Parse the asset URL and tag — portable grep/sed, no jq required
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

# ── Locate the extracted folders ─────────────────────────────────────────────
# The zip contains an aidlc-rules/ folder with two subdirectories.
RULES_BASE=$(find "$EXTRACT_DIR" -type d -name "aws-aidlc-rules" | head -1)
DETAILS_BASE=$(find "$EXTRACT_DIR" -type d -name "aws-aidlc-rule-details" | head -1)

if [ -z "$RULES_BASE" ] || [ -z "$DETAILS_BASE" ]; then
  echo "ERROR: Expected directories not found in the release zip." >&2
  echo "       Looking for aws-aidlc-rules/ and aws-aidlc-rule-details/" >&2
  exit 1
fi

# ── Install into Kiro workspace ──────────────────────────────────────────────
STEERING_DEST="$WORKSPACE/.kiro/steering/aws-aidlc-rules"
DETAILS_DEST="$WORKSPACE/.kiro/aws-aidlc-rule-details"

echo "==> Installing steering files..."

# Remove old copies if present
rm -rf "$STEERING_DEST" "$DETAILS_DEST"

# Create directories and copy
mkdir -p "$WORKSPACE/.kiro/steering"
cp -R "$RULES_BASE" "$STEERING_DEST"
cp -R "$DETAILS_BASE" "$DETAILS_DEST"

# ── Install agent hook ────────────────────────────────────────────────────────
# NOTE: The agent hook is created by the agent using the createHook tool
# after this script completes. See setup-workflow.md Step 5.

echo "==> Done! AI-DLC $TAG installed successfully."
echo ""
echo "    Steering rules:  $STEERING_DEST"
echo "    Rule details:    $DETAILS_DEST"
echo ""
echo "    Open the Kiro steering panel to verify 'core-workflow' is listed."
echo "    The agent will ask at the start of each conversation if you want to use AI-DLC."
