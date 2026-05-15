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
