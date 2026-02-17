<#
.SYNOPSIS
Logging and output formatting functions

.DESCRIPTION
Provides consistent logging and output across all templates
#>

function Enable-TerraformDebugLogging {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$LogPath
    )
    
    Write-Host "Debug mode enabled - Logging to: $LogPath" -ForegroundColor Yellow
    $env:TF_LOG = "DEBUG"
    $env:TF_LOG_PATH = $LogPath
    $env:AKAMAI_HTTP_TRACE_ENABLED = "true"
}

function Disable-TerraformDebugLogging {
    [CmdletBinding()]
    param()
    
    $env:TF_LOG = $null
    $env:TF_LOG_PATH = $null
    $env:AKAMAI_HTTP_TRACE_ENABLED = $null
}

function Write-ExecutionSummary {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [datetime]$StartTime
    )
    
    $endTime = Get-Date
    $duration = $endTime - $StartTime
    
    Write-Host ""
    Write-Host "================================" -ForegroundColor Green
    Write-Host "Script Execution Summary" -ForegroundColor Green
    Write-Host "================================" -ForegroundColor Green
    Write-Host "Started:  $($StartTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Cyan
    Write-Host "Finished: $($endTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Cyan
    Write-Host "Total Duration: $($duration.ToString('hh\:mm\:ss'))" -ForegroundColor Yellow
    Write-Host "================================" -ForegroundColor Green
}

function Get-Username {
    [CmdletBinding()]
    param()
    
    $platform = $PSVersionTable.Platform
    if (-not $platform -or $platform -eq 'Win32NT') {
        return $env:USERNAME
    }
    else {
        return $env:USER
    }
}

Export-ModuleMember -Function Enable-TerraformDebugLogging, Disable-TerraformDebugLogging, Write-ExecutionSummary, Get-Username
