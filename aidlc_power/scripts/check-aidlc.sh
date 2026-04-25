#!/usr/bin/env bash
# Check if AI-DLC steering files and hook are installed in a Kiro workspace.
# Usage: bash check-aidlc.sh [workspace-path]
set -euo pipefail

WORKSPACE="${1:-.}"
WORKSPACE="$(cd "$WORKSPACE" && pwd)"

STEERING="$WORKSPACE/.kiro/steering/aws-aidlc-rules"
DETAILS="$WORKSPACE/.kiro/aws-aidlc-rule-details"
CORE="$STEERING/core-workflow.md"
HOOK="$WORKSPACE/.kiro/hooks/aidlc-workflow-prompt.kiro.hook"

echo "==> AI-DLC Status Check"
echo "    Workspace: $WORKSPACE"
echo ""

ALL_OK=1
[ -d "$STEERING" ] || ALL_OK=0
[ -d "$DETAILS" ]  || ALL_OK=0
[ -f "$CORE" ]     || ALL_OK=0
[ -f "$HOOK" ]     || ALL_OK=0

ANY_PRESENT=0
[ -d "$STEERING" ] && ANY_PRESENT=1
[ -d "$DETAILS" ]  && ANY_PRESENT=1
[ -f "$CORE" ]     && ANY_PRESENT=1
[ -f "$HOOK" ]     && ANY_PRESENT=1

if [ "$ALL_OK" -eq 1 ]; then
    echo "    Status: INSTALLED"
    echo "    [OK]      $STEERING"
    echo "    [OK]      $DETAILS"
    echo "    [OK]      $CORE"
    echo "    [OK]      $HOOK"
elif [ "$ANY_PRESENT" -eq 1 ]; then
    echo "    Status: PARTIAL (some files missing)"
    [ -d "$STEERING" ] && echo "    [OK]      $STEERING" || echo "    [MISSING] $STEERING"
    [ -d "$DETAILS" ]  && echo "    [OK]      $DETAILS"  || echo "    [MISSING] $DETAILS"
    [ -f "$CORE" ]     && echo "    [OK]      $CORE"     || echo "    [MISSING] $CORE"
    [ -f "$HOOK" ]     && echo "    [OK]      $HOOK"     || echo "    [MISSING] $HOOK"
else
    echo "    Status: NOT INSTALLED"
fi
