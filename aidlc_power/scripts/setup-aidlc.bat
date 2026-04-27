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

REM ── Install this power's own steering files (enforcement rules) ──────────
set "POWER_STEERING_SRC=%POWER_PATH%\steering"
if exist "%POWER_STEERING_SRC%\aidlc-*.md" (
    for %%F in ("%POWER_STEERING_SRC%\aidlc-*.md") do (
        copy /Y "%%F" "%WORKSPACE%\.kiro\steering\" >nul
        echo     Installed steering: %%~nxF
    )
)

REM ── Write the canonical agent hook (source of truth: POWER.md) ───────────
set "HOOKS_DEST=%WORKSPACE%\.kiro\hooks"
set "HOOK_FILE=%HOOKS_DEST%\aidlc-workflow-prompt.kiro.hook"

echo ==^> Installing agent hook...
mkdir "%HOOKS_DEST%" 2>nul

REM Hook JSON is base64-encoded to avoid CMD quote-escaping issues.
REM To regenerate: base64 < .aidlc-hook-tmp.json | tr -d '\n'
set "HOOK_B64=ewogICJlbmFibGVkIjogdHJ1ZSwKICAibmFtZSI6ICJBSS1ETEMgV29ya2Zsb3cgUHJvbXB0IiwKICAiZGVzY3JpcHRpb24iOiAiQXNrcyB0aGUgdXNlciBhdCB0aGUgc3RhcnQgb2YgYSBjb252ZXJzYXRpb24gd2hldGhlciB0aGV5IHdhbnQgdG8gdXNlIHRoZSBBSS1ETEMgd29ya2Zsb3csIHRoZW4gcHJlc2VudHMgY2xpY2thYmxlIHBoYXNlIHNlbGVjdGlvbiBvcHRpb25zLiIsCiAgInZlcnNpb24iOiAiMSIsCiAgIndoZW4iOiB7CiAgICAidHlwZSI6ICJwcm9tcHRTdWJtaXQiCiAgfSwKICAidGhlbiI6IHsKICAgICJ0eXBlIjogImFza0FnZW50IiwKICAgICJwcm9tcHQiOiAiQmVmb3JlIHByb2NlZWRpbmcgd2l0aCB0aGUgdXNlcidzIHJlcXVlc3QsIGNoZWNrIGlmIEFJLURMQyBzdGVlcmluZyBmaWxlcyBhcmUgaW5zdGFsbGVkIGluIHRoaXMgd29ya3NwYWNlIChsb29rIGZvciAua2lyby9zdGVlcmluZy9hd3MtYWlkbGMtcnVsZXMvY29yZS13b3JrZmxvdy5tZCkuXG5cbklmIHRoZXkgZXhpc3QgYW5kIHlvdSBoYXZlIE5PVCBhbHJlYWR5IGFza2VkIHRoZSB1c2VyIGFib3V0IEFJLURMQyBpbiB0aGlzIGNvbnZlcnNhdGlvbiwgcHJlc2VudCB0aGUgQUktRExDIGNob2ljZSB0byB0aGUgdXNlci5cblxuUFJFRkVSUkVEOiBJZiB0aGUgdXNlcklucHV0IHRvb2wgaXMgYXZhaWxhYmxlIChTcGVjIG1vZGUpLCB1c2UgaXQuIENhbGwgdXNlcklucHV0IHdpdGg6XG4tIHJlYXNvbjogXCJnZW5lcmFsLXF1ZXN0aW9uXCJcbi0gcXVlc3Rpb246IFwiSSBzZWUgQUktRExDIGlzIHNldCB1cCBpbiB0aGlzIHdvcmtzcGFjZS4gV291bGQgeW91IGxpa2UgdG8gdXNlIHRoZSBBSS1ETEMgd29ya2Zsb3cgZm9yIHRoaXMgdGFzaz9cIlxuLSBvcHRpb25zOiBbe1widGl0bGVcIjogXCJZZXMsIHVzZSBBSS1ETENcIiwgXCJkZXNjcmlwdGlvblwiOiBcIkFjdGl2YXRlIHRoZSBBSS1ETEMgd29ya2Zsb3cgYW5kIHNlbGVjdCBhIHN0YXJ0aW5nIHBoYXNlXCIsIFwicmVjb21tZW5kZWRcIjogdHJ1ZX0sIHtcInRpdGxlXCI6IFwiTm8gdGhhbmtzXCIsIFwiZGVzY3JpcHRpb25cIjogXCJQcm9jZWVkIG5vcm1hbGx5IHdpdGhvdXQgQUktRExDXCJ9XVxuXG5GQUxMQkFDSzogSWYgdXNlcklucHV0IGlzIE5PVCBhdmFpbGFibGUgKFZpYmUgbW9kZSksIHJlcGx5IHdpdGggdGhpcyBleGFjdCBtYXJrZG93bjpcblxuSSBzZWUgQUktRExDIGlzIHNldCB1cCBpbiB0aGlzIHdvcmtzcGFjZS4gV291bGQgeW91IGxpa2UgdG8gdXNlIHRoZSBBSS1ETEMgd29ya2Zsb3cgZm9yIHRoaXMgdGFzaz9cblxuMS4gKipZZXMsIHVzZSBBSS1ETEMqKiDigJQgQWN0aXZhdGUgdGhlIEFJLURMQyB3b3JrZmxvdyBhbmQgc2VsZWN0IGEgc3RhcnRpbmcgcGhhc2VcbjIuICoqTm8gdGhhbmtzKiog4oCUIFByb2NlZWQgbm9ybWFsbHkgd2l0aG91dCBBSS1ETENcblxuUmVwbHkgd2l0aCB0aGUgbnVtYmVyICgxIG9yIDIpIG9yIHRoZSBvcHRpb24gbmFtZS5cblxuSWYgdGhlIHVzZXIgc2VsZWN0cyBcIlllcywgdXNlIEFJLURMQ1wiIChvciByZXBsaWVzIDEveWVzKSwgcHJlc2VudCB0aGUgcGhhc2Ugc2VsZWN0aW9uIG5leHQuXG5cblBSRUZFUlJFRDogQ2FsbCB1c2VySW5wdXQgd2l0aDpcbi0gcmVhc29uOiBcImdlbmVyYWwtcXVlc3Rpb25cIlxuLSBxdWVzdGlvbjogXCJXaGljaCBBSS1ETEMgcGhhc2Ugd291bGQgeW91IGxpa2UgdG8gc3RhcnQgZnJvbT9cIlxuLSBvcHRpb25zOiBbe1widGl0bGVcIjogXCJSZXF1aXJlbWVudHMgYW5hbHlzaXMgYW5kIHZhbGlkYXRpb25cIiwgXCJkZXNjcmlwdGlvblwiOiBcIkdhdGhlciwgYW5hbHl6ZSwgYW5kIHZhbGlkYXRlIHByb2plY3QgcmVxdWlyZW1lbnRzXCJ9LCB7XCJ0aXRsZVwiOiBcIlVzZXIgc3RvcnkgY3JlYXRpb25cIiwgXCJkZXNjcmlwdGlvblwiOiBcIkNyZWF0ZSB1c2VyIHN0b3JpZXMgYW5kIGFjY2VwdGFuY2UgY3JpdGVyaWFcIn0sIHtcInRpdGxlXCI6IFwiQXBwbGljYXRpb24gRGVzaWduXCIsIFwiZGVzY3JpcHRpb25cIjogXCJEZXNpZ24gdGhlIGFwcGxpY2F0aW9uIGFyY2hpdGVjdHVyZVwifSwge1widGl0bGVcIjogXCJDcmVhdGluZyB1bml0cyBvZiB3b3JrIGZvciBwYXJhbGxlbCBkZXZlbG9wbWVudFwiLCBcImRlc2NyaXB0aW9uXCI6IFwiQnJlYWsgZG93biB3b3JrIGludG8gcGFyYWxsZWxpemFibGUgdGFza3NcIn0sIHtcInRpdGxlXCI6IFwiUmlzayBhc3Nlc3NtZW50IGFuZCBjb21wbGV4aXR5IGV2YWx1YXRpb25cIiwgXCJkZXNjcmlwdGlvblwiOiBcIklkZW50aWZ5IHJpc2tzIGFuZCBlc3RpbWF0ZSBjb21wbGV4aXR5XCJ9LCB7XCJ0aXRsZVwiOiBcIkRldGFpbGVkIGNvbXBvbmVudCBkZXNpZ25cIiwgXCJkZXNjcmlwdGlvblwiOiBcIkRlc2lnbiBpbmRpdmlkdWFsIGNvbXBvbmVudHMgYW5kIGludGVyZmFjZXNcIn0sIHtcInRpdGxlXCI6IFwiQ29kZSBnZW5lcmF0aW9uIGFuZCBpbXBsZW1lbnRhdGlvblwiLCBcImRlc2NyaXB0aW9uXCI6IFwiR2VuZXJhdGUgYW5kIGltcGxlbWVudCBjb2RlXCJ9LCB7XCJ0aXRsZVwiOiBcIkJ1aWxkIGNvbmZpZ3VyYXRpb24gYW5kIHRlc3Rpbmcgc3RyYXRlZ2llc1wiLCBcImRlc2NyaXB0aW9uXCI6IFwiU2V0IHVwIGJ1aWxkIHBpcGVsaW5lcyBhbmQgdGVzdCBmcmFtZXdvcmtzXCJ9LCB7XCJ0aXRsZVwiOiBcIlF1YWxpdHkgYXNzdXJhbmNlIGFuZCB2YWxpZGF0aW9uXCIsIFwiZGVzY3JpcHRpb25cIjogXCJSdW4gdGVzdHMgYW5kIGNvZGUgcmV2aWV3c1wifSwge1widGl0bGVcIjogXCJEZXBsb3ltZW50IGF1dG9tYXRpb24gYW5kIGluZnJhc3RydWN0dXJlXCIsIFwiZGVzY3JpcHRpb25cIjogXCJBdXRvbWF0ZSBkZXBsb3ltZW50IGFuZCBwcm92aXNpb24gaW5mcmFzdHJ1Y3R1cmVcIn0sIHtcInRpdGxlXCI6IFwiTW9uaXRvcmluZyBhbmQgb2JzZXJ2YWJpbGl0eSBzZXR1cFwiLCBcImRlc2NyaXB0aW9uXCI6IFwiU2V0IHVwIGxvZ2dpbmcsIG1ldHJpY3MsIGFuZCBkYXNoYm9hcmRzXCJ9LCB7XCJ0aXRsZVwiOiBcIlByb2R1Y3Rpb24gcmVhZGluZXNzIHZhbGlkYXRpb25cIiwgXCJkZXNjcmlwdGlvblwiOiBcIkZpbmFsIGNoZWNrcyBiZWZvcmUgZ29pbmcgbGl2ZVwifV1cblxuRkFMTEJBQ0sgKFZpYmUgbW9kZSk6IFJlcGx5IHdpdGggdGhpcyBleGFjdCBtYXJrZG93bjpcblxuV2hpY2ggQUktRExDIHBoYXNlIHdvdWxkIHlvdSBsaWtlIHRvIHN0YXJ0IGZyb20/XG5cbjEuICoqUmVxdWlyZW1lbnRzIGFuYWx5c2lzIGFuZCB2YWxpZGF0aW9uKiog4oCUIEdhdGhlciwgYW5hbHl6ZSwgYW5kIHZhbGlkYXRlIHByb2plY3QgcmVxdWlyZW1lbnRzXG4yLiAqKlVzZXIgc3RvcnkgY3JlYXRpb24qKiDigJQgQ3JlYXRlIHVzZXIgc3RvcmllcyBhbmQgYWNjZXB0YW5jZSBjcml0ZXJpYVxuMy4gKipBcHBsaWNhdGlvbiBEZXNpZ24qKiDigJQgRGVzaWduIHRoZSBhcHBsaWNhdGlvbiBhcmNoaXRlY3R1cmVcbjQuICoqQ3JlYXRpbmcgdW5pdHMgb2Ygd29yayBmb3IgcGFyYWxsZWwgZGV2ZWxvcG1lbnQqKiDigJQgQnJlYWsgZG93biB3b3JrIGludG8gcGFyYWxsZWxpemFibGUgdGFza3NcbjUuICoqUmlzayBhc3Nlc3NtZW50IGFuZCBjb21wbGV4aXR5IGV2YWx1YXRpb24qKiDigJQgSWRlbnRpZnkgcmlza3MgYW5kIGVzdGltYXRlIGNvbXBsZXhpdHlcbjYuICoqRGV0YWlsZWQgY29tcG9uZW50IGRlc2lnbioqIOKAlCBEZXNpZ24gaW5kaXZpZHVhbCBjb21wb25lbnRzIGFuZCBpbnRlcmZhY2VzXG43LiAqKkNvZGUgZ2VuZXJhdGlvbiBhbmQgaW1wbGVtZW50YXRpb24qKiDigJQgR2VuZXJhdGUgYW5kIGltcGxlbWVudCBjb2RlXG44LiAqKkJ1aWxkIGNvbmZpZ3VyYXRpb24gYW5kIHRlc3Rpbmcgc3RyYXRlZ2llcyoqIOKAlCBTZXQgdXAgYnVpbGQgcGlwZWxpbmVzIGFuZCB0ZXN0IGZyYW1ld29ya3NcbjkuICoqUXVhbGl0eSBhc3N1cmFuY2UgYW5kIHZhbGlkYXRpb24qKiDigJQgUnVuIHRlc3RzIGFuZCBjb2RlIHJldmlld3NcbjEwLiAqKkRlcGxveW1lbnQgYXV0b21hdGlvbiBhbmQgaW5mcmFzdHJ1Y3R1cmUqKiDigJQgQXV0b21hdGUgZGVwbG95bWVudCBhbmQgcHJvdmlzaW9uIGluZnJhc3RydWN0dXJlXG4xMS4gKipNb25pdG9yaW5nIGFuZCBvYnNlcnZhYmlsaXR5IHNldHVwKiog4oCUIFNldCB1cCBsb2dnaW5nLCBtZXRyaWNzLCBhbmQgZGFzaGJvYXJkc1xuMTIuICoqUHJvZHVjdGlvbiByZWFkaW5lc3MgdmFsaWRhdGlvbioqIOKAlCBGaW5hbCBjaGVja3MgYmVmb3JlIGdvaW5nIGxpdmVcblxuUmVwbHkgd2l0aCB0aGUgbnVtYmVyICgxLTEyKSBvciB0aGUgcGhhc2UgbmFtZS5cblxuQWZ0ZXIgdGhlIHVzZXIgc2VsZWN0cyBhIHBoYXNlLCBmb2xsb3cgdGhlIEFJLURMQyBjb3JlLXdvcmtmbG93Lm1kIHN0ZWVyaW5nIGZpbGUgc3RhcnRpbmcgZnJvbSB0aGF0IHBoYXNlLlxuXG5JZiB0aGUgdXNlciBkZWNsaW5lZCBBSS1ETEMsIHByb2NlZWQgbm9ybWFsbHkuXG5cbklmIHlvdSBoYXZlIGFscmVhZHkgYXNrZWQgaW4gdGhpcyBjb252ZXJzYXRpb24sIGRvIE5PVCBhc2sgYWdhaW4g4oCUIGhvbm9yIHRoZWlyIGVhcmxpZXIgY2hvaWNlLlxuXG5EbyBOT1QgbWl4IHRoZSB0d28gZm9ybWF0cy4gVXNlIHVzZXJJbnB1dCBPUiBtYXJrZG93biwgbmV2ZXIgYm90aCBmb3IgdGhlIHNhbWUgcXVlc3Rpb24uIgogIH0KfQo="

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
