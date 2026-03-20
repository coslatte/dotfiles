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

# kill process by port
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

# unix 'touch'
function touch($file) {
    if (Test-Path $file) {
        Set-ItemProperty -Path $file -Name LastWriteTime -Value (Get-Date)
    } else {
        New-Item -ItemType File -Path $file | Out-Null
    }
}

# adaptive listing
function lsa {
    param([Parameter(ValueFromRemainingArguments=$true)]$args)
    $items = if ($args) { Get-ChildItem @args } else { Get-ChildItem }
    if ($Host.UI.RawUI.WindowSize.Width -lt 60) {
        $items | Format-Wide -Property Name -AutoSize
    } else {
        $items | Format-Table -AutoSize
    }
}


# git commit shortcut
function Invoke-GitCommitWithPush {
    param(
        [Parameter(Mandatory=$true)][string]$Message,
        [switch]$Force,
        [switch]$Push
    )

    $Message = ($Message -replace "\r?\n"," ").Trim()
    if ([string]::IsNullOrWhiteSpace($Message)) {
        Write-Warning "Commit message is empty. Aborting."
        return 1
    }

    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Warning "git is not available in PATH."
        return 1
    }
    $isRepo = & git rev-parse --is-inside-work-tree 2>$null
    if ($LASTEXITCODE -ne 0 -or $isRepo -ne 'true') {
        Write-Warning "Not inside a Git repository. Aborting."
        return 1
    }

    $status = & git status --porcelain
    if (-not $status) {
        Write-Host "No changes detected to commit." -ForegroundColor Yellow
        return 0
    }

    & git add -A
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to stage changes (exit code $LASTEXITCODE)."
        return $LASTEXITCODE
    }

    if (-not $Force) {
        $rawConfirm = Read-Host "Sure to add -A and commit$([bool]$Push ? ' and push' : '')? [y/N]"
        $trimmed = $rawConfirm.Trim()
        $isWhitespaceOrEmpty = ([string]::IsNullOrWhiteSpace($rawConfirm)) -or ($rawConfirm -match '^[\t \f\v]+$')
        if (-not ($isWhitespaceOrEmpty -or ($trimmed -match '^[Yy](es)?$'))) {
            Write-Host "Operation cancelled by user." -ForegroundColor Yellow
            return 2
        }
    }

    & git commit -m $Message
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Commit failed (exit code $LASTEXITCODE)."
        return $LASTEXITCODE
    }

    if ($Push) {
        & git push
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Pushed to remote successfully." -ForegroundColor Green
            return 0
        } else {
            Write-Error "Push failed (exit code $LASTEXITCODE)."
            return $LASTEXITCODE
        }
    }

    Write-Host "Commit created successfully." -ForegroundColor Green
    return 0
}

# git add -A + commit
function gca {
    param(
        [Parameter(Mandatory=$true)][string]$Message,
        [switch]$Force
    )
    Invoke-GitCommitWithPush -Message $Message -Force:$Force -Push:$false | Out-Null
}

# git add -A + commit + push
function gcap {
    param(
        [Parameter(Mandatory=$true)][string]$Message,
        [switch]$Force
    )
    Invoke-GitCommitWithPush -Message $Message -Force:$Force -Push:$true | Out-Null
}

# hexadecimal reading for binary files with optional paging
function hd {
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Path,
        
        [Parameter(Position=1)]
        [int]$Count = 0
    )

    if (-not (Test-Path $Path)) {
        Write-Error "file not found: $Path"
        return
    }

    if ($Count -gt 0) {
        # display a specific number of bytes without paging
        Format-Hex -Path $Path -Count $Count
    } else {
        # display the entire file using the 'more' pager
        # space: next page | enter: next line | q: quit
        Format-Hex -Path $Path | more
    }
}
