#!/usr/bin/env bash
# Remove AI-DLC steering files from a Kiro workspace.
# Usage: bash remove-aidlc.sh [workspace-path]
set -euo pipefail

WORKSPACE="${1:-.}"
WORKSPACE="$(cd "$WORKSPACE" && pwd)"

STEERING="$WORKSPACE/.kiro/steering/aws-aidlc-rules"
DETAILS="$WORKSPACE/.kiro/aws-aidlc-rule-details"

echo "==> Removing AI-DLC from Kiro workspace"
echo "    Workspace: $WORKSPACE"

REMOVED=0
if [ -d "$STEERING" ]; then
    rm -rf "$STEERING"
    echo "    Removed: $STEERING"
    REMOVED=1
fi
if [ -d "$DETAILS" ]; then
    rm -rf "$DETAILS"
    echo "    Removed: $DETAILS"
    REMOVED=1
fi

if [ "$REMOVED" -eq 0 ]; then
    echo "    Nothing to remove — AI-DLC is not installed."
else
    echo "==> Done. AI-DLC steering files removed."
fi
