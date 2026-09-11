<#
.SYNOPSIS
Build the GitHub Actions matrix for the integration workflow.

.DESCRIPTION
Reads env vars set by the workflow (event name, dispatch inputs, dorny/paths-filter outputs)
and emits `matrix=<json>` + `any=<bool>` to $GITHUB_OUTPUT. Every row includes the runtime
quirks needed by ci/prepare-template.ps1 and ci/run-lifecycle.ps1 (zone type for EDNS,
two-phase sentinel for BMP, expected tfvars filename, secret name to render, etc).

.NOTES
Consumed env vars:
  EVENT           github.event_name ('workflow_dispatch' | 'pull_request')
  INPUT_LIST      workflow_dispatch input 'templates' (comma-separated, empty = all)
  INPUT_ENV       workflow_dispatch input 'env' (defaults to 'test')
  CHANGE_AAP..CHANGE_DS2  'true' | 'false' from dorny/paths-filter
  CHANGE_SHARED   'true' when deploy.ps1 / lib/** / this workflow changed → run all
#>

$ErrorActionPreference = 'Stop'

# Canonical set of templates covered by the integration workflow. CPS is intentionally excluded.
$AllTemplates = @('aap','aapasm','pm','bmp','edns','ds2')

function Get-SelectedTemplates {
    $event = $env:EVENT
    if ($event -eq 'workflow_dispatch') {
        $raw = $env:INPUT_LIST
        if ([string]::IsNullOrWhiteSpace($raw)) { return $AllTemplates }
        return $raw.Split(',') | ForEach-Object { $_.Trim().ToLower() } | Where-Object { $_ -in $AllTemplates }
    }

    if ($env:CHANGE_SHARED -eq 'true') { return $AllTemplates }

    $selected = @()
    foreach ($t in $AllTemplates) {
        $flag = Get-Item -Path "env:CHANGE_$($t.ToUpper())" -ErrorAction SilentlyContinue
        if ($flag -and $flag.Value -eq 'true') { $selected += $t }
    }
    return $selected
}

function New-MatrixRow {
    param(
        [string]$Template,
        [string]$Env,
        [string]$TfvarsName,
        [string]$SecretName,
        [string]$Variant = ''
    )
    return [ordered]@{
        template   = $Template
        env        = $Env
        tfvarsName = $TfvarsName    # basename written under environments/<env>/
        secretName = $SecretName    # GitHub secret whose content is the tfvars body
        variant    = $Variant       # empty | 'primary' | 'secondary' (edns) | 'api'|'sec' (bmp phases)
    }
}

function Get-RowsForTemplate {
    param([string]$Template, [string]$Env)

    switch ($Template) {
        'edns' {
            # Two rows: primary + secondary. tfvars filename tracks the zone type.
            return @(
                (New-MatrixRow -Template 'edns' -Env $Env -TfvarsName 'primary-terraform'   -SecretName 'TFVARS_EDNS_PRIMARY'   -Variant 'primary'),
                (New-MatrixRow -Template 'edns' -Env $Env -TfvarsName 'secondary-terraform' -SecretName 'TFVARS_EDNS_SECONDARY' -Variant 'secondary')
            )
        }
        'bmp' {
            # Single row; run-lifecycle.ps1 executes Phase 1 then Phase 2 sequentially against the same tfvars.
            return @(
                (New-MatrixRow -Template 'bmp' -Env $Env -TfvarsName "$Env-terraform" -SecretName 'TFVARS_BMP' -Variant 'two-phase')
            )
        }
        default {
            $secret = "TFVARS_$($Template.ToUpper())"
            return @(
                (New-MatrixRow -Template $Template -Env $Env -TfvarsName "$Env-terraform" -SecretName $secret)
            )
        }
    }
}

$envName = if ($env:INPUT_ENV) { $env:INPUT_ENV } else { 'test' }
$templates = Get-SelectedTemplates

$rows = @()
foreach ($t in $templates) { $rows += Get-RowsForTemplate -Template $t -Env $envName }

$matrixJson = if ($rows.Count -gt 0) { ConvertTo-Json -Depth 5 -Compress -InputObject @($rows) } else { '[]' }
$any = if ($rows.Count -gt 0) { 'true' } else { 'false' }

Write-Host "Selected templates: $($templates -join ', ')"
Write-Host "Env: $envName"
Write-Host "Matrix rows: $($rows.Count)"
Write-Host "Matrix JSON: $matrixJson"

"matrix=$matrixJson" | Out-File -FilePath $env:GITHUB_OUTPUT -Append
"any=$any"           | Out-File -FilePath $env:GITHUB_OUTPUT -Append
