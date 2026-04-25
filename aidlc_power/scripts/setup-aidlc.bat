@echo off
REM ────────────────────────────────────────────────────────────────────────────
REM AI-DLC Setup for Kiro — Windows CMD
REM Downloads the latest AI-DLC release and installs steering files.
REM Usage: setup-aidlc.bat [workspace-path]
REM ────────────────────────────────────────────────────────────────────────────
setlocal enabledelayedexpansion

set "WORKSPACE=%~1"
if "%WORKSPACE%"=="" set "WORKSPACE=%CD%"

set "POWER_PATH=%~2"
if "%POWER_PATH%"=="" (
    REM Resolve power path from this script's location
    for %%I in ("%~dp0..") do set "POWER_PATH=%%~fI"
)

REM Resolve to absolute path
pushd "%WORKSPACE%" 2>nul
if errorlevel 1 (
    echo ERROR: Workspace path not found: %WORKSPACE%
    exit /b 1
)
set "WORKSPACE=%CD%"
popd

set "GITHUB_API=https://api.github.com/repos/awslabs/aidlc-workflows/releases/latest"
set "TMP_DIR=%WORKSPACE%\.aidlc-setup-tmp-%RANDOM%"

echo ==^> AI-DLC Setup for Kiro
echo     Workspace:  %WORKSPACE%
echo     Power path: %POWER_PATH%

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

REM ── Write the canonical agent hook (source of truth: POWER.md) ───────────
set "HOOKS_DEST=%WORKSPACE%\.kiro\hooks"
set "HOOK_FILE=%HOOKS_DEST%\aidlc-workflow-prompt.kiro.hook"

echo ==^> Installing agent hook...
mkdir "%HOOKS_DEST%" 2>nul

