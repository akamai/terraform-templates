<#
.SYNOPSIS
Best-effort cleanup of files generated during a CI integration run.

.DESCRIPTION
Removes the rendered tfvars, the CI-owned config.backend, and the runtime-generated
backend.tf so the runner filesystem never leaks between rows (matrix jobs run on
fresh runners anyway, but this keeps re-runs deterministic).

Called with `if: always()` in the workflow.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Template,
    [Parameter(Mandatory = $true)][string]$Environment,
    [Parameter(Mandatory = $true)][string]$TfvarsName
)

$ErrorActionPreference = 'Continue'

$templateFolderMap = @{
    aap    = 'new-aap-configuration'
    aapasm = 'new-aapasm-configuration'
    pm     = 'new-property'
    bmp    = 'new-bmp-endpoints'
    edns   = 'new-edns'
    ds2    = 'new-ds2'
}

$folder = $templateFolderMap[$Template]
if (-not $folder) { return }

$paths = @(
    (Join-Path $folder "environments/$Environment/$TfvarsName"),
    (Join-Path $folder "environments/$Environment/config.backend"),
    (Join-Path $folder 'backend.tf')
)

foreach ($p in $paths) {
    if (Test-Path $p) {
        Remove-Item -Path $p -Force -ErrorAction SilentlyContinue
        Write-Host "Removed $p"
    }
}
