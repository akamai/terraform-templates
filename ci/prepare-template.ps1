<#
.SYNOPSIS
Prepare a template's env folder for a CI integration run.

.DESCRIPTION
For a single matrix row:
  1. Writes ~/.edgerc from the AKAMAI_EDGERC secret (idempotent per job).
  2. Verifies environments/<env>/ exists; skips the row cleanly if not.
  3. Materializes environments/<env>/<tfvarsName> from the matching TFVARS_* secret.
  4. Writes environments/<env>/config.backend for Linode Object Storage.
  5. Emits `skip=true` (or false) to $GITHUB_OUTPUT so the workflow can gate later steps.

CI runs deploy.ps1 with -BackendType s3, which triggers Initialize-TerraformBackend to
validate config.backend + write backend.tf. Locals are unaffected.

.PARAMETER Template
Template short name (aap|aapasm|pm|bmp|edns|ds2).

.PARAMETER Environment
Environment folder name (typically 'test').

.PARAMETER TfvarsName
Basename of the .tfvars file to write (e.g. 'test.tfvars', 'test-primary.tfvars').

.PARAMETER SecretName
Name of the GitHub secret whose contents become the .tfvars body.
The secret's value is expected to be piped in via stdin OR passed via -TfvarsContent
(GitHub Actions can only surface secrets through env vars in steps).

.PARAMETER TfvarsContent
Full content of the tfvars file (passed from the workflow via env var).

.PARAMETER EdgercContent
Full content of the ~/.edgerc file.

.PARAMETER LinodeBucket
Linode Object Storage bucket name.

.PARAMETER LinodeAccessKey
Linode Object Storage access key.

.PARAMETER LinodeSecretKey
Linode Object Storage secret key.

.PARAMETER RunId
GitHub run id — used to uniquify the S3 state key so failed runs don't collide.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Template,
    [Parameter(Mandatory = $true)][string]$Environment,
    [Parameter(Mandatory = $true)][string]$TfvarsName,
    [Parameter(Mandatory = $true)][string]$SecretName,
    [Parameter(Mandatory = $true)][AllowEmptyString()][string]$TfvarsContent,
    [Parameter(Mandatory = $true)][AllowEmptyString()][string]$EdgercContent,
    [Parameter(Mandatory = $true)][string]$LinodeBucket,
    [Parameter(Mandatory = $true)][string]$LinodeAccessKey,
    [Parameter(Mandatory = $true)][string]$LinodeSecretKey,
    [Parameter(Mandatory = $true)][string]$RunId
)

$ErrorActionPreference = 'Stop'

$templateFolderMap = @{
    aap    = 'new-aap-configuration'
    aapasm = 'new-aapasm-configuration'
    pm     = 'new-property'
    bmp    = 'new-bmp-endpoints'
    edns   = 'new-edns'
    ds2    = 'new-ds2'
}

if (-not $templateFolderMap.ContainsKey($Template)) {
    throw "Unknown template: $Template"
}

$folder = $templateFolderMap[$Template]
$envDir = Join-Path $folder "environments/$Environment"

# Test env folder must exist for the template. Missing folder is a soft skip.
if (-not (Test-Path $envDir)) {
    Write-Host "⚠️  Skipping ${Template}: env folder '$envDir' does not exist. Add it in the repo to enable this template in CI."
    "skip=true" | Out-File -FilePath $env:GITHUB_OUTPUT -Append
    exit 0
}

if ([string]::IsNullOrWhiteSpace($TfvarsContent)) {
    throw "Secret '$SecretName' is empty or missing. Populate it in the repository settings."
}
if ([string]::IsNullOrWhiteSpace($EdgercContent)) {
    throw "AKAMAI_EDGERC secret is empty."
}

$edgercPath = Join-Path $HOME '.edgerc'
if (-not (Test-Path $edgercPath)) {
    $EdgercContent | Out-File -FilePath $edgercPath -Force -Encoding ascii
    if ($IsLinux -or $IsMacOS) { chmod 600 $edgercPath }
    Write-Host "Wrote ~/.edgerc"
}

$tfvarsPath = Join-Path $envDir $TfvarsName
$TfvarsContent | Out-File -FilePath $tfvarsPath -Force -Encoding utf8
Write-Host "Wrote tfvars: $tfvarsPath ($($TfvarsContent.Length) chars)"

# S3 state key: one per template + variant so parallel runs and reruns are isolated.
$cleanName = $TfvarsName -replace '\.tfvars$', ''
$stateKey = "$folder/$Environment-$cleanName.tfstate"

$backendConfigPath = Join-Path $envDir 'config.backend'
$backendConfig = @"
skip_credentials_validation = true
skip_region_validation      = true
skip_requesting_account_id  = true
skip_s3_checksum            = true
use_lockfile                = true
bucket                      = "$LinodeBucket"
key                         = "$stateKey"
region                      = "us-mia-1"
endpoints                   = { s3 = "https://us-mia-1.linodeobjects.com" }
access_key                  = "$LinodeAccessKey"
secret_key                  = "$LinodeSecretKey"
"@
$backendConfig | Out-File -FilePath $backendConfigPath -Force -Encoding utf8
Write-Host "Wrote backend config: $backendConfigPath (key=$stateKey)"

"skip=false"       | Out-File -FilePath $env:GITHUB_OUTPUT -Append
"tfvarsPath=$tfvarsPath" | Out-File -FilePath $env:GITHUB_OUTPUT -Append