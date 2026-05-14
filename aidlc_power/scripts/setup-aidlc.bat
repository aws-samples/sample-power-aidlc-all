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
set "HOOK_B64=ewogICJlbmFibGVkIjogdHJ1ZSwKICAibmFtZSI6ICJBSS1ETEMgV29ya2Zsb3cgUHJvbXB0IiwKICAiZGVzY3JpcHRpb24iOiAiQXNrcyB0aGUgdXNlciBhdCB0aGUgc3RhcnQgb2YgYSBjb252ZXJzYXRpb24gd2hldGhlciB0aGV5IHdhbnQgdG8gdXNlIHRoZSBBSS1ETEMgd29ya2Zsb3csIHJ1bnMgd29ya3NwYWNlIGRldGVjdGlvbiAoZ3JlZW5maWVsZCB2cyBicm93bmZpZWxkKSwgYW5kIHByZXNlbnRzIGNsaWNrYWJsZSBwaGFzZSBzZWxlY3Rpb24gb3B0aW9ucyBhY2NvcmRpbmdseS4iLAogICJ2ZXJzaW9uIjogIjEiLAogICJ3aGVuIjogewogICAgInR5cGUiOiAicHJvbXB0U3VibWl0IgogIH0sCiAgInRoZW4iOiB7CiAgICAidHlwZSI6ICJhc2tBZ2VudCIsCiAgICAicHJvbXB0IjogIkJlZm9yZSBwcm9jZWVkaW5nIHdpdGggdGhlIHVzZXIncyByZXF1ZXN0LCBjaGVjayBpZiBBSS1ETEMgc3RlZXJpbmcgZmlsZXMgYXJlIGluc3RhbGxlZCBpbiB0aGlzIHdvcmtzcGFjZSAobG9vayBmb3IgLmtpcm8vc3RlZXJpbmcvYXdzLWFpZGxjLXJ1bGVzL2NvcmUtd29ya2Zsb3cubWQpLlxuXG5JZiB0aGV5IGV4aXN0IGFuZCB5b3UgaGF2ZSBOT1QgYWxyZWFkeSBhc2tlZCB0aGUgdXNlciBhYm91dCBBSS1ETEMgaW4gdGhpcyBjb252ZXJzYXRpb24sIHByZXNlbnQgdGhlIEFJLURMQyBjaG9pY2UgdG8gdGhlIHVzZXIuXG5cbj09IFNURVAgMTogQXNrIFllcy9ObyA9PVxuXG5QUkVGRVJSRUQ6IElmIHRoZSB1c2VySW5wdXQgdG9vbCBpcyBhdmFpbGFibGUgKFNwZWMgbW9kZSksIHVzZSBpdC4gQ2FsbCB1c2VySW5wdXQgd2l0aDpcbi0gcmVhc29uOiBcImdlbmVyYWwtcXVlc3Rpb25cIlxuLSBxdWVzdGlvbjogXCJJIHNlZSBBSS1ETEMgaXMgc2V0IHVwIGluIHRoaXMgd29ya3NwYWNlLiBXb3VsZCB5b3UgbGlrZSB0byB1c2UgdGhlIEFJLURMQyB3b3JrZmxvdyBmb3IgdGhpcyB0YXNrP1wiXG4tIG9wdGlvbnM6IFt7XCJ0aXRsZVwiOiBcIlllcywgdXNlIEFJLURMQ1wiLCBcImRlc2NyaXB0aW9uXCI6IFwiQWN0aXZhdGUgdGhlIEFJLURMQyB3b3JrZmxvdyBhbmQgc2VsZWN0IGEgc3RhcnRpbmcgcGhhc2VcIiwgXCJyZWNvbW1lbmRlZFwiOiB0cnVlfSwge1widGl0bGVcIjogXCJObyB0aGFua3NcIiwgXCJkZXNjcmlwdGlvblwiOiBcIlByb2NlZWQgbm9ybWFsbHkgd2l0aG91dCBBSS1ETENcIn1dXG5cbkZBTExCQUNLOiBJZiB1c2VySW5wdXQgaXMgTk9UIGF2YWlsYWJsZSAoVmliZSBtb2RlKSwgcmVwbHkgd2l0aCB0aGlzIGV4YWN0IG1hcmtkb3duOlxuXG5JIHNlZSBBSS1ETEMgaXMgc2V0IHVwIGluIHRoaXMgd29ya3NwYWNlLiBXb3VsZCB5b3UgbGlrZSB0byB1c2UgdGhlIEFJLURMQyB3b3JrZmxvdyBmb3IgdGhpcyB0YXNrP1xuXG4xLiAqKlllcywgdXNlIEFJLURMQyoqIC0gQWN0aXZhdGUgdGhlIEFJLURMQyB3b3JrZmxvdyBhbmQgc2VsZWN0IGEgc3RhcnRpbmcgcGhhc2VcbjIuICoqTm8gdGhhbmtzKiogLSBQcm9jZWVkIG5vcm1hbGx5IHdpdGhvdXQgQUktRExDXG5cblJlcGx5IHdpdGggdGhlIG51bWJlciAoMSBvciAyKSBvciB0aGUgb3B0aW9uIG5hbWUuXG5cbj09IFNURVAgMjogV29ya3NwYWNlIERldGVjdGlvbiAob25seSBpZiB1c2VyIGNob3NlIFllcykgPT1cblxuSWYgdGhlIHVzZXIgc2VsZWN0ZWQgXCJZZXMsIHVzZSBBSS1ETENcIiAob3IgcmVwbGllZCAxL3llcyksIERPIE5PVCBwcmVzZW50IHRoZSBwaGFzZSBsaXN0IHlldC4gRmlyc3QgcnVuIHdvcmtzcGFjZSBkZXRlY3Rpb24gYnkgbG9hZGluZyBhbmQgZm9sbG93aW5nIC5raXJvL2F3cy1haWRsYy1ydWxlLWRldGFpbHMvaW5jZXB0aW9uL3dvcmtzcGFjZS1kZXRlY3Rpb24ubWQuIFNpbGVudGx5IHNjYW4gdGhlIHdvcmtzcGFjZSBmb3IgZXhpc3Rpbmcgc291cmNlIGNvZGUgZmlsZXMgKC5qYXZhLCAucHksIC5qcywgLnRzLCAuanN4LCAudHN4LCAua3QsIC5rdHMsIC5zY2FsYSwgLmdyb292eSwgLmdvLCAucnMsIC5yYiwgLnBocCwgLmMsIC5oLCAuY3BwLCAuaHBwLCAuY2MsIC5jcywgLmZzKSBhbmQgYnVpbGQgZmlsZXMgKHBvbS54bWwsIHBhY2thZ2UuanNvbiwgYnVpbGQuZ3JhZGxlLCBDYXJnby50b21sLCBnby5tb2QsIEdlbWZpbGUsIHJlcXVpcmVtZW50cy50eHQsIHB5cHJvamVjdC50b21sLCBldGMuKSwgZXhjbHVkaW5nIHRoZSAua2lybyBhbmQgYWlkbGMtZG9jcyBkaXJlY3Rvcmllcy4gRG8gTk9UIGFzayB0aGUgdXNlciAtIGRldGVjdCBhdXRvbWF0aWNhbGx5LlxuXG4tIElmIE5PIHNvdXJjZSBvciBidWlsZCBmaWxlcyBhcmUgZm91bmQgb3V0c2lkZSAua2lybyBhbmQgYWlkbGMtZG9jczogcHJvamVjdF90eXBlID0gZ3JlZW5maWVsZFxuLSBJZiBzb3VyY2Ugb3IgYnVpbGQgZmlsZXMgYXJlIGZvdW5kOiBwcm9qZWN0X3R5cGUgPSBicm93bmZpZWxkXG5cbj09IFNURVAgMzogUHJlc2VudCBwaGFzZSBzZWxlY3Rpb24gZm9yIHRoZSBkZXRlY3RlZCB0eXBlID09XG5cbkZvciBHUkVFTkZJRUxEOiBwcmVzZW50IDEyIHBoYXNlcyBzdGFydGluZyB3aXRoIFwiUmVxdWlyZW1lbnRzIGFuYWx5c2lzIGFuZCB2YWxpZGF0aW9uXCIuXG5Gb3IgQlJPV05GSUVMRDogcHJlc2VudCAxMyBwaGFzZXMgd2l0aCBcIlJldmVyc2UgRW5naW5lZXJpbmdcIiBhcyBwaGFzZSAxLlxuXG5QUkVGRVJSRUQgKFNwZWMgbW9kZSk6IENhbGwgdXNlcklucHV0IHdpdGg6XG4tIHJlYXNvbjogXCJnZW5lcmFsLXF1ZXN0aW9uXCJcbi0gcXVlc3Rpb246IFwiRGV0ZWN0ZWQgPGdyZWVuZmllbGR8YnJvd25maWVsZD4gcHJvamVjdC4gV2hpY2ggQUktRExDIHBoYXNlIHdvdWxkIHlvdSBsaWtlIHRvIHN0YXJ0IGZyb20/XCIgKHN1YnN0aXR1dGUgdGhlIGRldGVjdGVkIHR5cGUpXG4tIG9wdGlvbnMgZm9yIEdSRUVORklFTEQ6IFt7XCJ0aXRsZVwiOiBcIlJlcXVpcmVtZW50cyBhbmFseXNpcyBhbmQgdmFsaWRhdGlvblwiLCBcImRlc2NyaXB0aW9uXCI6IFwiR2F0aGVyLCBhbmFseXplLCBhbmQgdmFsaWRhdGUgcHJvamVjdCByZXF1aXJlbWVudHNcIiwgXCJyZWNvbW1lbmRlZFwiOiB0cnVlfSwge1widGl0bGVcIjogXCJVc2VyIHN0b3J5IGNyZWF0aW9uXCIsIFwiZGVzY3JpcHRpb25cIjogXCJDcmVhdGUgdXNlciBzdG9yaWVzIGFuZCBhY2NlcHRhbmNlIGNyaXRlcmlhXCJ9LCB7XCJ0aXRsZVwiOiBcIkFwcGxpY2F0aW9uIERlc2lnblwiLCBcImRlc2NyaXB0aW9uXCI6IFwiRGVzaWduIHRoZSBhcHBsaWNhdGlvbiBhcmNoaXRlY3R1cmVcIn0sIHtcInRpdGxlXCI6IFwiQ3JlYXRpbmcgdW5pdHMgb2Ygd29yayBmb3IgcGFyYWxsZWwgZGV2ZWxvcG1lbnRcIiwgXCJkZXNjcmlwdGlvblwiOiBcIkJyZWFrIGRvd24gd29yayBpbnRvIHBhcmFsbGVsaXphYmxlIHRhc2tzXCJ9LCB7XCJ0aXRsZVwiOiBcIlJpc2sgYXNzZXNzbWVudCBhbmQgY29tcGxleGl0eSBldmFsdWF0aW9uXCIsIFwiZGVzY3JpcHRpb25cIjogXCJJZGVudGlmeSByaXNrcyBhbmQgZXN0aW1hdGUgY29tcGxleGl0eVwifSwge1widGl0bGVcIjogXCJEZXRhaWxlZCBjb21wb25lbnQgZGVzaWduXCIsIFwiZGVzY3JpcHRpb25cIjogXCJEZXNpZ24gaW5kaXZpZHVhbCBjb21wb25lbnRzIGFuZCBpbnRlcmZhY2VzXCJ9LCB7XCJ0aXRsZVwiOiBcIkNvZGUgZ2VuZXJhdGlvbiBhbmQgaW1wbGVtZW50YXRpb25cIiwgXCJkZXNjcmlwdGlvblwiOiBcIkdlbmVyYXRlIGFuZCBpbXBsZW1lbnQgY29kZVwifSwge1widGl0bGVcIjogXCJCdWlsZCBjb25maWd1cmF0aW9uIGFuZCB0ZXN0aW5nIHN0cmF0ZWdpZXNcIiwgXCJkZXNjcmlwdGlvblwiOiBcIlNldCB1cCBidWlsZCBwaXBlbGluZXMgYW5kIHRlc3QgZnJhbWV3b3Jrc1wifSwge1widGl0bGVcIjogXCJRdWFsaXR5IGFzc3VyYW5jZSBhbmQgdmFsaWRhdGlvblwiLCBcImRlc2NyaXB0aW9uXCI6IFwiUnVuIHRlc3RzIGFuZCBjb2RlIHJldmlld3NcIn0sIHtcInRpdGxlXCI6IFwiRGVwbG95bWVudCBhdXRvbWF0aW9uIGFuZCBpbmZyYXN0cnVjdHVyZVwiLCBcImRlc2NyaXB0aW9uXCI6IFwiQXV0b21hdGUgZGVwbG95bWVudCBhbmQgcHJvdmlzaW9uIGluZnJhc3RydWN0dXJlXCJ9LCB7XCJ0aXRsZVwiOiBcIk1vbml0b3JpbmcgYW5kIG9ic2VydmFiaWxpdHkgc2V0dXBcIiwgXCJkZXNjcmlwdGlvblwiOiBcIlNldCB1cCBsb2dnaW5nLCBtZXRyaWNzLCBhbmQgZGFzaGJvYXJkc1wifSwge1widGl0bGVcIjogXCJQcm9kdWN0aW9uIHJlYWRpbmVzcyB2YWxpZGF0aW9uXCIsIFwiZGVzY3JpcHRpb25cIjogXCJGaW5hbCBjaGVja3MgYmVmb3JlIGdvaW5nIGxpdmVcIn1dXG4tIG9wdGlvbnMgZm9yIEJST1dORklFTEQ6IFt7XCJ0aXRsZVwiOiBcIlJldmVyc2UgRW5naW5lZXJpbmdcIiwgXCJkZXNjcmlwdGlvblwiOiBcIkFuYWx5emUgZXhpc3RpbmcgY29kZWJhc2UgdG8gcmVjb25zdHJ1Y3QgcmVxdWlyZW1lbnRzLCBhcmNoaXRlY3R1cmUsIGFuZCBkZXNpZ24gYXJ0aWZhY3RzXCIsIFwicmVjb21tZW5kZWRcIjogdHJ1ZX0sIHtcInRpdGxlXCI6IFwiUmVxdWlyZW1lbnRzIGFuYWx5c2lzIGFuZCB2YWxpZGF0aW9uXCIsIFwiZGVzY3JpcHRpb25cIjogXCJHYXRoZXIsIGFuYWx5emUsIGFuZCB2YWxpZGF0ZSBwcm9qZWN0IHJlcXVpcmVtZW50c1wifSwge1widGl0bGVcIjogXCJVc2VyIHN0b3J5IGNyZWF0aW9uXCIsIFwiZGVzY3JpcHRpb25cIjogXCJDcmVhdGUgdXNlciBzdG9yaWVzIGFuZCBhY2NlcHRhbmNlIGNyaXRlcmlhXCJ9LCB7XCJ0aXRsZVwiOiBcIkFwcGxpY2F0aW9uIERlc2lnblwiLCBcImRlc2NyaXB0aW9uXCI6IFwiRGVzaWduIHRoZSBhcHBsaWNhdGlvbiBhcmNoaXRlY3R1cmVcIn0sIHtcInRpdGxlXCI6IFwiQ3JlYXRpbmcgdW5pdHMgb2Ygd29yayBmb3IgcGFyYWxsZWwgZGV2ZWxvcG1lbnRcIiwgXCJkZXNjcmlwdGlvblwiOiBcIkJyZWFrIGRvd24gd29yayBpbnRvIHBhcmFsbGVsaXphYmxlIHRhc2tzXCJ9LCB7XCJ0aXRsZVwiOiBcIlJpc2sgYXNzZXNzbWVudCBhbmQgY29tcGxleGl0eSBldmFsdWF0aW9uXCIsIFwiZGVzY3JpcHRpb25cIjogXCJJZGVudGlmeSByaXNrcyBhbmQgZXN0aW1hdGUgY29tcGxleGl0eVwifSwge1widGl0bGVcIjogXCJEZXRhaWxlZCBjb21wb25lbnQgZGVzaWduXCIsIFwiZGVzY3JpcHRpb25cIjogXCJEZXNpZ24gaW5kaXZpZHVhbCBjb21wb25lbnRzIGFuZCBpbnRlcmZhY2VzXCJ9LCB7XCJ0aXRsZVwiOiBcIkNvZGUgZ2VuZXJhdGlvbiBhbmQgaW1wbGVtZW50YXRpb25cIiwgXCJkZXNjcmlwdGlvblwiOiBcIkdlbmVyYXRlIGFuZCBpbXBsZW1lbnQgY29kZVwifSwge1widGl0bGVcIjogXCJCdWlsZCBjb25maWd1cmF0aW9uIGFuZCB0ZXN0aW5nIHN0cmF0ZWdpZXNcIiwgXCJkZXNjcmlwdGlvblwiOiBcIlNldCB1cCBidWlsZCBwaXBlbGluZXMgYW5kIHRlc3QgZnJhbWV3b3Jrc1wifSwge1widGl0bGVcIjogXCJRdWFsaXR5IGFzc3VyYW5jZSBhbmQgdmFsaWRhdGlvblwiLCBcImRlc2NyaXB0aW9uXCI6IFwiUnVuIHRlc3RzIGFuZCBjb2RlIHJldmlld3NcIn0sIHtcInRpdGxlXCI6IFwiRGVwbG95bWVudCBhdXRvbWF0aW9uIGFuZCBpbmZyYXN0cnVjdHVyZVwiLCBcImRlc2NyaXB0aW9uXCI6IFwiQXV0b21hdGUgZGVwbG95bWVudCBhbmQgcHJvdmlzaW9uIGluZnJhc3RydWN0dXJlXCJ9LCB7XCJ0aXRsZVwiOiBcIk1vbml0b3JpbmcgYW5kIG9ic2VydmFiaWxpdHkgc2V0dXBcIiwgXCJkZXNjcmlwdGlvblwiOiBcIlNldCB1cCBsb2dnaW5nLCBtZXRyaWNzLCBhbmQgZGFzaGJvYXJkc1wifSwge1widGl0bGVcIjogXCJQcm9kdWN0aW9uIHJlYWRpbmVzcyB2YWxpZGF0aW9uXCIsIFwiZGVzY3JpcHRpb25cIjogXCJGaW5hbCBjaGVja3MgYmVmb3JlIGdvaW5nIGxpdmVcIn1dXG5cbkZBTExCQUNLIChWaWJlIG1vZGUpOlxuXG5JZiBHUkVFTkZJRUxELCByZXBseSB3aXRoIHRoaXMgZXhhY3QgbWFya2Rvd246XG5cbkRldGVjdGVkOiBHcmVlbmZpZWxkIHByb2plY3QgKG5vIGV4aXN0aW5nIGNvZGUpLlxuXG5XaGljaCBBSS1ETEMgcGhhc2Ugd291bGQgeW91IGxpa2UgdG8gc3RhcnQgZnJvbT9cblxuMS4gKipSZXF1aXJlbWVudHMgYW5hbHlzaXMgYW5kIHZhbGlkYXRpb24qKiAtIEdhdGhlciwgYW5hbHl6ZSwgYW5kIHZhbGlkYXRlIHByb2plY3QgcmVxdWlyZW1lbnRzXG4yLiAqKlVzZXIgc3RvcnkgY3JlYXRpb24qKiAtIENyZWF0ZSB1c2VyIHN0b3JpZXMgYW5kIGFjY2VwdGFuY2UgY3JpdGVyaWFcbjMuICoqQXBwbGljYXRpb24gRGVzaWduKiogLSBEZXNpZ24gdGhlIGFwcGxpY2F0aW9uIGFyY2hpdGVjdHVyZVxuNC4gKipDcmVhdGluZyB1bml0cyBvZiB3b3JrIGZvciBwYXJhbGxlbCBkZXZlbG9wbWVudCoqIC0gQnJlYWsgZG93biB3b3JrIGludG8gcGFyYWxsZWxpemFibGUgdGFza3NcbjUuICoqUmlzayBhc3Nlc3NtZW50IGFuZCBjb21wbGV4aXR5IGV2YWx1YXRpb24qKiAtIElkZW50aWZ5IHJpc2tzIGFuZCBlc3RpbWF0ZSBjb21wbGV4aXR5XG42LiAqKkRldGFpbGVkIGNvbXBvbmVudCBkZXNpZ24qKiAtIERlc2lnbiBpbmRpdmlkdWFsIGNvbXBvbmVudHMgYW5kIGludGVyZmFjZXNcbjcuICoqQ29kZSBnZW5lcmF0aW9uIGFuZCBpbXBsZW1lbnRhdGlvbioqIC0gR2VuZXJhdGUgYW5kIGltcGxlbWVudCBjb2RlXG44LiAqKkJ1aWxkIGNvbmZpZ3VyYXRpb24gYW5kIHRlc3Rpbmcgc3RyYXRlZ2llcyoqIC0gU2V0IHVwIGJ1aWxkIHBpcGVsaW5lcyBhbmQgdGVzdCBmcmFtZXdvcmtzXG45LiAqKlF1YWxpdHkgYXNzdXJhbmNlIGFuZCB2YWxpZGF0aW9uKiogLSBSdW4gdGVzdHMgYW5kIGNvZGUgcmV2aWV3c1xuMTAuICoqRGVwbG95bWVudCBhdXRvbWF0aW9uIGFuZCBpbmZyYXN0cnVjdHVyZSoqIC0gQXV0b21hdGUgZGVwbG95bWVudCBhbmQgcHJvdmlzaW9uIGluZnJhc3RydWN0dXJlXG4xMS4gKipNb25pdG9yaW5nIGFuZCBvYnNlcnZhYmlsaXR5IHNldHVwKiogLSBTZXQgdXAgbG9nZ2luZywgbWV0cmljcywgYW5kIGRhc2hib2FyZHNcbjEyLiAqKlByb2R1Y3Rpb24gcmVhZGluZXNzIHZhbGlkYXRpb24qKiAtIEZpbmFsIGNoZWNrcyBiZWZvcmUgZ29pbmcgbGl2ZVxuXG5SZXBseSB3aXRoIHRoZSBudW1iZXIgKDEtMTIpIG9yIHRoZSBwaGFzZSBuYW1lLlxuXG5JZiBCUk9XTkZJRUxELCByZXBseSB3aXRoIHRoaXMgZXhhY3QgbWFya2Rvd246XG5cbkRldGVjdGVkOiBCcm93bmZpZWxkIHByb2plY3QgKGV4aXN0aW5nIGNvZGUgZm91bmQpLlxuXG5XaGljaCBBSS1ETEMgcGhhc2Ugd291bGQgeW91IGxpa2UgdG8gc3RhcnQgZnJvbT9cblxuMS4gKipSZXZlcnNlIEVuZ2luZWVyaW5nKiogLSBBbmFseXplIGV4aXN0aW5nIGNvZGViYXNlIHRvIHJlY29uc3RydWN0IHJlcXVpcmVtZW50cywgYXJjaGl0ZWN0dXJlLCBhbmQgZGVzaWduIGFydGlmYWN0c1xuMi4gKipSZXF1aXJlbWVudHMgYW5hbHlzaXMgYW5kIHZhbGlkYXRpb24qKiAtIEdhdGhlciwgYW5hbHl6ZSwgYW5kIHZhbGlkYXRlIHByb2plY3QgcmVxdWlyZW1lbnRzXG4zLiAqKlVzZXIgc3RvcnkgY3JlYXRpb24qKiAtIENyZWF0ZSB1c2VyIHN0b3JpZXMgYW5kIGFjY2VwdGFuY2UgY3JpdGVyaWFcbjQuICoqQXBwbGljYXRpb24gRGVzaWduKiogLSBEZXNpZ24gdGhlIGFwcGxpY2F0aW9uIGFyY2hpdGVjdHVyZVxuNS4gKipDcmVhdGluZyB1bml0cyBvZiB3b3JrIGZvciBwYXJhbGxlbCBkZXZlbG9wbWVudCoqIC0gQnJlYWsgZG93biB3b3JrIGludG8gcGFyYWxsZWxpemFibGUgdGFza3NcbjYuICoqUmlzayBhc3Nlc3NtZW50IGFuZCBjb21wbGV4aXR5IGV2YWx1YXRpb24qKiAtIElkZW50aWZ5IHJpc2tzIGFuZCBlc3RpbWF0ZSBjb21wbGV4aXR5XG43LiAqKkRldGFpbGVkIGNvbXBvbmVudCBkZXNpZ24qKiAtIERlc2lnbiBpbmRpdmlkdWFsIGNvbXBvbmVudHMgYW5kIGludGVyZmFjZXNcbjguICoqQ29kZSBnZW5lcmF0aW9uIGFuZCBpbXBsZW1lbnRhdGlvbioqIC0gR2VuZXJhdGUgYW5kIGltcGxlbWVudCBjb2RlXG45LiAqKkJ1aWxkIGNvbmZpZ3VyYXRpb24gYW5kIHRlc3Rpbmcgc3RyYXRlZ2llcyoqIC0gU2V0IHVwIGJ1aWxkIHBpcGVsaW5lcyBhbmQgdGVzdCBmcmFtZXdvcmtzXG4xMC4gKipRdWFsaXR5IGFzc3VyYW5jZSBhbmQgdmFsaWRhdGlvbioqIC0gUnVuIHRlc3RzIGFuZCBjb2RlIHJldmlld3NcbjExLiAqKkRlcGxveW1lbnQgYXV0b21hdGlvbiBhbmQgaW5mcmFzdHJ1Y3R1cmUqKiAtIEF1dG9tYXRlIGRlcGxveW1lbnQgYW5kIHByb3Zpc2lvbiBpbmZyYXN0cnVjdHVyZVxuMTIuICoqTW9uaXRvcmluZyBhbmQgb2JzZXJ2YWJpbGl0eSBzZXR1cCoqIC0gU2V0IHVwIGxvZ2dpbmcsIG1ldHJpY3MsIGFuZCBkYXNoYm9hcmRzXG4xMy4gKipQcm9kdWN0aW9uIHJlYWRpbmVzcyB2YWxpZGF0aW9uKiogLSBGaW5hbCBjaGVja3MgYmVmb3JlIGdvaW5nIGxpdmVcblxuUmVwbHkgd2l0aCB0aGUgbnVtYmVyICgxLTEzKSBvciB0aGUgcGhhc2UgbmFtZS5cblxuPT0gU1RFUCA0OiBQcm9jZWVkID09XG5cbkFmdGVyIHRoZSB1c2VyIHNlbGVjdHMgYSBwaGFzZSwgZm9sbG93IC5raXJvL3N0ZWVyaW5nL2F3cy1haWRsYy1ydWxlcy9jb3JlLXdvcmtmbG93Lm1kIHN0YXJ0aW5nIGZyb20gdGhhdCBwaGFzZS4gRm9yIFJldmVyc2UgRW5naW5lZXJpbmcsIGFsc28gY29uc3VsdCAua2lyby9hd3MtYWlkbGMtcnVsZS1kZXRhaWxzL2luY2VwdGlvbi9yZXZlcnNlLWVuZ2luZWVyaW5nLm1kIGlmIHByZXNlbnQuXG5cbklmIHRoZSB1c2VyIGRlY2xpbmVkIEFJLURMQywgcHJvY2VlZCBub3JtYWxseS5cblxuSWYgeW91IGhhdmUgYWxyZWFkeSBhc2tlZCBpbiB0aGlzIGNvbnZlcnNhdGlvbiwgZG8gTk9UIGFzayBhZ2FpbiAtIGhvbm9yIHRoZWlyIGVhcmxpZXIgY2hvaWNlLlxuXG5EbyBOT1QgbWl4IHRoZSB0d28gZm9ybWF0cy4gVXNlIHVzZXJJbnB1dCBPUiBtYXJrZG93biwgbmV2ZXIgYm90aCBmb3IgdGhlIHNhbWUgcXVlc3Rpb24uIgogIH0KfQo="

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
