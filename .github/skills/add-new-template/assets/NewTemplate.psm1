<#
.SYNOPSIS
{TemplateName} template handler

.DESCRIPTION
Handles deployment, activation, and destruction of {TemplateName} configurations.

INSTRUCTIONS: Replace every occurrence of {TemplateName} with your PascalCase module name
(e.g. "MyProduct"). Then update the product IDs, resource names, and Terraform variable
keys to match your actual template.
#>

using module ../core/TerraformRunner.psm1
using module ../core/Validation.psm1
using module ../core/Logger.psm1

class {TemplateName}Template {
    [string]$Environment
    [string]$TemplateFolder
    [hashtable]$DeployParams

    {TemplateName}Template([string]$environment, [string]$templateFolder) {
        $this.Environment    = $environment
        $this.TemplateFolder = $templateFolder
        $this.DeployParams   = @{}
    }

    [void] ValidatePrerequisites() {
        Write-Host "Validating {TemplateName} prerequisites..." -ForegroundColor Cyan

        $tfvarsPath = "./$($this.TemplateFolder)/environments/$($this.Environment)/$($this.Environment).tfvars"
        if (-not (Test-Path $tfvarsPath)) {
            throw "Environment file not found: $tfvarsPath"
        }

        # TODO: Add product ID validation if applicable, or remove this block.
        if (-not $this.DeployParams.SkipValidation) {
            $expectedProducts = @(
                @{Id = "M-LC-XXXXXX"; Name = "TODO: Product display name"}
            )
            Test-AkamaiProductId -TfVarsPath $tfvarsPath -ExpectedProducts $expectedProducts
        }
    }

    [hashtable] BuildTerraformVars() {
        $username   = Get-Username
        $emailsJson = ConvertTo-Json @("$username@akamai.com") -Compress

        $versionNotes = $this.DeployParams.VersionNotes
        if (-not $versionNotes) {
            $versionNotes = Read-Host "Please enter version/activation notes"
            if (-not $versionNotes) { $versionNotes = "Used Terraform PS Templates" }
        }
        Write-Host "Using version/activation notes: $versionNotes" -ForegroundColor Green

        $vars = @{
            "emails"                 = $emailsJson
            "activation_notes"       = $versionNotes
            "version_notes"          = $versionNotes
            "activate_to_staging"    = $this.DeployParams.ActivateStaging    ? "true" : "false"
            "activate_to_production" = $this.DeployParams.ActivateProduction ? "true" : "false"
        }

        # Check for existing activation resources to prevent duplicate-activation errors.
        # TODO: Update resource names to match the activation resources in your main.tf.
        $stagingExists = Test-TerraformResourceExists -TemplateFolder $this.TemplateFolder `
                            -ResourceName "akamai_appsec_activations.staging"
        $prodExists    = Test-TerraformResourceExists -TemplateFolder $this.TemplateFolder `
                            -ResourceName "akamai_appsec_activations.production"

        Write-Host "Previous activation to staging found: $stagingExists"    -ForegroundColor Gray
        Write-Host "Previous activation to production found: $prodExists"    -ForegroundColor Gray

        $vars["activation_to_staging_exists"]    = $stagingExists ? "true" : "false"
        $vars["activation_to_production_exists"] = $prodExists    ? "true" : "false"

        return $vars
    }

    # OPTIONAL: Implement HandleApplyFailure only if the template has a known
    # first-run import quirk (like AAP auto-creating rate policies). Otherwise delete this method.
    # [void] HandleApplyFailure() {
    #     Write-Host "Handling {TemplateName}-specific failure..." -ForegroundColor Yellow
    #     # Import logic here.
    # }

