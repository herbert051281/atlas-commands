# Atlas Command Watcher - PowerShell Script
# Polls GitHub repo for commands and executes them on Windows

# Configuration
$REPO_PATH = "C:\atlas-commands"
$SERVICE_URL = "http://127.0.0.1:9999/execute-primitive"
$POLL_INTERVAL = 5

Write-Host ""
Write-Host "========================================"
Write-Host "Atlas Command Watcher Started"
Write-Host "Polling every $POLL_INTERVAL seconds"
Write-Host "Service: $SERVICE_URL"
Write-Host "========================================"
Write-Host ""

# Ensure we're in the repo directory
if (-not (Test-Path $REPO_PATH)) {
    Write-Host "ERROR: Repo not found at $REPO_PATH"
    Write-Host "Please clone: git clone https://github.com/herbert051281/atlas-commands.git"
    exit 1
}

Set-Location $REPO_PATH

$loop = $true
while ($loop) {
    # Pull latest commands from GitHub
    try {
        git pull origin master > $null 2>&1
    } catch {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Git pull failed: $_"
    }

    # Look for command files (cmd-*.json)
    $commandFiles = Get-ChildItem -Filter "cmd-*.json" -ErrorAction SilentlyContinue

    foreach ($file in $commandFiles) {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Executing: $($file.Name)"
        
        try {
            # Read the command file
            $json = Get-Content $file.FullName | ConvertFrom-Json
            
            # Execute each command
            foreach ($cmd in $json.commands) {
                # Determine the endpoint based on command type
                $endpoint = $SERVICE_URL
                if ($cmd.type -eq "operation") {
                    $endpoint = $endpoint -replace "/execute-primitive", "/execute-operation"
                }
                
                $body = $cmd | ConvertTo-Json -Compress
                
                try {
                    $response = Invoke-WebRequest -Uri $endpoint `
                        -Method POST `
                        -Headers @{"Content-Type"="application/json"} `
                        -Body $body `
                        -TimeoutSec 10
                    
                    $cmdName = if ($cmd.primitive) { $cmd.primitive } else { $cmd.operation }
                    Write-Host "  ✓ Executed: $cmdName"
                } catch {
                    Write-Host "  ✗ Error: $($_.Exception.Message)"
                }
            }
            
            # Delete the command file after execution
            Remove-Item $file.FullName -Force
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Completed: $($file.Name)"
            Write-Host ""
        } catch {
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Error processing $($file.Name): $_"
        }
    }

    # Wait before next poll
    Start-Sleep -Seconds $POLL_INTERVAL
}
