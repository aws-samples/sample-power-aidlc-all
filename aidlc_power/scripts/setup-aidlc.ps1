# ──────────────────────────────────────────────────────────────────────────────
# AI-DLC Setup for Kiro — Windows PowerShell
# Downloads the latest AI-DLC release and installs steering files.
# Usage: powershell -ExecutionPolicy Bypass -File setup-aidlc.ps1 [-WorkspacePath "C:\myproject"]
# ──────────────────────────────────────────────────────────────────────────────
param(
    [string]$WorkspacePath = "."
)

$ErrorActionPreference = "Stop"
$WorkspacePath = (Resolve-Path $WorkspacePath).Path

$GitHubApi = "https://api.github.com/repos/awslabs/aidlc-workflows/releases/latest"
$TmpDir = Join-Path ([System.IO.Path]::GetTempPath()) "aidlc-setup-$(Get-Random)"

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

    # ── Locate extracted folders ─────────────────────────────────────────────
    $RulesBase = Get-ChildItem -Path $ExtractDir -Recurse -Directory -Filter "aws-aidlc-rules" | Select-Object -First 1
    $DetailsBase = Get-ChildItem -Path $ExtractDir -Recurse -Directory -Filter "aws-aidlc-rule-details" | Select-Object -First 1

    if (-not $RulesBase -or -not $DetailsBase) {
        Write-Error "Expected directories not found in the release zip."
        exit 1
    }

    # ── Install into Kiro workspace ──────────────────────────────────────────
    $SteeringDest = Join-Path $WorkspacePath ".kiro\steering\aws-aidlc-rules"
    $DetailsDest = Join-Path $WorkspacePath ".kiro\aws-aidlc-rule-details"

    Write-Host "==> Installing steering files..."

    # Remove old copies if present
    if (Test-Path $SteeringDest) { Remove-Item -Recurse -Force $SteeringDest }
    if (Test-Path $DetailsDest) { Remove-Item -Recurse -Force $DetailsDest }

    # Create directories and copy
    New-Item -ItemType Directory -Force -Path (Join-Path $WorkspacePath ".kiro\steering") | Out-Null
    Copy-Item -Recurse -Force $RulesBase.FullName $SteeringDest
    Copy-Item -Recurse -Force $DetailsBase.FullName $DetailsDest

    # ── Agent hook is created by the agent using createHook after this script ──

    Write-Host "==> Done! AI-DLC $Tag installed successfully."
    Write-Host ""
    Write-Host "    Steering rules:  $SteeringDest"
    Write-Host "    Rule details:    $DetailsDest"
    Write-Host ""
    Write-Host "    Open the Kiro steering panel to verify 'core-workflow' is listed."
    Write-Host "    The agent will ask at the start of each conversation if you want to use AI-DLC."
}
finally {
    Cleanup
}
