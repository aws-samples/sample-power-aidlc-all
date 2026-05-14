# ──────────────────────────────────────────────────────────────────────────────
# AI-DLC Setup for Kiro — Windows PowerShell
# Downloads the latest AI-DLC release, installs steering files, and writes
# the canonical agent hook defined in POWER.md.
# Usage: powershell -ExecutionPolicy Bypass -File setup-aidlc.ps1 [-WorkspacePath "C:\myproject"]
# ──────────────────────────────────────────────────────────────────────────────
param(
    [string]$WorkspacePath = ".",
    [string]$PowerPath = ""
)

$ErrorActionPreference = "Stop"
$WorkspacePath = (Resolve-Path $WorkspacePath).Path

# Resolve power path
if (-not $PowerPath) {
    $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $PowerPath = Split-Path -Parent $ScriptDir
} else {
    $PowerPath = (Resolve-Path $PowerPath).Path
}

$GitHubApi = "https://api.github.com/repos/awslabs/aidlc-workflows/releases/latest"
$TmpDir = Join-Path $WorkspacePath ".aidlc-setup-tmp-$(Get-Random)"

function Cleanup {
    if (Test-Path $TmpDir) { Remove-Item -Recurse -Force $TmpDir -ErrorAction SilentlyContinue }
}

function Write-HookFile {
    param([string]$Path)

    # JSON content with ASCII-only characters (no em-dashes) to avoid encoding issues
    $json = @'
{
  "enabled": true,
  "name": "AI-DLC Workflow Prompt",
  "description": "Asks the user at the start of a conversation whether they want to use the AI-DLC workflow, runs workspace detection (greenfield vs brownfield), and presents clickable phase selection options accordingly.",
  "version": "1",
  "when": {
    "type": "promptSubmit"
  },
  "then": {
    "type": "askAgent",
    "prompt": "Before proceeding with the user's request, check if AI-DLC steering files are installed in this workspace (look for .kiro/steering/aws-aidlc-rules/core-workflow.md).\n\nIf they exist and you have NOT already asked the user about AI-DLC in this conversation, present the AI-DLC choice to the user.\n\n== STEP 1: Ask Yes/No ==\n\nPREFERRED: If the userInput tool is available (Spec mode), use it. Call userInput with:\n- reason: \"general-question\"\n- question: \"I see AI-DLC is set up in this workspace. Would you like to use the AI-DLC workflow for this task?\"\n- options: [{\"title\": \"Yes, use AI-DLC\", \"description\": \"Activate the AI-DLC workflow and select a starting phase\", \"recommended\": true}, {\"title\": \"No thanks\", \"description\": \"Proceed normally without AI-DLC\"}]\n\nFALLBACK: If userInput is NOT available (Vibe mode), reply with this exact markdown:\n\nI see AI-DLC is set up in this workspace. Would you like to use the AI-DLC workflow for this task?\n\n1. **Yes, use AI-DLC** - Activate the AI-DLC workflow and select a starting phase\n2. **No thanks** - Proceed normally without AI-DLC\n\nReply with the number (1 or 2) or the option name.\n\n== STEP 2: Workspace Detection (only if user chose Yes) ==\n\nIf the user selected \"Yes, use AI-DLC\" (or replied 1/yes), DO NOT present the phase list yet. First run workspace detection by loading and following .kiro/aws-aidlc-rule-details/inception/workspace-detection.md. Silently scan the workspace for existing source code files (.java, .py, .js, .ts, .jsx, .tsx, .kt, .kts, .scala, .groovy, .go, .rs, .rb, .php, .c, .h, .cpp, .hpp, .cc, .cs, .fs) and build files (pom.xml, package.json, build.gradle, Cargo.toml, go.mod, Gemfile, requirements.txt, pyproject.toml, etc.), excluding the .kiro and aidlc-docs directories. Do NOT ask the user - detect automatically.\n\n- If NO source or build files are found outside .kiro and aidlc-docs: project_type = greenfield\n- If source or build files are found: project_type = brownfield\n\n== STEP 3: Present phase selection for the detected type ==\n\nFor GREENFIELD: present 12 phases starting with \"Requirements analysis and validation\".\nFor BROWNFIELD: present 13 phases with \"Reverse Engineering\" as phase 1.\n\nPREFERRED (Spec mode): Call userInput with:\n- reason: \"general-question\"\n- question: \"Detected <greenfield|brownfield> project. Which AI-DLC phase would you like to start from?\" (substitute the detected type)\n- options for GREENFIELD: [{\"title\": \"Requirements analysis and validation\", \"description\": \"Gather, analyze, and validate project requirements\", \"recommended\": true}, {\"title\": \"User story creation\", \"description\": \"Create user stories and acceptance criteria\"}, {\"title\": \"Application Design\", \"description\": \"Design the application architecture\"}, {\"title\": \"Creating units of work for parallel development\", \"description\": \"Break down work into parallelizable tasks\"}, {\"title\": \"Risk assessment and complexity evaluation\", \"description\": \"Identify risks and estimate complexity\"}, {\"title\": \"Detailed component design\", \"description\": \"Design individual components and interfaces\"}, {\"title\": \"Code generation and implementation\", \"description\": \"Generate and implement code\"}, {\"title\": \"Build configuration and testing strategies\", \"description\": \"Set up build pipelines and test frameworks\"}, {\"title\": \"Quality assurance and validation\", \"description\": \"Run tests and code reviews\"}, {\"title\": \"Deployment automation and infrastructure\", \"description\": \"Automate deployment and provision infrastructure\"}, {\"title\": \"Monitoring and observability setup\", \"description\": \"Set up logging, metrics, and dashboards\"}, {\"title\": \"Production readiness validation\", \"description\": \"Final checks before going live\"}]\n- options for BROWNFIELD: [{\"title\": \"Reverse Engineering\", \"description\": \"Analyze existing codebase to reconstruct requirements, architecture, and design artifacts\", \"recommended\": true}, {\"title\": \"Requirements analysis and validation\", \"description\": \"Gather, analyze, and validate project requirements\"}, {\"title\": \"User story creation\", \"description\": \"Create user stories and acceptance criteria\"}, {\"title\": \"Application Design\", \"description\": \"Design the application architecture\"}, {\"title\": \"Creating units of work for parallel development\", \"description\": \"Break down work into parallelizable tasks\"}, {\"title\": \"Risk assessment and complexity evaluation\", \"description\": \"Identify risks and estimate complexity\"}, {\"title\": \"Detailed component design\", \"description\": \"Design individual components and interfaces\"}, {\"title\": \"Code generation and implementation\", \"description\": \"Generate and implement code\"}, {\"title\": \"Build configuration and testing strategies\", \"description\": \"Set up build pipelines and test frameworks\"}, {\"title\": \"Quality assurance and validation\", \"description\": \"Run tests and code reviews\"}, {\"title\": \"Deployment automation and infrastructure\", \"description\": \"Automate deployment and provision infrastructure\"}, {\"title\": \"Monitoring and observability setup\", \"description\": \"Set up logging, metrics, and dashboards\"}, {\"title\": \"Production readiness validation\", \"description\": \"Final checks before going live\"}]\n\nFALLBACK (Vibe mode):\n\nIf GREENFIELD, reply with this exact markdown:\n\nDetected: Greenfield project (no existing code).\n\nWhich AI-DLC phase would you like to start from?\n\n1. **Requirements analysis and validation** - Gather, analyze, and validate project requirements\n2. **User story creation** - Create user stories and acceptance criteria\n3. **Application Design** - Design the application architecture\n4. **Creating units of work for parallel development** - Break down work into parallelizable tasks\n5. **Risk assessment and complexity evaluation** - Identify risks and estimate complexity\n6. **Detailed component design** - Design individual components and interfaces\n7. **Code generation and implementation** - Generate and implement code\n8. **Build configuration and testing strategies** - Set up build pipelines and test frameworks\n9. **Quality assurance and validation** - Run tests and code reviews\n10. **Deployment automation and infrastructure** - Automate deployment and provision infrastructure\n11. **Monitoring and observability setup** - Set up logging, metrics, and dashboards\n12. **Production readiness validation** - Final checks before going live\n\nReply with the number (1-12) or the phase name.\n\nIf BROWNFIELD, reply with this exact markdown:\n\nDetected: Brownfield project (existing code found).\n\nWhich AI-DLC phase would you like to start from?\n\n1. **Reverse Engineering** - Analyze existing codebase to reconstruct requirements, architecture, and design artifacts\n2. **Requirements analysis and validation** - Gather, analyze, and validate project requirements\n3. **User story creation** - Create user stories and acceptance criteria\n4. **Application Design** - Design the application architecture\n5. **Creating units of work for parallel development** - Break down work into parallelizable tasks\n6. **Risk assessment and complexity evaluation** - Identify risks and estimate complexity\n7. **Detailed component design** - Design individual components and interfaces\n8. **Code generation and implementation** - Generate and implement code\n9. **Build configuration and testing strategies** - Set up build pipelines and test frameworks\n10. **Quality assurance and validation** - Run tests and code reviews\n11. **Deployment automation and infrastructure** - Automate deployment and provision infrastructure\n12. **Monitoring and observability setup** - Set up logging, metrics, and dashboards\n13. **Production readiness validation** - Final checks before going live\n\nReply with the number (1-13) or the phase name.\n\n== STEP 4: Proceed ==\n\nAfter the user selects a phase, follow .kiro/steering/aws-aidlc-rules/core-workflow.md starting from that phase. For Reverse Engineering, also consult .kiro/aws-aidlc-rule-details/inception/reverse-engineering.md if present.\n\nIf the user declined AI-DLC, proceed normally.\n\nIf you have already asked in this conversation, do NOT ask again - honor their earlier choice.\n\nDo NOT mix the two formats. Use userInput OR markdown, never both for the same question."
  }
}
'@

    # Strip any BOM from the string itself (in case the here-string picked one up)
    if ($json.Length -gt 0 -and [int][char]$json[0] -eq 0xFEFF) {
        $json = $json.Substring(1)
    }

    # Convert to UTF-8 bytes with NO BOM and write directly (bypasses PS 5.1 BOM behavior)
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)

    # Sanity check: ensure no BOM at start of byte array
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        $bytes = $bytes[3..($bytes.Length - 1)]
    }

    # Resolve to absolute path
    $absPath = [System.IO.Path]::GetFullPath($Path)

    # Use FileStream directly to avoid any PowerShell encoding interference
    $fs = [System.IO.File]::Create($absPath)
    try {
        $fs.Write($bytes, 0, $bytes.Length)
    } finally {
        $fs.Close()
    }
}

