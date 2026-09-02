<#
.SYNOPSIS 
Save and/or activate resources via Terraform

.DESCRIPTION 
Can be used to 'save' only the changes to the Akamai resource or activate to either staging or production networks, 
or activate to both networks simultaneously. Also supports certificate management for CPS.

This script uses a modular architecture with template handlers in lib/templates/ and shared functionality in lib/core/.

.PARAMETER TemplateType
Specifies the template type. Available values: aap, aapasm, pm, cps, bmp, edns, ds2 ,dom

.PARAMETER CpsType
Specifies the CPS certificate type when TemplateType is 'cps'. Available values: dv-san-cert, third-party-cert

.PARAMETER Environment
The environment to deploy to (e.g., prod, dev, qa). Used for aap, aapasm, pm, and bmp templates.

.PARAMETER CertNumber
The certificate identifier. Used for CPS templates.

.PARAMETER VersionNotes
Specifies the notes to be appended to the configuration version.

.PARAMETER Save
Saves only the modifications to the Akamai resource. Cannot be used with activation parameters.

.PARAMETER ActivateStaging
Activates the Akamai resource to the staging network.

.PARAMETER ActivateProduction
Activates the Akamai resource to the production network.

.PARAMETER SaveApi
[BMP only — Phase 1] Saves the API definition without activating. Cannot be combined with -ActivateStagingApi or -ActivateProductionApi.

.PARAMETER ActivateStagingApi
[BMP only — Phase 1] Activates the API definition to the staging network. Can be combined with -ActivateProductionApi. Cannot be combined with -SaveApi.

.PARAMETER ActivateProductionApi
[BMP only — Phase 1] Activates the API definition to the production network. Can be combined with -ActivateStagingApi. Cannot be combined with -SaveApi.

.PARAMETER SaveSec
[BMP only — Phase 2] Saves the security configuration without activating. Requires Phase 1 to be activated first. Cannot be combined with -ActivateStagingSec or -ActivateProductionSec.

.PARAMETER ActivateStagingSec
[BMP only — Phase 2] Activates the security configuration to the staging network. Requires API definition activated to staging first. Can be combined with -ActivateProductionSec. Cannot be combined with -SaveSec.

.PARAMETER ActivateProductionSec
[BMP only — Phase 2] Activates the security configuration to the production network. Requires API definition activated to production first. Can be combined with -ActivateStagingSec. Cannot be combined with -SaveSec.

.PARAMETER CreateCert
Creates a new certificate (CPS only).

.PARAMETER UploadCert
Uploads a certificate (CPS third-party only).

.PARAMETER DestroyCert
Destroys a certificate (CPS only).

.PARAMETER ZoneType
Specifies Edge DNS zone type. Available values: primary, secondary.
Used only when TemplateType is 'edns'.

.PARAMETER Dry
Outputs the terraform plan and performs no actions.

.PARAMETER Destroy
Deactivates and destroys all the resources.

.PARAMETER Debug
Enables debug logging. Saved in ./akamai_tf.log

.PARAMETER SkipValidation
Skips product ID validation. Use this if product IDs have changed or for testing purposes.

.PARAMETER Force
Skips the drift-detection prompt. When drift is detected before applying changes, the script normally
prompts for confirmation. Pass -Force to bypass this prompt and continue automatically.

.PARAMETER Help
Displays detailed help information about the script.

.EXAMPLE
PS> Get-Help deploy.ps1
Show Help information for the deployment script

.EXAMPLE
PS> .\deploy.ps1 aap -Env prod -Save -Notes "Some user notes"
Create/Save AAP configuration for prod environment without activations

.EXAMPLE
PS> .\deploy.ps1 aapasm -Env dev -ActivateStaging -Debug
Create and Activate to staging network an AAP+ASM configuration for the dev environment with debug logging

.EXAMPLE
PS> .\deploy.ps1 pm -Env prod -Save -Notes "Some user notes"
Create/Save delivery configurations for prod environment without activations

.EXAMPLE
PS> .\deploy.ps1 pm -Env dev -ActivateStaging -Debug
Create and Activate to staging network a delivery configuration for the dev environment with debug logging

.EXAMPLE
PS> .\deploy.ps1 pm -Env qa -ActivateProduction -Notes "Some user notes"
Create and Activate to production network a property manager configuration for qa environment

.EXAMPLE
PS> .\deploy.ps1 cps -CpsType dv-san-cert -CreateCert cert1
Create a DV SAN certificate

.EXAMPLE
PS> .\deploy.ps1 cps -CpsType third-party-cert -CreateCert cert1
Create a third-party certificate

.EXAMPLE
PS> .\deploy.ps1 cps -CpsType third-party-cert -UploadCert cert1
Upload a third-party certificate