    [void] Deploy([hashtable]$params) {
        $this.DeployParams = $params

        Write-Host "Deploying {TemplateName} configuration for environment: $($this.Environment)" -ForegroundColor Green

        $this.ValidatePrerequisites()

        $configPath    = "environments/$($this.Environment)"
        $stateFileName = "$($this.Environment)-terraform.tfstate"
        $logPath       = "./$($this.TemplateFolder)/$configPath/$($this.Environment)-akamai_tf.log"

        Initialize-TerraformBackend `
            -TemplateFolder $this.TemplateFolder `
            -ConfigPath     $configPath `
            -StateFileName  $stateFileName `
            -VarFilePath    "./$configPath/$($this.Environment).tfvars" `
            -Force          $params.Force

        if ($params.Debug) { Enable-TerraformDebugLogging -LogPath $logPath }

        $vars    = $this.BuildTerraformVars()
        $varFile = "./$configPath/$($this.Environment).tfvars"

        $outFileName = if ($params.Save) { "$($this.Environment)-save.tfplan" }
                       elseif ($params.ActivateStaging -and -not $params.ActivateProduction) { "$($this.Environment)-staging.tfplan" }
                       elseif ($params.ActivateProduction -and -not $params.ActivateStaging) { "$($this.Environment)-production.tfplan" }
                       elseif ($params.ActivateStaging -and $params.ActivateProduction)      { "$($this.Environment)-production.tfplan" }
                       else { "$($this.Environment)-default.tfplan" }
        $outFile = "./$configPath/$outFileName"

        $exitCode = Invoke-TerraformPlan -TemplateFolder $this.TemplateFolder `
                        -Variables $vars -VarFilePath $varFile -OutFile $outFile

        if ($exitCode -ne 0) {
            if ($params.Debug) { Write-Host "`nDebug log saved to: $logPath" -ForegroundColor Yellow }
            throw "Terraform plan failed with exit code: $exitCode"
        }

        if (-not $params.Dry) {
            $exitCode = Invoke-TerraformApply -TemplateFolder $this.TemplateFolder -PlanFile $outFile
            if ($exitCode -eq 0) {
                Write-Host "✓ {TemplateName} deployment completed successfully" -ForegroundColor Green
            }
            else {
                # TODO: If HandleApplyFailure is implemented, replace the throw below
                # with a retry loop (see AAP.psm1 for the full pattern).
                throw "{TemplateName} deployment failed with exit code: $exitCode"
            }
        }

        if ($params.Debug) { Disable-TerraformDebugLogging }
    }

    [void] Destroy() {
        Write-Host "Destroying {TemplateName} configuration for environment: $($this.Environment)" -ForegroundColor Red

        Confirm-DestroyOperation -ResourceDescription "{TemplateName} configuration for environment: $($this.Environment)"

        $configPath    = "environments/$($this.Environment)"
        $stateFileName = "$($this.Environment)-terraform.tfstate"

        Initialize-TerraformBackend -TemplateFolder $this.TemplateFolder `
            -ConfigPath $configPath -StateFileName $stateFileName

        $varFile  = "./$configPath/$($this.Environment).tfvars"
        $exitCode = Invoke-TerraformDestroy -TemplateFolder $this.TemplateFolder `
                        -VarFilePath $varFile -NoRefresh

        if ($exitCode -eq 0) {
            Write-Host "✓ {TemplateName} destruction completed successfully" -ForegroundColor Green
        }
        else {
            throw "{TemplateName} destruction failed with exit code: $exitCode"
        }
    }
}

function New-{TemplateName}Template {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] [string]$Environment,
        [Parameter(Mandatory = $true)] [string]$TemplateFolder
    )
    return [{TemplateName}Template]::new($Environment, $TemplateFolder)
}

function Get-{TemplateName}ParamPolicy {
    <#
    .SYNOPSIS
    Returns the parameter policy for the {TemplateName} template.
    Called automatically by deploy.ps1 before routing begins.
    #>
    return @{
        Required      = @("Environment")
        RequiredHints = @{ Environment = "Use: -Env <environment>" }
        Allowed       = @(
            "Environment", "Save", "ActivateStaging", "ActivateProduction",
            "Destroy", "VersionNotes", "SkipValidation", "Dry", "Debug", "Force"
        )
        MustHaveOneOf = @("Save", "ActivateStaging", "ActivateProduction", "Destroy")
    }
}

function Invoke-{TemplateName}Template {
    <#
    .SYNOPSIS
    Dispatches a {TemplateName} deployment request received from deploy.ps1.
    Owns all {TemplateName}-specific routing logic so that deploy.ps1 stays template-agnostic.
    #>
    param(
        [Parameter(Mandatory = $true)] [string]$TemplateFolder,
        [Parameter(Mandatory = $true)] [hashtable]$BoundParams
    )

    $template = New-{TemplateName}Template -Environment $BoundParams['Environment'] -TemplateFolder $TemplateFolder

    if ($BoundParams.ContainsKey('Destroy')) {
        $template.Destroy()
    }
    else {
        $template.Deploy(@{
            Save               = $BoundParams.ContainsKey('Save')
            ActivateStaging    = $BoundParams.ContainsKey('ActivateStaging')
            ActivateProduction = $BoundParams.ContainsKey('ActivateProduction')
            VersionNotes       = $BoundParams['VersionNotes']
            Dry                = $BoundParams.ContainsKey('Dry')
            SkipValidation     = $BoundParams.ContainsKey('SkipValidation')
            Force              = $BoundParams.ContainsKey('Force')
            Debug              = $BoundParams.ContainsKey('Debug')
        })
    }
}

Export-ModuleMember -Function New-{TemplateName}Template, Get-{TemplateName}ParamPolicy, Invoke-{TemplateName}Template
