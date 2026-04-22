@echo off
REM Check if AI-DLC steering files are installed in a Kiro workspace.
REM Usage: check-aidlc.bat [workspace-path]
setlocal

set "WORKSPACE=%~1"
if "%WORKSPACE%"=="" set "WORKSPACE=%CD%"

set "STEERING=%WORKSPACE%\.kiro\steering\aws-aidlc-rules"
set "DETAILS=%WORKSPACE%\.kiro\aws-aidlc-rule-details"
set "CORE=%STEERING%\core-workflow.md"

echo ==^> AI-DLC Status Check
echo     Workspace: %WORKSPACE%
echo.

set "HAS_STEERING=0"
set "HAS_DETAILS=0"
set "HAS_CORE=0"

if exist "%STEERING%\" set "HAS_STEERING=1"
if exist "%DETAILS%\" set "HAS_DETAILS=1"
if exist "%CORE%" set "HAS_CORE=1"

if "%HAS_STEERING%"=="1" if "%HAS_DETAILS%"=="1" if "%HAS_CORE%"=="1" (
    echo     Status: INSTALLED
    echo     Steering rules:  %STEERING%
    echo     Rule details:    %DETAILS%
    echo     Core workflow:   %CORE%
    goto :end
)

if "%HAS_STEERING%"=="1" (
    echo     Status: PARTIAL ^(some files missing^)
) else if "%HAS_DETAILS%"=="1" (
    echo     Status: PARTIAL ^(some files missing^)
) else (
    echo     Status: NOT INSTALLED
    goto :end
)

if "%HAS_STEERING%"=="1" (echo     [OK]      %STEERING%) else (echo     [MISSING] %STEERING%)
if "%HAS_DETAILS%"=="1"  (echo     [OK]      %DETAILS%)  else (echo     [MISSING] %DETAILS%)
if "%HAS_CORE%"=="1"     (echo     [OK]      %CORE%)     else (echo     [MISSING] %CORE%)

:end
endlocal
