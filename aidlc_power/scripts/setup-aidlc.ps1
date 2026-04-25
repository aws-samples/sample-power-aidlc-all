# ──────────────────────────────────────────────────────────────────────────────
# AI-DLC Setup for Kiro — Windows PowerShell
# Downloads the latest AI-DLC release, installs steering files, and writes
# the canonical agent hook defined in POWER.md.
# Usage: powershell -ExecutionPolicy Bypass -File setup-aidlc.ps1 [-WorkspacePath "C:\myproject"]
# ──────────────────────────────────────────────────────────────────────────────
param(
    [string]$WorkspacePath = "."
)

$ErrorActionPreference = "Stop"
$WorkspacePath = (Resolve-Path $WorkspacePath).Path

$GitHubApi = "https://api.github.com/repos/awslabs/aidlc-workflows/releases/latest"
$TmpDir = Join-Path $WorkspacePath ".aidlc-setup-tmp-$(Get-Random)"

function Cleanup {
    if (Test-Path $TmpDir) { Remove-Item -Recurse -Force $TmpDir }
}

try {
    New-Item -ItemType Directory -Force -Path $TmpDir | Out-Null

    Write-Host "==> AI-DLC Setup for Kiro"
    Write-Host "    Workspace: $WorkspacePath"

    # ── Fetch latest release info ────────────────────────────────────────────
    Write-Host "==> Querying GitHub for latest release..."

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $Headers = @{ "User-Agent" = "aidlc-setup" }
    $Release = Invoke-RestMethod -Uri $GitHubApi -Headers $Headers

    $Tag = $Release.tag_name
    $Asset = $Release.assets | Where-Object { $_.name -match "ai-dlc-rules.*\.zip" } | Select-Object -First 1

    if (-not $Asset) {
        Write-Error "Could not find AI-DLC rules zip in the latest release."
        exit 1
    }

    $AssetUrl = $Asset.browser_download_url
    Write-Host "    Latest release: $Tag"
    Write-Host "    Asset URL: $AssetUrl"

    # ── Download ─────────────────────────────────────────────────────────────
    $ZipFile = Join-Path $TmpDir "aidlc-rules.zip"
    Write-Host "==> Downloading..."
    Invoke-WebRequest -Uri $AssetUrl -OutFile $ZipFile -Headers $Headers

    # ── Extract ──────────────────────────────────────────────────────────────
    $ExtractDir = Join-Path $TmpDir "extracted"
    Write-Host "==> Extracting..."
    Expand-Archive -Path $ZipFile -DestinationPath $ExtractDir -Force

    $RulesBase = Get-ChildItem -Path $ExtractDir -Recurse -Directory -Filter "aws-aidlc-rules" | Select-Object -First 1
    $DetailsBase = Get-ChildItem -Path $ExtractDir -Recurse -Directory -Filter "aws-aidlc-rule-details" | Select-Object -First 1

    if (-not $RulesBase -or -not $DetailsBase) {
        Write-Error "Expected directories not found in the release zip."
        exit 1
    }

    # ── Install steering files ───────────────────────────────────────────────
    $SteeringDest = Join-Path $WorkspacePath ".kiro\steering\aws-aidlc-rules"
    $DetailsDest = Join-Path $WorkspacePath ".kiro\aws-aidlc-rule-details"

    Write-Host "==> Installing steering files..."

    if (Test-Path $SteeringDest) { Remove-Item -Recurse -Force $SteeringDest }
    if (Test-Path $DetailsDest) { Remove-Item -Recurse -Force $DetailsDest }

    New-Item -ItemType Directory -Force -Path (Join-Path $WorkspacePath ".kiro\steering") | Out-Null
    Copy-Item -Recurse -Force $RulesBase.FullName $SteeringDest
    Copy-Item -Recurse -Force $DetailsBase.FullName $DetailsDest

    # ── Write the canonical agent hook (source of truth: POWER.md) ───────────
    $HooksDest = Join-Path $WorkspacePath ".kiro\hooks"
    $HookFile = Join-Path $HooksDest "aidlc-workflow-prompt.kiro.hook"

    Write-Host "==> Installing agent hook..."
    New-Item -ItemType Directory -Force -Path $HooksDest | Out-Null

    $HookContent = @'
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
'@

    Set-Content -Path $HookFile -Value $HookContent -Encoding UTF8
    Write-Host "    Hook written to: $HookFile"

    Write-Host "==> Done! AI-DLC $Tag installed successfully."
    Write-Host ""
    Write-Host "    Steering rules:  $SteeringDest"
    Write-Host "    Rule details:    $DetailsDest"
    Write-Host "    Agent hook:      $HookFile"
    Write-Host ""
    Write-Host "    Open the Kiro steering panel to verify 'core-workflow' is listed."
    Write-Host "    The agent will ask at the start of each conversation if you want to use AI-DLC."
}
finally {
    Cleanup
}
