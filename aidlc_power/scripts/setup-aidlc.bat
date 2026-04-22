@echo off
REM ────────────────────────────────────────────────────────────────────────────
REM AI-DLC Setup for Kiro — Windows CMD
REM Downloads the latest AI-DLC release and installs steering files.
REM Usage: setup-aidlc.bat [workspace-path]
REM ────────────────────────────────────────────────────────────────────────────
setlocal enabledelayedexpansion

set "WORKSPACE=%~1"
if "%WORKSPACE%"=="" set "WORKSPACE=%CD%"

REM Resolve to absolute path
pushd "%WORKSPACE%" 2>nul
if errorlevel 1 (
    echo ERROR: Workspace path not found: %WORKSPACE%
    exit /b 1
)
set "WORKSPACE=%CD%"
popd

set "GITHUB_API=https://api.github.com/repos/awslabs/aidlc-workflows/releases/latest"
set "TMP_DIR=%TEMP%\aidlc-setup-%RANDOM%"

echo ==^> AI-DLC Setup for Kiro
echo     Workspace: %WORKSPACE%

mkdir "%TMP_DIR%" 2>nul

REM ── Check for curl (available on Windows 10+) ─────────────────────────────
where curl >nul 2>&1
if errorlevel 1 (
    echo ERROR: curl not found. Windows 10+ includes curl by default.
    echo        Please install curl or use the PowerShell script instead.
    goto :cleanup
)

REM ── Fetch latest release info ──────────────────────────────────────────────
echo ==^> Querying GitHub for latest release...
set "RELEASE_JSON=%TMP_DIR%\release.json"
curl -sL -H "User-Agent: aidlc-setup" "%GITHUB_API%" -o "%RELEASE_JSON%"

REM Parse tag_name — extract version between quotes after tag_name
for /f "tokens=2 delims=:" %%a in ('findstr /C:"tag_name" "%RELEASE_JSON%"') do (
    set "TAG_RAW=%%a"
)
REM Clean up the tag value — remove quotes, commas, spaces
set "TAG=!TAG_RAW: =!"
set "TAG=!TAG:"=!"
set "TAG=!TAG:,=!"

REM Parse the ai-dlc-rules zip URL
for /f "delims=" %%a in ('findstr /C:"ai-dlc-rules" "%RELEASE_JSON%" ^| findstr /C:"browser_download_url"') do (
    set "URL_LINE=%%a"
)
REM Extract URL from the line
for /f "tokens=2 delims= " %%u in ("!URL_LINE!") do (
    set "ASSET_URL=%%~u"
)
REM Remove trailing quote and comma if present
set "ASSET_URL=!ASSET_URL:"=!"
set "ASSET_URL=!ASSET_URL:,=!"

if "!ASSET_URL!"=="" (
    echo ERROR: Could not find AI-DLC rules zip in the latest release.
    goto :cleanup
)

echo     Latest release: !TAG!
echo     Asset URL: !ASSET_URL!

REM ── Download ───────────────────────────────────────────────────────────────
set "ZIP_FILE=%TMP_DIR%\aidlc-rules.zip"
echo ==^> Downloading...
curl -sL "!ASSET_URL!" -o "%ZIP_FILE%"

REM ── Extract ────────────────────────────────────────────────────────────────
set "EXTRACT_DIR=%TMP_DIR%\extracted"
mkdir "%EXTRACT_DIR%" 2>nul
echo ==^> Extracting...
tar -xf "%ZIP_FILE%" -C "%EXTRACT_DIR%" 2>nul
if errorlevel 1 (
    echo ERROR: Failed to extract zip. tar is required ^(Windows 10+^).
    goto :cleanup
)

REM ── Locate extracted folders ───────────────────────────────────────────────
set "RULES_BASE="
set "DETAILS_BASE="

for /f "delims=" %%d in ('dir /s /b /ad "%EXTRACT_DIR%\aws-aidlc-rules" 2^>nul') do (
    if not defined RULES_BASE set "RULES_BASE=%%d"
)
for /f "delims=" %%d in ('dir /s /b /ad "%EXTRACT_DIR%\aws-aidlc-rule-details" 2^>nul') do (
    if not defined DETAILS_BASE set "DETAILS_BASE=%%d"
)

if not defined RULES_BASE (
    echo ERROR: aws-aidlc-rules directory not found in the release zip.
    goto :cleanup
)
if not defined DETAILS_BASE (
    echo ERROR: aws-aidlc-rule-details directory not found in the release zip.
    goto :cleanup
)

REM ── Install into Kiro workspace ────────────────────────────────────────────
set "STEERING_DEST=%WORKSPACE%\.kiro\steering\aws-aidlc-rules"
set "DETAILS_DEST=%WORKSPACE%\.kiro\aws-aidlc-rule-details"

echo ==^> Installing steering files...

REM Remove old copies if present
if exist "%STEERING_DEST%" rmdir /s /q "%STEERING_DEST%"
if exist "%DETAILS_DEST%" rmdir /s /q "%DETAILS_DEST%"

REM Create directories and copy
mkdir "%WORKSPACE%\.kiro\steering" 2>nul
xcopy "%RULES_BASE%" "%STEERING_DEST%\" /E /I /Q /Y >nul
xcopy "%DETAILS_BASE%" "%DETAILS_DEST%\" /E /I /Q /Y >nul

REM ── Agent hook is created by the agent using createHook after this script ──

echo ==^> Done! AI-DLC !TAG! installed successfully.
echo.
echo     Steering rules:  %STEERING_DEST%
echo     Rule details:    %DETAILS_DEST%
echo.
echo     Open the Kiro steering panel to verify 'core-workflow' is listed.
echo     The agent will ask at the start of each conversation if you want to use AI-DLC.

:cleanup
if exist "%TMP_DIR%" rmdir /s /q "%TMP_DIR%" 2>nul
endlocal