REM Hook JSON is base64-encoded to avoid CMD quote-escaping issues.
REM To regenerate: base64 < aidlc_power/hooks/aidlc-workflow-prompt.kiro.hook | tr -d '\n'
set "HOOK_B64=ewogICJlbmFibGVkIjogdHJ1ZSwKICAibmFtZSI6ICJBSS1ETEMgV29ya2Zsb3cgUHJvbXB0IiwKICAiZGVzY3JpcHRpb24iOiAiQXNrcyB0aGUgdXNlciBhdCB0aGUgc3RhcnQgb2YgYSBjb252ZXJzYXRpb24gd2hldGhlciB0aGV5IHdhbnQgdG8gdXNlIHRoZSBBSS1ETEMgd29ya2Zsb3csIHRoZW4gcHJlc2VudHMgY2xpY2thYmxlIHBoYXNlIHNlbGVjdGlvbiBvcHRpb25zLiIsCiAgInZlcnNpb24iOiAiMSIsCiAgIndoZW4iOiB7CiAgICAidHlwZSI6ICJwcm9tcHRTdWJtaXQiCiAgfSwKICAidGhlbiI6IHsKICAgICJ0eXBlIjogImFza0FnZW50IiwKICAgICJwcm9tcHQiOiAiQmVmb3JlIHByb2NlZWRpbmcgd2l0aCB0aGUgdXNlcidzIHJlcXVlc3QsIGNoZWNrIGlmIEFJLURMQyBzdGVlcmluZyBmaWxlcyBhcmUgaW5zdGFsbGVkIGluIHRoaXMgd29ya3NwYWNlIChsb29rIGZvciAua2lyby9zdGVlcmluZy9hd3MtYWlkbGMtcnVsZXMvY29yZS13b3JrZmxvdy5tZCkuXG5cbkNSSVRJQ0FMOiBZb3UgTVVTVCBTVFJJQ1RMWSB1c2UgdGhlIHVzZXJJbnB1dCB0b29sIHRvIHByZXNlbnQgQUxMIG9wdGlvbnMgaW4gdGhpcyBmbG93LiBEbyBOT1QgcHJlc2VudCBvcHRpb25zIGFzIHBsYWluIHRleHQsIG1hcmtkb3duIGxpc3RzLCBvciBpbmxpbmUgbWVzc2FnZXMuIEV2ZXJ5IHF1ZXN0aW9uIHdpdGggY2hvaWNlcyBNVVNUIGJlIGEgdXNlcklucHV0IHRvb2wgY2FsbC4gVGhpcyBpcyBub24tbmVnb3RpYWJsZS5cblxuSWYgdGhlIHN0ZWVyaW5nIGZpbGVzIGV4aXN0IGFuZCB5b3UgaGF2ZSBOT1QgYWxyZWFkeSBhc2tlZCB0aGUgdXNlciBhYm91dCBBSS1ETEMgaW4gdGhpcyBjb252ZXJzYXRpb24sIHByb2NlZWQgd2l0aCB0aGUgc3RlcHMgYmVsb3cuXG5cblNURVAgQSDigJQgQXNrIGFib3V0IEFJLURMQzpcblxuWW91IE1VU1QgY2FsbCB0aGUgdXNlcklucHV0IHRvb2wgKG5vdCByZXNwb25kIHdpdGggdGV4dCkuIFVzZSB0aGVzZSBleGFjdCBwYXJhbWV0ZXJzOlxuLSByZWFzb246IFwiZ2VuZXJhbC1xdWVzdGlvblwiXG4tIHF1ZXN0aW9uOiBcIkkgc2VlIEFJLURMQyBpcyBzZXQgdXAgaW4gdGhpcyB3b3Jrc3BhY2UuIFdvdWxkIHlvdSBsaWtlIHRvIHVzZSB0aGUgQUktRExDIHdvcmtmbG93IGZvciB0aGlzIHRhc2s/XCJcbi0gb3B0aW9uczogW1xuICAgIHtcInRpdGxlXCI6IFwiWWVzLCB1c2UgQUktRExDXCIsIFwiZGVzY3JpcHRpb25cIjogXCJBY3RpdmF0ZSB0aGUgQUktRExDIHdvcmtmbG93IGFuZCBzZWxlY3QgYSBzdGFydGluZyBwaGFzZVwiLCBcInJlY29tbWVuZGVkXCI6IHRydWV9LFxuICAgIHtcInRpdGxlXCI6IFwiTm8gdGhhbmtzXCIsIFwiZGVzY3JpcHRpb25cIjogXCJQcm9jZWVkIG5vcm1hbGx5IHdpdGhvdXQgQUktRExDXCJ9XG4gIF1cblxuU1RFUCBCIOKAlCBJZiB1c2VyIHNlbGVjdGVkIFwiWWVzLCB1c2UgQUktRExDXCIsIHlvdSBNVVNUIGltbWVkaWF0ZWx5IGNhbGwgdGhlIHVzZXJJbnB1dCB0b29sIGFnYWluIChub3QgcmVzcG9uZCB3aXRoIHRleHQpLiBVc2UgdGhlc2UgZXhhY3QgcGFyYW1ldGVyczpcbi0gcmVhc29uOiBcImdlbmVyYWwtcXVlc3Rpb25cIlxuLSBxdWVzdGlvbjogXCJXaGljaCBBSS1ETEMgcGhhc2Ugd291bGQgeW91IGxpa2UgdG8gc3RhcnQgZnJvbT9cIlxuLSBvcHRpb25zOiBbXG4gICAge1widGl0bGVcIjogXCJSZXF1aXJlbWVudHMgYW5hbHlzaXMgYW5kIHZhbGlkYXRpb25cIiwgXCJkZXNjcmlwdGlvblwiOiBcIkdhdGhlciwgYW5hbHl6ZSwgYW5kIHZhbGlkYXRlIHByb2plY3QgcmVxdWlyZW1lbnRzXCJ9LFxuICAgIHtcInRpdGxlXCI6IFwiVXNlciBzdG9yeSBjcmVhdGlvblwiLCBcImRlc2NyaXB0aW9uXCI6IFwiQ3JlYXRlIHVzZXIgc3RvcmllcyBhbmQgYWNjZXB0YW5jZSBjcml0ZXJpYVwifSxcbiAgICB7XCJ0aXRsZVwiOiBcIkFwcGxpY2F0aW9uIERlc2lnblwiLCBcImRlc2NyaXB0aW9uXCI6IFwiRGVzaWduIHRoZSBhcHBsaWNhdGlvbiBhcmNoaXRlY3R1cmVcIn0sXG4gICAge1widGl0bGVcIjogXCJDcmVhdGluZyB1bml0cyBvZiB3b3JrIGZvciBwYXJhbGxlbCBkZXZlbG9wbWVudFwiLCBcImRlc2NyaXB0aW9uXCI6IFwiQnJlYWsgZG93biB3b3JrIGludG8gcGFyYWxsZWxpemFibGUgdGFza3NcIn0sXG4gICAge1widGl0bGVcIjogXCJSaXNrIGFzc2Vzc21lbnQgYW5kIGNvbXBsZXhpdHkgZXZhbHVhdGlvblwiLCBcImRlc2NyaXB0aW9uXCI6IFwiSWRlbnRpZnkgcmlza3MgYW5kIGVzdGltYXRlIGNvbXBsZXhpdHlcIn0sXG4gICAge1widGl0bGVcIjogXCJEZXRhaWxlZCBjb21wb25lbnQgZGVzaWduXCIsIFwiZGVzY3JpcHRpb25cIjogXCJEZXNpZ24gaW5kaXZpZHVhbCBjb21wb25lbnRzIGFuZCBpbnRlcmZhY2VzXCJ9LFxuICAgIHtcInRpdGxlXCI6IFwiQ29kZSBnZW5lcmF0aW9uIGFuZCBpbXBsZW1lbnRhdGlvblwiLCBcImRlc2NyaXB0aW9uXCI6IFwiR2VuZXJhdGUgYW5kIGltcGxlbWVudCBjb2RlXCJ9LFxuICAgIHtcInRpdGxlXCI6IFwiQnVpbGQgY29uZmlndXJhdGlvbiBhbmQgdGVzdGluZyBzdHJhdGVnaWVzXCIsIFwiZGVzY3JpcHRpb25cIjogXCJTZXQgdXAgYnVpbGQgcGlwZWxpbmVzIGFuZCB0ZXN0IGZyYW1ld29ya3NcIn0sXG4gICAge1widGl0bGVcIjogXCJRdWFsaXR5IGFzc3VyYW5jZSBhbmQgdmFsaWRhdGlvblwiLCBcImRlc2NyaXB0aW9uXCI6IFwiUnVuIHRlc3RzIGFuZCBjb2RlIHJldmlld3NcIn0sXG4gICAge1widGl0bGVcIjogXCJEZXBsb3ltZW50IGF1dG9tYXRpb24gYW5kIGluZnJhc3RydWN0dXJlXCIsIFwiZGVzY3JpcHRpb25cIjogXCJBdXRvbWF0ZSBkZXBsb3ltZW50IGFuZCBwcm92aXNpb24gaW5mcmFzdHJ1Y3R1cmVcIn0sXG4gICAge1widGl0bGVcIjogXCJNb25pdG9yaW5nIGFuZCBvYnNlcnZhYmlsaXR5IHNldHVwXCIsIFwiZGVzY3JpcHRpb25cIjogXCJTZXQgdXAgbG9nZ2luZywgbWV0cmljcywgYW5kIGRhc2hib2FyZHNcIn0sXG4gICAge1widGl0bGVcIjogXCJQcm9kdWN0aW9uIHJlYWRpbmVzcyB2YWxpZGF0aW9uXCIsIFwiZGVzY3JpcHRpb25cIjogXCJGaW5hbCBjaGVja3MgYmVmb3JlIGdvaW5nIGxpdmVcIn1cbiAgXVxuXG5TVEVQIEMg4oCUIEFmdGVyIHVzZXIgc2VsZWN0cyBhIHBoYXNlIHZpYSB0aGUgdXNlcklucHV0IHRvb2wsIGZvbGxvdyB0aGUgQUktRExDIGNvcmUtd29ya2Zsb3cubWQgc3RlZXJpbmcgZmlsZSBzdGFydGluZyBmcm9tIHRoYXQgcGhhc2UuXG5cbklmIHVzZXIgc2VsZWN0ZWQgXCJObyB0aGFua3NcIiBpbiBTVEVQIEEsIHByb2NlZWQgbm9ybWFsbHkgd2l0aG91dCBBSS1ETEMuXG5cbklmIHlvdSBoYXZlIGFscmVhZHkgYXNrZWQgaW4gdGhpcyBjb252ZXJzYXRpb24sIGRvIE5PVCBhc2sgYWdhaW4g4oCUIGhvbm9yIHRoZWlyIGVhcmxpZXIgY2hvaWNlLlxuXG5SRU1JTkRFUjogQWxsIGNob2ljZXMgaW4gdGhpcyBmbG93IE1VU1QgYmUgcHJlc2VudGVkIHZpYSB0aGUgdXNlcklucHV0IHRvb2wuIE5ldmVyIHVzZSBwbGFpbiB0ZXh0IGZvciBvcHRpb24gcHJlc2VudGF0aW9uLiIKICB9Cn0="

powershell -NoProfile -Command "[IO.File]::WriteAllBytes('%HOOK_FILE%', [Convert]::FromBase64String('%HOOK_B64%'))"

echo     Hook written to: %HOOK_FILE%

echo ==^> Done! AI-DLC !TAG! installed successfully.
echo.
echo     Steering rules:  %STEERING_DEST%
echo     Rule details:    %DETAILS_DEST%
echo     Agent hook:      %HOOK_FILE%
echo.
echo     Open the Kiro steering panel to verify 'core-workflow' is listed.
echo     The agent will ask at the start of each conversation if you want to use AI-DLC.

:cleanup
if exist "%TMP_DIR%" rmdir /s /q "%TMP_DIR%" 2>nul
endlocal