try {
    New-Item -ItemType Directory -Force -Path $TmpDir | Out-Null

    Write-Host "==> AI-DLC Setup for Kiro"
    Write-Host "    Workspace:  $WorkspacePath"
    Write-Host "    Power path: $PowerPath"

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

    Write-Host "==> Installing AI-DLC steering files..."

    if (Test-Path $SteeringDest) { Remove-Item -Recurse -Force $SteeringDest }
    if (Test-Path $DetailsDest) { Remove-Item -Recurse -Force $DetailsDest }

    New-Item -ItemType Directory -Force -Path (Join-Path $WorkspacePath ".kiro\steering") | Out-Null
    Copy-Item -Recurse -Force $RulesBase.FullName $SteeringDest
    Copy-Item -Recurse -Force $DetailsBase.FullName $DetailsDest

    # ── Install this power's own steering files (enforcement rules) ──────────
    $PowerSteeringSrc = Join-Path $PowerPath "steering"

    Write-Host "==> Installing power's steering files..."
    Write-Host "    Looking in: $PowerSteeringSrc"

    if (-not (Test-Path $PowerSteeringSrc)) {
        Write-Warning "Power steering directory not found: $PowerSteeringSrc"
    } else {
        $steeringFiles = @(Get-ChildItem -Path $PowerSteeringSrc -Filter "aidlc-*.md" -ErrorAction SilentlyContinue)
        if ($steeringFiles.Count -eq 0) {
            Write-Warning "No aidlc-*.md files found in $PowerSteeringSrc"
        } else {
            $targetSteering = Join-Path $WorkspacePath ".kiro\steering"
            foreach ($f in $steeringFiles) {
                Copy-Item -Force $f.FullName $targetSteering
                Write-Host "    Installed: $($f.Name)"
            }
        }
    }

    # ── Write the canonical agent hook ───────────────────────────────────────
    $HooksDest = Join-Path $WorkspacePath ".kiro\hooks"
    $HookFile = Join-Path $HooksDest "aidlc-workflow-prompt.kiro.hook"

    Write-Host "==> Installing agent hook..."
    New-Item -ItemType Directory -Force -Path $HooksDest | Out-Null

    try {
        Write-HookFile -Path $HookFile
        if (Test-Path $HookFile) {
            $size = (Get-Item $HookFile).Length
            # Verify no BOM by reading first 3 bytes
            $firstBytes = [System.IO.File]::ReadAllBytes($HookFile) | Select-Object -First 3
            if ($firstBytes.Count -ge 3 -and $firstBytes[0] -eq 0xEF -and $firstBytes[1] -eq 0xBB -and $firstBytes[2] -eq 0xBF) {
                Write-Warning "Hook file has BOM! This will break JSON parsing. Attempting to strip..."
                $allBytes = [System.IO.File]::ReadAllBytes($HookFile)
                $stripped = $allBytes[3..($allBytes.Length - 1)]
                [System.IO.File]::WriteAllBytes($HookFile, $stripped)
                Write-Host "    BOM stripped from hook file"
            }
            Write-Host "    Hook written to: $HookFile ($size bytes)"
        } else {
            Write-Error "Hook file was not created: $HookFile"
        }
    } catch {
        Write-Error "Failed to write hook file: $($_.Exception.Message)"
        throw
    }

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
