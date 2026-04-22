@echo off
REM Remove AI-DLC steering files from a Kiro workspace.
REM Usage: remove-aidlc.bat [workspace-path]
setlocal

set "WORKSPACE=%~1"
if "%WORKSPACE%"=="" set "WORKSPACE=%CD%"

set "STEERING=%WORKSPACE%\.kiro\steering\aws-aidlc-rules"
set "DETAILS=%WORKSPACE%\.kiro\aws-aidlc-rule-details"

echo ==^> Removing AI-DLC from Kiro workspace
echo     Workspace: %WORKSPACE%

set "REMOVED=0"
if exist "%STEERING%\" (
    rmdir /s /q "%STEERING%"
    echo     Removed: %STEERING%
    set "REMOVED=1"
)
if exist "%DETAILS%\" (
    rmdir /s /q "%DETAILS%"
    echo     Removed: %DETAILS%
    set "REMOVED=1"
)

if "%REMOVED%"=="0" (
    echo     Nothing to remove — AI-DLC is not installed.
) else (
    echo ==^> Done. AI-DLC steering files removed.
)

endlocal
