[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
param()
$ErrorActionPreference = 'Stop'

function Refresh-PathFromRegistry {
    try {
        $machine = [System.Environment]::GetEnvironmentVariable('Path', 'Machine')
        $user    = [System.Environment]::GetEnvironmentVariable('Path', 'User')
        $paths = @()
        if ($machine) { $paths += $machine }
        if ($user)    { $paths += $user }
        if ($paths.Count -gt 0) { $env:Path = ($paths -join ';') }
    } catch { Write-Verbose "Failed to refresh PATH: $_" }
}

function Ensure-GitInstalled {
    if (Get-Command git -ErrorAction SilentlyContinue) { return $true }

    Write-Warning "Git not found in PATH."

    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Error "winget is not available. Install 'App Installer' from Microsoft Store to get winget, then re-run this script."
        return $false
    }

    if ($PSCmdlet.ShouldProcess('Git', 'Install via winget')) {
        Write-Host "Installing Git via winget..." -ForegroundColor Cyan
        try {
            # Exact ID, accept agreements to avoid prompts
            winget install --id Git.Git -e --source winget --accept-source-agreements --accept-package-agreements | Out-Host
        } catch {
            Write-Error "winget failed to install Git: $_"
            return $false
        }

        # After install, refresh PATH for current session and re-check
        Refresh-PathFromRegistry
        if (Get-Command git -ErrorAction SilentlyContinue) { return $true }

        # Fallback: common install path
        $gitCmdPath = "C:\\Program Files\\Git\\cmd"
        if (Test-Path $gitCmdPath) {
            $env:Path = "$gitCmdPath;" + $env:Path
        }
    }
    return [bool](Get-Command git -ErrorAction SilentlyContinue)
}

# Ensure Git exists (install if missing)
$gitReady = Ensure-GitInstalled
if (-not $gitReady) { Write-Error "Git is not available. Could not proceed with alias creation."; exit 1 }

# MAIN HASHTABLE OF ALIASES
$aliases = @{
    s    = 'status'
    st   = 'status -sb'
    co   = 'checkout'
    sw   = 'switch'
    br   = 'branch'
    ci   = 'commit'
    cm   = 'commit -m'
    cam  = 'commit -am'
    aa   = 'add -A'
    ap   = 'add -p'
    lg   = 'log --oneline --graph --decorate --all'
    last = 'log -1 HEAD'
}

$changedCount = 0
foreach ($name in $aliases.Keys | Sort-Object) {
    $desired = $aliases[$name]
    $current = git config --global --get "alias.$name" 2>$null
    if ($current -eq $desired) {
        Write-Host ("alias.{0} already set to: {1}" -f $name, $desired) -ForegroundColor DarkGray
    }
    else {
        if ($WhatIf) {
            Write-Host ("Would set alias.{0} -> {1}" -f $name, $desired) -ForegroundColor Yellow
        }
        else {
            if ($PSCmdlet.ShouldProcess("alias.$name", "Set to '$desired'")) {
                git config --global "alias.$name" "$desired"
                Write-Host ("Set alias.{0} -> {1}" -f $name, $desired) -ForegroundColor Green
                $changedCount++
            }
        }
    }
}

Write-Host ""
Write-Host "Current aliases:" -ForegroundColor Cyan
git config --global --get-regexp '^alias\.' 2>$null | Out-Host

if ($WhatIfPreference) {
    Write-Host "WhatIf: simulation only; no changes were made." -ForegroundColor Yellow
} else {
    if ($changedCount -gt 0) {
        Write-Host ("Updated {0} alias(es)." -f $changedCount) -ForegroundColor Green
    } else {
        Write-Host "No aliases changed; everything already up to date." -ForegroundColor DarkGray
    }
}

exit 0
