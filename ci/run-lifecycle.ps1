<#
.SYNOPSIS
Drive one deploy → destroy lifecycle for a single template row against the sandbox.

.DESCRIPTION
Called from the integration workflow for both the Deploy and Destroy phases. Always
passes the CI-safe flags (-Force -BackendType s3, notes stamped with the run id).
Handles the BMP two-phase variant (Phase 1 API def → Phase 2 sec config) as a single
sequential step.

Interactive prompts are suppressed via env vars set before invoking deploy.ps1:
  CI_AUTO_CONFIRM_DESTROY=1   — honored by Confirm-DestroyOperation
  TF_BACKEND_TYPE=s3          — also set by deploy.ps1 param, safety net
  TF_INPUT=false              — honored by terraform for provider prompts

.PARAMETER Phase
'Deploy' (save + activate staging) or 'Destroy'.

.PARAMETER Template
Template short name.

.PARAMETER Environment
Environment folder (typically 'test').

.PARAMETER Variant
Optional variant token:
  'primary' | 'secondary' → EDNS zone type
  'two-phase'            → BMP dual-phase deploy
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][ValidateSet('Deploy','Destroy')][string]$Phase,
    [Parameter(Mandatory = $true)][string]$Template,
    [Parameter(Mandatory = $true)][string]$Environment,
    [Parameter(Mandatory = $false)][string]$Variant = '',
    [Parameter(Mandatory = $true)][string]$RunId
)

$ErrorActionPreference = 'Stop'

$env:CI_AUTO_CONFIRM_DESTROY = '1'
$env:TF_BACKEND_TYPE         = 's3'
$env:TF_INPUT                = 'false'

$notes = "ci-$RunId"
$commonArgs = @('-Env', $Environment, '-Force', '-BackendType', 's3', '-Notes', $notes)

# EDNS needs -ZoneType regardless of phase.
if ($Template -eq 'edns') {
    if ($Variant -notin @('primary','secondary')) {
        throw "EDNS row requires Variant 'primary' or 'secondary' (got '$Variant')."
    }
    $commonArgs += @('-ZoneType', $Variant)
}

function Invoke-Deploy {
    if ($Phase -ne 'Deploy') { return }

    if ($Template -eq 'bmp' -and $Variant -eq 'two-phase') {
        Write-Host "BMP two-phase deploy: Phase 1 (API def) → Phase 2 (sec config)"
        & ./deploy.ps1 bmp @commonArgs -ActivateStagingApi
        if ($LASTEXITCODE -ne 0) { throw "BMP Phase 1 (API) failed with exit code $LASTEXITCODE" }

        & ./deploy.ps1 bmp @commonArgs -ActivateStagingSec
        if ($LASTEXITCODE -ne 0) { throw "BMP Phase 2 (Sec) failed with exit code $LASTEXITCODE" }
        return
    }

    if ($Template -eq 'ds2') {
        # DS2 activation is driven by the tfvars 'activate_stream' value. Save-only is enough.
        & ./deploy.ps1 ds2 @commonArgs -Save
    } else {
        & ./deploy.ps1 $Template @commonArgs -ActivateStaging
    }
    if ($LASTEXITCODE -ne 0) { throw "$Template deploy failed with exit code $LASTEXITCODE" }
}

function Invoke-Destroy {
    if ($Phase -ne 'Destroy') { return }

    # Single -Destroy call works for every template (BMP module tears down both phases).
    & ./deploy.ps1 $Template @commonArgs -Destroy
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "$Template destroy exited with $LASTEXITCODE — investigate orphans in the sandbox."
        exit $LASTEXITCODE
    }
}

Invoke-Deploy
Invoke-Destroy
