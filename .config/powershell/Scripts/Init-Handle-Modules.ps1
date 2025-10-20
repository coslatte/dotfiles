<# SCRIPT FOR INSTALLING, UPDATING, AND MANAGING POWERSHELL MODULES. #>

function Install-ModuleIfNeeded {
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        [Version]$MinimumVersion
    )
    try {
        $installedModule = Get-InstalledModule -Name $Name -ErrorAction SilentlyContinue
        $needsInstall = -not $installedModule -or (
            $MinimumVersion -and $installedModule.Version -lt $MinimumVersion
        )

        if ($needsInstall) {
            if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
                Install-PackageProvider -Name NuGet -Force -Scope CurrentUser -ErrorAction Stop | Out-Null
            }
            Install-Module -Name $Name -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop | Out-Null
            $action = if ($installedModule) { 'Updated' } else { 'Installed' }
            $ver = (Get-InstalledModule -Name $Name -ErrorAction SilentlyContinue).Version
            Write-Host "[OK] $action $Name ($ver)"
        }
        else {
            Write-Host "[OK] Up-to-date $Name ($($installedModule.Version))"
        }
    }
    catch {
        Write-Warning "[FAIL] $Name - $($_.Exception.Message)"
    }
}

# MODULESSSS
$ModulesToEnsure = @(
    @{ Name = 'PSReadLine'; MinimumVersion = '2.1.0' }
    @{ Name = 'Terminal-Icons' }
    # @{ Name = 'module' }
)

foreach ($m in $ModulesToEnsure) { Install-ModuleIfNeeded @m }
