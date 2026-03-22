@echo off
REM Atlas Command Watcher - Windows Batch Script
REM This script polls a GitHub repo for commands and executes them
REM Run this in the background on your Windows machine

setlocal enabledelayedexpansion

REM Configuration
set REPO_PATH=C:\atlas-commands
set SERVICE_URL=http://127.0.0.1:9999/execute-primitive
set POLL_INTERVAL=5

REM Check if repo exists
if not exist "%REPO_PATH%" (
    echo Cloning atlas-commands repo...
    cd C:\
    git clone https://github.com/YOUR_USERNAME/atlas-commands.git
    cd "%REPO_PATH%"
) else (
    cd "%REPO_PATH%"
)

echo.
echo ========================================
echo Atlas Command Watcher Started
echo Polling every %POLL_INTERVAL% seconds
echo Service: %SERVICE_URL%
echo ========================================
echo.

:loop
REM Pull latest commands from GitHub
git pull origin master >nul 2>&1

REM Look for command files (cmd-*.json)
for %%F in (cmd-*.json) do (
    if exist "%%F" (
        echo [%date% %time%] Executing: %%F
        
        REM Execute the command using PowerShell
        powershell -NoProfile -Command "^
            $json = Get-Content '%%F' | ConvertFrom-Json; ^
            foreach ($cmd in $json.commands) { ^
                $body = $cmd | ConvertTo-Json; ^
                try { ^
                    $resp = Invoke-WebRequest -Uri '%SERVICE_URL%' -Method POST -Headers @{'Content-Type'='application/json'} -Body $body; ^
                    Write-Host 'Executed: ' $cmd.primitive; ^
                } catch { ^
                    Write-Host 'Error: ' $_.Exception.Message; ^
                } ^
            } ^
        "
        
        REM Delete the command file after execution
        del "%%F"
        echo [%date% %time%] Completed: %%F
        echo.
    )
)

REM Wait before next poll
timeout /t %POLL_INTERVAL% /nobreak

goto loop