.EXAMPLE
PS> .\deploy.ps1 cps -CpsType dv-san-cert -DestroyCert cert1
Destroy a certificate

.EXAMPLE
PS> .\deploy.ps1 bmp -Env dev -SaveApi
[BMP Phase 1] Save the API definition for the dev environment without activating

.EXAMPLE
PS> .\deploy.ps1 bmp -Env dev -ActivateStagingApi
[BMP Phase 1] Activate the API definition to staging for the dev environment

.EXAMPLE
PS> .\deploy.ps1 bmp -Env dev -ActivateProductionApi
[BMP Phase 1] Activate the API definition to production for the dev environment

.EXAMPLE
PS> .\deploy.ps1 bmp -Env dev -ActivateStagingApi -ActivateProductionApi
[BMP Phase 1] Activate the API definition to both staging and production simultaneously

.EXAMPLE
PS> .\deploy.ps1 bmp -Env dev -SaveSec -Notes "JIRA-123: initial setup"
[BMP Phase 2] Save the security configuration (requires Phase 1 activated first)

.EXAMPLE
PS> .\deploy.ps1 bmp -Env dev -ActivateStagingSec
[BMP Phase 2] Activate the security configuration to staging (requires API activated to staging first)

.EXAMPLE
PS> .\deploy.ps1 bmp -Env dev -ActivateProductionSec
[BMP Phase 2] Activate the security configuration to production (requires API activated to production first)

.EXAMPLE
PS> .\deploy.ps1 bmp -Env dev -Destroy
Tear down the entire BMP configuration for the dev environment

.EXAMPLE
PS> .\deploy.ps1 edns -Env dev -ZoneType primary -Save
Create or update PRIMARY Edge DNS zone in dev environment

.EXAMPLE
PS> .\deploy.ps1 edns -Env qa -ZoneType secondary -Destroy
Safely destroy SECONDARY Edge DNS zone in qa environment

.EXAMPLE
PS> .\deploy.ps1 ds2 -Env dev -Save
Create or update a DataStream 2 configuration in the dev environment (activation driven by the tfvars activate_stream value)

.EXAMPLE
PS> .\deploy.ps1 ds2 -Env prod -ActivateProduction
Deploy and activate the DataStream 2 stream in the prod environment

.EXAMPLE
PS> .\deploy.ps1 ds2 -Env dev -Destroy
Tear down the DataStream 2 configuration for the dev environment

.EXAMPLE
PS> .\deploy.ps1 dom -Run -Dry 
Safely execute DOM addition/validation/search to preview changes

.EXAMPLE
PS> .\deploy.ps1 dom -Run 
Execute DOM addition/validation/search and see results in outputfiles (dom_*.txt)

.LINK
https://github.com/akamai/terraform-templates
#>

[CmdletBinding(DefaultParameterSetName = 'save-activate')]
Param(
    [Parameter(Position = 0, Mandatory = $true)]
    [ValidateSet("aap", "aapasm", "pm", "cps", "bmp", "edns", "ds2" , "dom")]
    [string]$TemplateType,

    # --- Common parameters ---
    [Parameter(Mandatory = $false)]
    [Alias("Env")]
    [string]$Environment,

    [Parameter(ParameterSetName = 'destroy')]
    [switch]$Destroy,

    [Parameter()]
    [switch]$SkipValidation,

    [Parameter()]
    [switch]$Force,

    [Parameter()]
    [switch]$Help,

    # --- AAP / AAPASM / PM / EDNS / DS2 parameters ---
    [Parameter(ParameterSetName = 'save')]
    [switch]$Save,

    [Parameter(ParameterSetName = 'activate')]
    [switch]$ActivateStaging,

    [Parameter(ParameterSetName = 'activate')]
    [switch]$ActivateProduction,

    # VersionNotes is applicable to all templates except CPS
    [Parameter(ParameterSetName = 'bmp-sec-save')]
    [Parameter(ParameterSetName = 'bmp-sec-activate')]
    [Parameter(ParameterSetName = 'activate')]
    [Parameter(ParameterSetName = 'save')]
    [Alias("Notes")]
    [string]$VersionNotes,

    # Dry is applicable to all templates except -DestroyCert (no plan phase).
    [Parameter(ParameterSetName = 'bmp-api-save')]
    [Parameter(ParameterSetName = 'bmp-api-activate')]
    [Parameter(ParameterSetName = 'bmp-sec-save')]
    [Parameter(ParameterSetName = 'bmp-sec-activate')]
    [Parameter(ParameterSetName = 'save')]
    [Parameter(ParameterSetName = 'activate')]
    [Parameter(ParameterSetName = 'cps-create')]
    [Parameter(ParameterSetName = 'cps-upload')]
    [Parameter(ParameterSetName = 'dom-run')]
    [switch]$Dry,

      # --- DOM: Specific action ---
    [Parameter(ParameterSetName = 'dom-run', Mandatory = $true)]
    [switch]$Run,

    # --- EDNS parameters ---
    [Parameter(Mandatory = $false)]
    [ValidateSet("primary", "secondary")]
    [string]$ZoneType,

    # --- BMP parameters ---
    # Phase 1: API-scope actions
    [Parameter(ParameterSetName = 'bmp-api-save')]
    [switch]$SaveApi,

    [Parameter(ParameterSetName = 'bmp-api-activate')]
    [switch]$ActivateStagingApi,

    [Parameter(ParameterSetName = 'bmp-api-activate')]
    [switch]$ActivateProductionApi,

    # Phase 2: Security-scope actions
    [Parameter(ParameterSetName = 'bmp-sec-save')]
    [switch]$SaveSec,

    [Parameter(ParameterSetName = 'bmp-sec-activate')]
    [switch]$ActivateStagingSec,

    [Parameter(ParameterSetName = 'bmp-sec-activate')]
    [switch]$ActivateProductionSec,

    # --- CPS parameters ---
    [Parameter(Mandatory = $false)]
    [ValidateSet("dv-san-cert", "third-party-cert")]
    [string]$CpsType,

    [Parameter(Mandatory = $false)]
    [Alias("Cert")]
    [string]$CertNumber,

    [Parameter(ParameterSetName = 'cps-create')]
    [string]$CreateCert,

    [Parameter(ParameterSetName = 'cps-upload')]
    [string]$UploadCert,

    [Parameter(ParameterSetName = 'cps-destroy')]
    [string]$DestroyCert
)

