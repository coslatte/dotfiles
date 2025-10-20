# coslatte's PowerShell config :)

# Suppress PowerShell update check notification
$env:POWERSHELL_UPDATECHECK = 'Off'

Import-Module PSReadLine -ErrorAction SilentlyContinue
Import-Module Terminal-Icons -ErrorAction SilentlyContinue

# ----------------------
# STARSHIP CONFIGURATION
# ----------------------
# INFO: Configure Starship prompt
#
$ENV:STARSHIP_CONFIG = "$HOME\.config\starship\.starship.toml"
$ENV:STARSHIP_CACHE = "$HOME\.config\starship\cache"
Invoke-Expression (& starship init powershell)

# --------------------
# NEOVIM CONFIGURATION
# --------------------
# INFO: Set Neovim configuration directory
#
$ENV:XDG_CONFIG_HOME = "$HOME\.config"

# --------------------
# OLLAMA CONFIGURATION
# --------------------
# INFO: Custom configurations for Ollama
#
$ENV:OLLAMA_MODELS = ""

# ------------------
# UTILITY FUNCTIONS!
# ------------------
# INFO: My custom utilities and stuff
#
function Update-TouchFile {
    <# Unix simulation 'touch' command. #>

    param (
        [Parameter(Mandatory = $true)]
        [string]$File
    )
    if (Test-Path $File) {
        Set-ItemProperty -Path $File -Name LastWriteTime -Value (Get-Date)
    }
    else {
        New-Item -ItemType File -Path $File | Out-Null
    }
}
Set-Alias -Name touch -Value Update-TouchFile

function Set-LocationAndList {
    <# Change directory and list contents #>

    param (
        [Parameter(Mandatory=$false, Position=0)]
        [string]$Path = $PWD
    )
    Set-Location $Path
    Get-ChildItem
}
Set-Alias -Name cdd -Value Set-LocationAndList

function Get-AdaptiveListing {
    <# Shows full info on wide terminals, compact on narrow ones #>

    param(
        [Parameter(ValueFromRemainingArguments=$true)]
        $Path
    )
    $termWidth = $Host.UI.RawUI.WindowSize.Width
    $items = if ($Path) { Get-ChildItem @Path } else { Get-ChildItem }
    
    if ($termWidth -lt 100) {
        # Compact mode: Name and icon only, in wide format (multiple columns)
        $items | Format-Wide -Property Name -AutoSize
    } else {
        # Full mode: Standard table with all info (Mode, Date, Size, Name with icons)
        $items | Format-Table -AutoSize
    }
}
Remove-Item Alias:ls -Force -ErrorAction SilentlyContinue
Set-Alias -Name ls -Value Get-AdaptiveListing
$PSDefaultParameterValues['Format-Table:AutoSize'] = $true  # Default format settings for tables

# PSReadLine settings
# -------------------
if (Get-Module PSReadLine) {
    Set-PSReadLineOption -PredictionSource History -ErrorAction SilentlyContinue
    Set-PSReadLineOption -PredictionViewStyle ListView -ErrorAction SilentlyContinue

    # Avoid adding 'git' commands to history
    Set-PSReadLineOption -AddToHistoryHandler {
        param ([string]$Line)
        if ($Line -match "^git") {
            return $false
        }
        return $true
    } -ErrorAction SilentlyContinue
} else {
    Write-Host "PSReadLine module not loaded; skipping configuration."
}

# Aliases
function dot {
    git --git-dir=$HOME\.dotfiles\ --work-tree=$HOME @args
}