#!/usr/bin/env bash
# Check if AI-DLC steering files are installed in a Kiro workspace.
# Usage: bash check-aidlc.sh [workspace-path]
set -euo pipefail

WORKSPACE="${1:-.}"
WORKSPACE="$(cd "$WORKSPACE" && pwd)"

STEERING="$WORKSPACE/.kiro/steering/aws-aidlc-rules"
DETAILS="$WORKSPACE/.kiro/aws-aidlc-rule-details"
CORE="$STEERING/core-workflow.md"

echo "==> AI-DLC Status Check"
echo "    Workspace: $WORKSPACE"
echo ""

if [ -d "$STEERING" ] && [ -d "$DETAILS" ] && [ -f "$CORE" ]; then
    echo "    Status: INSTALLED"
    echo "    Steering rules:  $STEERING"
    echo "    Rule details:    $DETAILS"
    echo "    Core workflow:   $CORE"
elif [ -d "$STEERING" ] || [ -d "$DETAILS" ]; then
    echo "    Status: PARTIAL (some files missing)"
    [ -d "$STEERING" ] && echo "    [OK]      $STEERING" || echo "    [MISSING] $STEERING"
    [ -d "$DETAILS" ]  && echo "    [OK]      $DETAILS"  || echo "    [MISSING] $DETAILS"
    [ -f "$CORE" ]     && echo "    [OK]      $CORE"     || echo "    [MISSING] $CORE"
else
    echo "    Status: NOT INSTALLED"
fi
