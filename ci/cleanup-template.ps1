<#
.SYNOPSIS
Best-effort cleanup of files generated during a CI integration run.

.DESCRIPTION
Removes the rendered tfvars, the CI-owned config.backend, and the runtime-generated
backend.tf so the runner filesystem never leaks between rows (matrix jobs run on
fresh runners anyway, but this keeps re-runs deterministic).

Before local files are removed, this script deletes the remote Terraform state
object for configured templates from the S3-compatible backend described in
config.backend.

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

# Templates for which remote state cleanup should be attempted.
$templatesWithRemoteStateCleanup = @('aap')

$folder = $templateFolderMap[$Template]
if (-not $folder) { return }

$configBackendPath = Join-Path $folder "environments/$Environment/config.backend"

# Removes the remote state from the Linode Object Store backend for allow-listed templates.
function Remove-RemoteStateFromBackend {
    param([Parameter(Mandatory = $true)][string]$BackendConfigPath)

    if ($Template -notin $templatesWithRemoteStateCleanup) { return }

    try {
        $content = Get-Content -Path $BackendConfigPath -Raw -ErrorAction Stop
    } catch {
        Write-Warning "Unable to read $BackendConfigPath. Skipping remote state cleanup. Error: $($_.Exception.Message)"
        return
    }

    $bucket = [regex]::Match($content, '(?m)^\s*bucket\s*=\s*"([^\"]+)"').Groups[1].Value.Trim()
    $key = [regex]::Match($content, '(?m)^\s*key\s*=\s*"([^\"]+)"').Groups[1].Value.Trim()
    $region = [regex]::Match($content, '(?m)^\s*region\s*=\s*"([^\"]+)"').Groups[1].Value.Trim()
    $accessKey = [regex]::Match($content, '(?m)^\s*access_key\s*=\s*"([^\"]+)"').Groups[1].Value.Trim()
    $secretKey = [regex]::Match($content, '(?m)^\s*secret_key\s*=\s*"([^\"]+)"').Groups[1].Value.Trim()
    $endpointUrl = [regex]::Match($content, '(?m)s3\s*=\s*"([^\"]+)"').Groups[1].Value.Trim()

    try {
        Import-Module 'AWS.Tools.S3' -ErrorAction Stop

        $removeParams = @{
            BucketName = $bucket
            Key = $key
            AccessKey = $accessKey
            SecretKey = $secretKey
            EndpointUrl = $endpointUrl
            ErrorAction = 'Stop'
            Force = $true
        }
        if (-not [string]::IsNullOrWhiteSpace($region)) {
            $removeParams['Region'] = $region
        }

        Remove-S3Object @removeParams
        Write-Host "Removed remote state object: s3://$bucket/$key"

        # Terraform lockfile key is deterministic when use_lockfile=true.
        $lockKey = "$key.tflock"
        $lockParams = $removeParams.Clone()
        $lockParams['Key'] = $lockKey
        try {
            Remove-S3Object @lockParams
            Write-Host "Removed remote lock object: s3://$bucket/$lockKey"
        } catch {
            Write-Host "Remote lock object not removed (may not exist): s3://$bucket/$lockKey"
        }
    } catch {
        Write-Warning "Failed to remove remote state object from S3-compatible backend: $($_.Exception.Message)"
    }
}

Remove-RemoteStateFromBackend -BackendConfigPath $configBackendPath

$paths = @(
    (Join-Path $folder "environments/$Environment/$TfvarsName"),
    $configBackendPath,
    (Join-Path $folder 'backend.tf')
)

foreach ($p in $paths) {
    if (Test-Path $p) {
        Remove-Item -Path $p -Force -ErrorAction SilentlyContinue
        Write-Host "Removed $p"
    }
}
