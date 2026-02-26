# coslatte's PowerShell config :)

# Global settings
$env:POWERSHELL_UPDATECHECK = 'Off'
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# Modules
Import-Module PSReadLine -ErrorAction SilentlyContinue
Import-Module Terminal-Icons -ErrorAction SilentlyContinue

$ENV:STARSHIP_CONFIG = "$HOME\.config\starship\starship.toml"
Invoke-Expression (& starship init powershell --print-full-init | Out-String)

# Environment variables
$ENV:XDG_CONFIG_HOME = "$HOME\.config"
$ENV:OLLAMA_MODELS = ""

# PSReadLine configuration
if (Get-Module PSReadLine) {
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -PredictionViewStyle ListView
    Set-PSReadLineOption -AddToHistoryHandler {
        param ([string]$Line)
        return $Line -notmatch "^git"
    }
}

# --- Shortcuts & Functions ---

# Kill process by port
function kp($port) {
    $connections = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue | 
                   Where-Object { $_.OwningProcess -gt 0 }
    if ($connections) {
        foreach ($conn in $connections) {
            try {
                Stop-Process -Id $conn.OwningProcess -Force -ErrorAction Stop
                Write-Host "Process $($conn.OwningProcess) on port $port deleted." -ForegroundColor Green
            } catch {
                Write-Warning "Access denied to process $($conn.OwningProcess). Run as Admin."
            }
        }
    } else {
        Write-Warning "No process listening on port $port."
    }
}

# Unix 'touch'
function touch($file) {
    if (Test-Path $file) {
        Set-ItemProperty -Path $file -Name LastWriteTime -Value (Get-Date)
    } else {
        New-Item -ItemType File -Path $file | Out-Null
    }
}

# Change directory and list
function cdd($path = $PWD) {
    Set-Location $path
    ls
}

# Adaptive listing
function lsa {
    param([Parameter(ValueFromRemainingArguments=$true)]$path)
    $items = if ($path) { Get-ChildItem @path } else { Get-ChildItem }
    if ($Host.UI.RawUI.WindowSize.Width -lt 100) {
        $items | Format-Wide -Property Name -AutoSize
    } else {
        $items | Format-Table -AutoSize
    }
}

# Replace default ls with adaptive listing
if (Test-Path Alias:ls) { Remove-Item Alias:ls -Force }
Set-Alias -Name ls -Value lsa

# Dotfiles management
function dot {
    git --git-dir=$HOME\.dotfiles\ --work-tree=$HOME @args
}