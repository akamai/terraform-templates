<#
.SYNOPSIS 
Save and/or activate resources via Terraform

.DESCRIPTION 
Can be used to 'save' only the changes to the Akamai resource or activate to either staging or production networks, 
or activate to both networks simultaneously. Also supports certificate management for CPS.

This script uses a modular architecture with template handlers in lib/templates/ and shared functionality in lib/core/.

.PARAMETER TemplateType
Specifies the template type. Available values: aap, aapasm, pm, cps, bmp

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

.LINK
https://github.com/akamai/terraform-templates
#>

[CmdletBinding(DefaultParameterSetName = 'save-activate')]
Param(
    [Parameter(Position = 0, Mandatory = $true)]
    [ValidateSet("aap", "aapasm", "pm", "cps", "bmp", "edns")]
    [string]$TemplateType,

    [Parameter(Mandatory = $false)]
    [ValidateSet("dv-san-cert", "third-party-cert")]
    [string]$CpsType,

    [Parameter(Mandatory = $false)]
    [Alias("Env")]
    [string]$Environment,

    # --- BMP: API-scope actions ---
    [Parameter(ParameterSetName = 'bmp-api-save')]
    [switch]$SaveApi,

    [Parameter(ParameterSetName = 'bmp-api-activate')]
    [switch]$ActivateStagingApi,

    [Parameter(ParameterSetName = 'bmp-api-activate')]
    [switch]$ActivateProductionApi,

    # --- BMP: SEC-scope actions ---
    [Parameter(ParameterSetName = 'bmp-sec-save')]
    [switch]$SaveSec,

    [Parameter(ParameterSetName = 'bmp-sec-activate')]
    [switch]$ActivateStagingSec,

    [Parameter(ParameterSetName = 'bmp-sec-activate')]
    [switch]$ActivateProductionSec,

    [Parameter(Mandatory = $false)]
    [Alias("Cert")]
    [string]$CertNumber,

    [Parameter(Mandatory = $false)]
    [ValidateSet("primary", "secondary")]
    [string]$ZoneType,

    [Parameter(ParameterSetName = 'save')]
    [switch]$Save,
    
    [Parameter(ParameterSetName = 'activate')]
    [switch]$ActivateStaging,
    
    [Parameter(ParameterSetName = 'activate')]
    [switch]$ActivateProduction,

    [Parameter(ParameterSetName = 'cps-create')]
    [string]$CreateCert,

    [Parameter(ParameterSetName = 'cps-upload')]
    [string]$UploadCert,

    [Parameter(ParameterSetName = 'cps-destroy')]
    [string]$DestroyCert,

    [Parameter(ParameterSetName = 'bmp-api-save')]
    [Parameter(ParameterSetName = 'bmp-api-activate')]
    [Parameter(ParameterSetName = 'bmp-sec-save')]
    [Parameter(ParameterSetName = 'bmp-sec-activate')]
    [Parameter(ParameterSetName = 'save')]
    [Parameter(ParameterSetName = 'activate')]
    [switch]$Dry,

    [Parameter(ParameterSetName = 'bmp-sec-save')]  
    [Parameter(ParameterSetName = 'bmp-sec-activate')] 
    [Parameter(ParameterSetName = 'activate')]
    [Parameter(ParameterSetName = 'save')]
    [Alias("Notes")]
    [string]$VersionNotes,

    [Parameter(ParameterSetName = 'destroy')]
    [switch]$Destroy,

    [Parameter()]
    [switch]$SkipValidation,

    [Parameter()]
    [switch]$Force,

    [Parameter()]
    [switch]$Help
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
}

$moduleName = $templateModuleMap[$TemplateType]

# Import template-specific module
$modulePath = "$PSScriptRoot/lib/templates/$moduleName.psm1"
if (-not (Test-Path $modulePath)) {
    throw "Template module not found: $modulePath"
}
Import-Module $modulePath -Force