# Start timing
$ScriptStartTime = Get-Date

# Handle help
if ($Help -or $args -contains "Help" -or $args -contains "-Help" -or $args -contains "--help" -or $args -contains "help" -or $args -contains "-h") {
    Get-Help $PSCommandPath -Full
    exit 0
}

# Import core modules
Import-Module "$PSScriptRoot/lib/core/TerraformRunner.psm1" -Force
Import-Module "$PSScriptRoot/lib/core/Validation.psm1" -Force
Import-Module "$PSScriptRoot/lib/core/Logger.psm1" -Force

# Map template type to module name
$templateModuleMap = @{
    "aap"    = "AAP"
    "aapasm" = "AAPASM"
    "pm"     = "PropertyManager"
    "cps"    = "CPS"
    "bmp"    = "BMP" 
    "edns"   = "EDNS"
    "ds2"    = "DS2"
    "dom"    = "DOM"
}

$moduleName = $templateModuleMap[$TemplateType]

# Import template-specific module
$modulePath = "$PSScriptRoot/lib/templates/$moduleName.psm1"
if (-not (Test-Path $modulePath)) {
    throw "Template module not found: $modulePath"
}
Import-Module $modulePath -Force

# Map template types to their default folder names.
# Modules that need custom folder logic (e.g. CPS) export Get-<Name>TemplateFolder
# and that function takes precedence over this map.
$templateFolderMap = @{
    "aap"    = "new-aap-configuration"
    "aapasm" = "new-aapasm-configuration"
    "pm"     = "new-property"
    "bmp"    = "new-bmp-endpoints"
    "edns"   = "new-edns"
    "ds2"    = "new-ds2"
    "dom"    = "new-dom"
}

$folderFnName = "Get-${moduleName}TemplateFolder"
if (Get-Command $folderFnName -ErrorAction SilentlyContinue) {
    $TemplateFolder = & $folderFnName -BoundParams $PSBoundParameters
}
elseif ($templateFolderMap.ContainsKey($TemplateType)) {
    $TemplateFolder = $templateFolderMap[$TemplateType]
}
else {
    throw "No folder mapping found for '$TemplateType'. Ensure the module exports Get-${moduleName}TemplateFolder."
}

# Route to appropriate template handler
try {
    # 1. Validate parameters against the template's declared policy.
    $policyFnName = "Get-${moduleName}ParamPolicy"
    if (Get-Command $policyFnName -ErrorAction SilentlyContinue) {
        Assert-TemplateParameters `
            -TemplateType $TemplateType `
            -Policy      (& $policyFnName) `
            -BoundParams $PSBoundParameters
    }

    # 2. Dispatch to the template's own handler — no template-specific logic here.
    $invokeFnName = "Invoke-${moduleName}Template"
    if (-not (Get-Command $invokeFnName -ErrorAction SilentlyContinue)) {
        throw "Template dispatch function not found: $invokeFnName. Ensure the module exports this function."
    }
    & $invokeFnName -TemplateFolder $TemplateFolder -BoundParams $PSBoundParameters
}
catch {
    Write-Error "Deployment failed: $_"
    exit 1
}

# Execution summary
Write-ExecutionSummary -StartTime $ScriptStartTime