# Map template type to folder name
$templateFolderMap = @{
    "aap"    = "new-aap-configuration"
    "aapasm" = "new-aapasm-configuration"
    "pm"     = "new-property"
    "bmp"    = "new-bmp-endpoints"
    "edns"   = "new-edns"
}

if ($TemplateType -eq "cps") {
    if (-not $CpsType) {
        throw "CpsType is required for CPS template. Use: -CpsType dv-san-cert or -CpsType third-party-cert"
    }
    $TemplateFolder = "new-$CpsType"
}
else {
    $TemplateFolder = $templateFolderMap[$TemplateType]
}

# Route to appropriate template handler
try {
    switch ($moduleName) {
        "AAP" {
            if (-not $Environment) {
                throw "Environment parameter required for AAP template. Use: -Env <environment>"
            }
            
            if ($CertNumber -or $CreateCert -or $UploadCert -or $DestroyCert -or $CpsType) {
                throw "CPS parameters not applicable for AAP template"
            }
            
            $template = New-AAPTemplate -Environment $Environment -TemplateFolder $TemplateFolder
            
            if ($Destroy) {
                $template.Destroy()
            }
            elseif ($Save -or $ActivateStaging -or $ActivateProduction) {
                $template.Deploy(@{
                        Save               = $Save.IsPresent
                        ActivateStaging    = $ActivateStaging.IsPresent
                        ActivateProduction = $ActivateProduction.IsPresent
                        VersionNotes       = $VersionNotes
                        Dry                = $Dry.IsPresent
                        SkipValidation     = $SkipValidation.IsPresent
                        Force              = $Force.IsPresent
                        Debug              = $PSBoundParameters.ContainsKey('Debug')
                    })
            }
            else {
                throw "Please specify at least one parameter: -Save, -ActivateStaging, -ActivateProduction, or -Destroy"
            }
        }
        
        "AAPASM" {
            if (-not $Environment) {
                throw "Environment parameter required for AAP+ASM template. Use: -Env <environment>"
            }
            
            if ($CertNumber -or $CreateCert -or $UploadCert -or $DestroyCert -or $CpsType) {
                throw "CPS parameters not applicable for AAP+ASM template"
            }
            
            $template = New-AAPASMTemplate -Environment $Environment -TemplateFolder $TemplateFolder
            
            if ($Destroy) {
                $template.Destroy()
            }
            elseif ($Save -or $ActivateStaging -or $ActivateProduction) {
                $template.Deploy(@{
                        Save               = $Save.IsPresent
                        ActivateStaging    = $ActivateStaging.IsPresent
                        ActivateProduction = $ActivateProduction.IsPresent
                        VersionNotes       = $VersionNotes
                        Dry                = $Dry.IsPresent
                        SkipValidation     = $SkipValidation.IsPresent
                        Force              = $Force.IsPresent
                        Debug              = $PSBoundParameters.ContainsKey('Debug')
                    })
            }
            else {
                throw "Please specify at least one parameter: -Save, -ActivateStaging, -ActivateProduction, or -Destroy"
            }
        }
        
        "PropertyManager" {
            if (-not $Environment) {
                throw "Environment parameter required for Property Manager template. Use: -Env <environment>"
            }
            
            if ($CertNumber -or $CreateCert -or $UploadCert -or $DestroyCert -or $CpsType) {
                throw "CPS parameters not applicable for Property Manager template"
            }
            
            $template = New-PropertyManagerTemplate -Environment $Environment -TemplateFolder $TemplateFolder
            
            if ($Destroy) {
                $template.Destroy()
            }
            elseif ($Save -or $ActivateStaging -or $ActivateProduction) {
                $template.Deploy(@{
                        Save               = $Save.IsPresent
                        ActivateStaging    = $ActivateStaging.IsPresent
                        ActivateProduction = $ActivateProduction.IsPresent
                        VersionNotes       = $VersionNotes
                        Dry                = $Dry.IsPresent
                        SkipValidation     = $SkipValidation.IsPresent
                        Force              = $Force.IsPresent
                        Debug              = $PSBoundParameters.ContainsKey('Debug')
                    })
            }
            else {
                throw "Please specify at least one parameter: -Save, -ActivateStaging, -ActivateProduction, or -Destroy"
            }
        }
        
        "CPS" {
            if ($Environment -or $Save -or $ActivateStaging -or $ActivateProduction -or $VersionNotes -or $SkipValidation) {
                throw "Security template parameters not applicable for CPS template"
            }
            
            # Determine action and cert number
            $action = $null
            if ($CreateCert) {
                $action = "create"
                $CertNumber = $CreateCert
            }
            elseif ($UploadCert) {
                $action = "upload"
                $CertNumber = $UploadCert
            }
            elseif ($DestroyCert) {
                $action = "destroy"
                $CertNumber = $DestroyCert
            }
            else {
                throw "Please specify at least one parameter: -CreateCert, -UploadCert, or -DestroyCert"
            }
            
            $template = New-CPSTemplate -CpsType $CpsType -CertNumber $CertNumber -TemplateFolder $TemplateFolder
            
            switch ($action) {
                "create" { $template.CreateCert($Dry.IsPresent, $Force.IsPresent) }
                "upload" { $template.UploadCert($Dry.IsPresent, $Force.IsPresent) }
                "destroy" { $template.DestroyCert() }
            }
        }

        "BMP" {
            if (-not $Environment) {
                throw "Environment parameter required for BMP template. Use: -Env <environment>"
            }

            $template = New-BMPTemplate -Environment $Environment -TemplateFolder $TemplateFolder

            if ($Destroy) {
                $template.Destroy()
            }
            elseif ( $ActivateStaging -or $ActivateProduction -or
                    $SaveApi -or $ActivateStagingApi -or $ActivateProductionApi -or
                    $SaveSec -or $ActivateStagingSec -or $ActivateProductionSec) {
                $template.Deploy(@{
                    # Global scope
                    ActivateStaging    = $ActivateStaging.IsPresent
                    ActivateProduction = $ActivateProduction.IsPresent
                    # API scope
                    SaveApi               = $SaveApi.IsPresent
                    ActivateStagingApi    = $ActivateStagingApi.IsPresent
                    ActivateProductionApi = $ActivateProductionApi.IsPresent
                    # SEC scope
                    SaveSec               = $SaveSec.IsPresent
                    ActivateStagingSec    = $ActivateStagingSec.IsPresent
                    ActivateProductionSec = $ActivateProductionSec.IsPresent
                    # Common
                    VersionNotes       = $VersionNotes
                    Dry                = $Dry.IsPresent
                    SkipValidation     = $SkipValidation.IsPresent
                    Force              = $Force.IsPresent
                    Debug              = $PSBoundParameters.ContainsKey('Debug')
                })
            }
            else {
                throw "Please specify at least one parameter: -Save, -SaveApi, -SaveSec, -ActivateStaging[Api|Sec], -ActivateProduction[Api|Sec], or -Destroy"
            }
        }
        
        "EDNS" {
            if (-not $Environment) {
                throw "Environment parameter required for EDNS template. Use: -Env <environment>"
            }

            if (-not $ZoneType) {
                throw "ZoneType parameter required for EDNS template. Use: -ZoneType primary|secondary"
            }

            if ($CertNumber -or $CreateCert -or $UploadCert -or $DestroyCert -or $CpsType) {
                throw "CPS parameters are not applicable for EDNS template"
            }

            $template = New-EDNSTemplate `
                -Environment $Environment `
                -ZoneType $ZoneType `
                -TemplateFolder $TemplateFolder

            if ($Destroy) {
                $template.Destroy()
            }
            else {
                $template.Deploy($Dry.IsPresent, $Force.IsPresent)
            }
        }
        
        default {
            throw "Unknown template module: $moduleName"
        }
    }
}
catch {
    Write-Error "Deployment failed: $_"
    exit 1
}

# Execution summary
Write-ExecutionSummary -StartTime $ScriptStartTime