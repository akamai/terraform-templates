<#
.SYNOPSIS
Bot Manager Premier (BMP) template handler

.DESCRIPTION
Handles deployment, activation, and destruction of BMP endpoint configurations.
BMP has a two-phase activation model:

  Phase 1 — API Definition scope:
    -SaveApi, -ActivateStagingApi, -ActivateProductionApi
    targets: module.api_definition

  Phase 2 — Security Config scope:
    -SaveSec, -ActivateStagingSec, -ActivateProductionSec
    targets: module.transactional_endpoint / module.security_config_activation
    REQUIRES Phase 1 to be activated on the same network first.

  Global scope (no target restriction):
    -ActivateStaging, -ActivateProduction
#>

using module ../core/TerraformRunner.psm1
using module ../core/Validation.psm1
using module ../core/Logger.psm1

class BMPTemplate {
    [string]$Environment
    [string]$TemplateFolder
    [hashtable]$DeployParams

    # Static resource addresses — single source of truth
    static [string]$AppsecStagingRes = "akamai_appsec_activations.staging"
    static [string]$AppsecProdRes    = "akamai_appsec_activations.production"
    static [string]$ApiStagingRes    = "akamai_apidefinitions_activation.staging"
    static [string]$ApiProdRes       = "akamai_apidefinitions_activation.production"

    BMPTemplate([string]$environment, [string]$templateFolder) {
        $this.Environment    = $environment
        $this.TemplateFolder = $templateFolder
        $this.DeployParams   = @{}
    }

    # -------------------------------------------------------------------------
    # State helper
    # -------------------------------------------------------------------------

    [bool] ResourceExists([string]$resourceName) {
        return Test-TerraformResourceExists -TemplateFolder $this.TemplateFolder -ResourceName $resourceName
    }

    # -------------------------------------------------------------------------
    # ValidatePrerequisites
    # -------------------------------------------------------------------------

    [void] ValidatePrerequisites() {
        Write-Host "Validating BMP prerequisites..." -ForegroundColor Cyan

        $tfvarsPath = "./$($this.TemplateFolder)/environments/$($this.Environment)/$($this.Environment).tfvars"
        if (-not (Test-Path $tfvarsPath)) {
            throw "Environment file not found: $tfvarsPath"
        }

        $p = $this.DeployParams

        $apiStagingActivated = $this.ResourceExists([BMPTemplate]::ApiStagingRes)
        $apiProdActivated    = $this.ResourceExists([BMPTemplate]::ApiProdRes)

        if ($p.SaveSec -and -not ($apiStagingActivated -or $apiProdActivated)) {
            Write-Host ""
            Write-Host "========================================" -ForegroundColor Yellow
            Write-Host "SaveSec requires API activation (staging or production) to exist in state." -ForegroundColor Yellow
            Write-Host "Run one of the following first:" -ForegroundColor Yellow
            Write-Host "  - .\deploy.ps1 bmp -Env $($this.Environment) -ActivateStagingApi" -ForegroundColor Yellow
            Write-Host "  - .\deploy.ps1 bmp -Env $($this.Environment) -ActivateProductionApi" -ForegroundColor Yellow
            Write-Host "========================================" -ForegroundColor Yellow
            throw "SaveSec prerequisite not met: API activation required first"
        }

        if ($p.ActivateStagingSec -and -not $apiStagingActivated) {
            Write-Host ""
            Write-Host "========================================" -ForegroundColor Yellow
            Write-Host "ActivateStagingSec requires API to be activated to STAGING first." -ForegroundColor Yellow
            Write-Host "Run: .\deploy.ps1 bmp -Env $($this.Environment) -ActivateStagingApi" -ForegroundColor Yellow
            Write-Host "========================================" -ForegroundColor Yellow
            throw "ActivateStagingSec prerequisite not met: API staging activation required first"
        }

        if ($p.ActivateProductionSec -and -not $apiProdActivated) {
            Write-Host ""
            Write-Host "========================================" -ForegroundColor Yellow
            Write-Host "ActivateProductionSec requires API to be activated to PRODUCTION first." -ForegroundColor Yellow
            Write-Host "Run: .\deploy.ps1 bmp -Env $($this.Environment) -ActivateProductionApi" -ForegroundColor Yellow
            Write-Host "========================================" -ForegroundColor Yellow
            throw "ActivateProductionSec prerequisite not met: API production activation required first"
        }
    }

    # -------------------------------------------------------------------------
    # BuildTerraformVars
    # -------------------------------------------------------------------------

    [hashtable] BuildTerraformVars() {
        $p = $this.DeployParams

        $username   = Get-Username
        $emailsJson = ConvertTo-Json @("$username@akamai.com") -Compress

        $useApiScope = $p.SaveApi -or $p.ActivateStagingApi -or $p.ActivateProductionApi -or $p.SaveSec
        $useSecScope = $p.ActivateStagingSec -or $p.ActivateProductionSec

        $stagingRes = [BMPTemplate]::AppsecStagingRes
        $prodRes    = [BMPTemplate]::AppsecProdRes

        if ($useApiScope) {
            $stagingRes = [BMPTemplate]::ApiStagingRes
            $prodRes    = [BMPTemplate]::ApiProdRes
        }
        elseif (-not $useSecScope) {
            if (-not $this.ResourceExists($stagingRes) -and $this.ResourceExists([BMPTemplate]::ApiStagingRes)) {
                $stagingRes = [BMPTemplate]::ApiStagingRes
            }
            if (-not $this.ResourceExists($prodRes) -and $this.ResourceExists([BMPTemplate]::ApiProdRes)) {
                $prodRes = [BMPTemplate]::ApiProdRes
            }
        }

        $stagingExists = $this.ResourceExists($stagingRes)
        $prodExists    = $this.ResourceExists($prodRes)

        Write-Host "Checking for an existing state file..." -ForegroundColor Gray
        Write-Host "Previous activation to staging found: $stagingExists"  -ForegroundColor Gray
        Write-Host "Previous activation to production found: $prodExists"  -ForegroundColor Gray

        $activateStaging    = $p.ActivateStaging    -or $p.ActivateStagingApi    -or $p.ActivateStagingSec
        $activateProduction = $p.ActivateProduction -or $p.ActivateProductionApi -or $p.ActivateProductionSec

        $versionNotes = $this.DeployParams.VersionNotes
        if ($p.SaveSec -or $p.ActivateStagingSec -or $p.ActivateProductionSec -or
            $p.ActivateStaging -or $p.ActivateProduction) {
            if (-not $versionNotes) {
                $versionNotes = Read-Host "Please enter version/activation notes"
                if (-not $versionNotes) {
                    $versionNotes = "Used Terraform PS Templates"
                }
            }
            Write-Host "Using version/activation notes: $versionNotes" -ForegroundColor Green
        }

        return @{
            "emails"                          = $emailsJson
            "version_notes"                   = $versionNotes
            "activate_to_staging"             = $activateStaging    ? "true" : "false"
            "activate_to_production"          = $activateProduction ? "true" : "false"
            "activation_to_staging_exists"    = $stagingExists      ? "true" : "false"
            "activation_to_production_exists" = $prodExists         ? "true" : "false"
        }
    }

    # -------------------------------------------------------------------------
    # GetTargetArgs
    # -------------------------------------------------------------------------

    [string[]] GetTargetArgs() {
        $p = $this.DeployParams

        if ($p.SaveApi -or $p.ActivateStagingApi -or $p.ActivateProductionApi) {
            return @("-target=module.api_definition")
        }
        if ($p.SaveSec) {
            return @("-target=module.transactional_endpoint")
        }
        if ($p.ActivateStagingSec -or $p.ActivateProductionSec) {
            return @("-target=module.security_config_activation")
        }

        return @()
    }

    # -------------------------------------------------------------------------
    # GetPlanFileName
    # -------------------------------------------------------------------------

    [string] GetPlanFileName() {
        $p   = $this.DeployParams
        $env = $this.Environment

        if ($p.SaveApi)                                                  { return "$env-api-save.tfplan" }
        if ($p.ActivateStagingApi   -and -not $p.ActivateProductionApi) { return "$env-api-staging.tfplan" }
        if ($p.ActivateProductionApi -and -not $p.ActivateStagingApi)   { return "$env-api-production.tfplan" }
        if ($p.ActivateStagingApi   -and $p.ActivateProductionApi)      { return "$env-api-both.tfplan" }

        if ($p.SaveSec)                                                   { return "$env-sec-save.tfplan" }
        if ($p.ActivateStagingSec   -and -not $p.ActivateProductionSec) { return "$env-sec-staging.tfplan" }
        if ($p.ActivateProductionSec -and -not $p.ActivateStagingSec)   { return "$env-sec-production.tfplan" }
        if ($p.ActivateStagingSec   -and $p.ActivateProductionSec)      { return "$env-sec-both.tfplan" }

        if ($p.ActivateStaging -and -not $p.ActivateProduction)         { return "$env-staging.tfplan" }
        if ($p.ActivateProduction -and -not $p.ActivateStaging)         { return "$env-production.tfplan" }
        if ($p.ActivateStaging -and $p.ActivateProduction)              { return "$env-both.tfplan" }

        return "$env-default.tfplan"
    }

    # -------------------------------------------------------------------------
    # RunPlan — shared plan logic used by both initial plan and retry re-plan
    # -------------------------------------------------------------------------

    [hashtable] RunPlan([string]$varFile, [string]$outFile, [string[]]$targetArgs, [hashtable]$vars) {
        if ($targetArgs.Count -gt 0) {
            $varArgs = @()
            foreach ($key in $vars.Keys) {
                $varArgs += "-var"
                $varArgs += "$key=$($vars[$key])"
            }
            $varArgs += "-var-file"
            $varArgs += $varFile
            $varArgs += $targetArgs
            $varArgs += "-out"
            $varArgs += $outFile

            Write-Host "Running Terraform plan..." -ForegroundColor Cyan
            $output = terraform -chdir="./$($this.TemplateFolder)" plan @varArgs 2>&1
            $output | Out-Default
            return @{ ExitCode = $LASTEXITCODE; Output = $output -join "`n" }
        }
        else {
            Write-Host "Running Terraform plan..." -ForegroundColor Cyan
            $output = terraform -chdir="./$($this.TemplateFolder)" plan `
                ($vars.Keys | ForEach-Object { "-var"; "$_=$($vars[$_])" }) `
                "-var-file" $varFile "-out" $outFile 2>&1
            $output | Out-Default
            return @{ ExitCode = $LASTEXITCODE; Output = $output -join "`n" }
        }
    }

    # -------------------------------------------------------------------------
    # Deploy
    # -------------------------------------------------------------------------

    [void] Deploy([hashtable]$params) {
        $this.DeployParams = $params

        Write-Host "Deploying BMP configuration for environment: $($this.Environment)" -ForegroundColor Green

        $this.ValidatePrerequisites()

        $configPath    = "environments/$($this.Environment)"
        $stateFileName = "$($this.Environment)-terraform.tfstate"
        $logPath       = "./$($this.TemplateFolder)/$configPath/$($this.Environment)-akamai_tf.log"

        # Initialize Terraform (drift check runs automatically when VarFilePath is supplied)
        Initialize-TerraformBackend `
            -TemplateFolder $this.TemplateFolder `
            -ConfigPath $configPath `
            -StateFileName $stateFileName `
            -VarFilePath "./$configPath/$($this.Environment).tfvars" `
            -Force $params.Force

        if ($params.Debug) {
            Enable-TerraformDebugLogging -LogPath $logPath
        }

        $vars       = $this.BuildTerraformVars()
        $targetArgs = $this.GetTargetArgs()
        $outFile    = "./$configPath/$($this.GetPlanFileName())"
        $varFile    = "./$configPath/$($this.Environment).tfvars"

        $planResult = $this.RunPlan($varFile, $outFile, $targetArgs, $vars)

        if ($planResult.ExitCode -ne 0) {
            if ($params.Debug) {
                Write-Host "`nDebug log saved to: $logPath" -ForegroundColor Yellow
            }

            if ($planResult.Output -match "config_id value 0 specified in configuration differs from resource ID" -or
                $planResult.Output -match "security_policy_id value\s+specified in configuration differs from resource ID") {
                Write-Host ""
                Write-Host "========================================" -ForegroundColor Yellow
                Write-Host "A change in the API Definition has been detected." -ForegroundColor Yellow
                Write-Host "The following security configuration commands cannot be run until the API Definition is synced:" -ForegroundColor Yellow
                Write-Host "  -SaveSec" -ForegroundColor White
                Write-Host "  -ActivateStagingSec" -ForegroundColor White
                Write-Host "  -ActivateProductionSec" -ForegroundColor White
                Write-Host ""
                Write-Host "Please run one of the following API commands first to sync:" -ForegroundColor Cyan
                Write-Host "  .\deploy.ps1 bmp -Env $($this.Environment) -SaveApi" -ForegroundColor White
                Write-Host "  .\deploy.ps1 bmp -Env $($this.Environment) -ActivateStagingApi" -ForegroundColor White
                Write-Host "  .\deploy.ps1 bmp -Env $($this.Environment) -ActivateProductionApi" -ForegroundColor White
                Write-Host "========================================" -ForegroundColor Yellow
            }

            throw "Terraform plan failed with exit code: $($planResult.ExitCode). Check the output above for details."
        }

        if (-not $params.Dry) {
            $maxRetries = 2
            $retryCount = 0
            $success    = $false

            while (-not $success -and $retryCount -lt $maxRetries) {
                if ($retryCount -gt 0) {
                    Write-Host "Re-planning before retry..." -ForegroundColor Yellow
                    $replanResult = $this.RunPlan($varFile, $outFile, $targetArgs, $vars)
                    if ($replanResult.ExitCode -ne 0) {
                        throw "Terraform re-plan failed on retry $retryCount"
                    }
                }

                $exitCode = Invoke-TerraformApply `
                    -TemplateFolder $this.TemplateFolder `
                    -PlanFile $outFile

                if ($exitCode -eq 0) {
                    $success = $true

                    # --- Operation-specific success messages ---
                    $p = $this.DeployParams

                    if ($p.SaveApi) {
                        Write-Host ""
                        Write-Host "========================================" -ForegroundColor Green
                        Write-Host "✓ API Definition configuration created successfully." -ForegroundColor Green
                        Write-Host "  Note: This is saved but NOT yet activated." -ForegroundColor Yellow
                        Write-Host "  To activate, run one of:" -ForegroundColor Yellow
                        Write-Host "    .\deploy.ps1 bmp -Env $($this.Environment) -ActivateStagingApi" -ForegroundColor White
                        Write-Host "    .\deploy.ps1 bmp -Env $($this.Environment) -ActivateProductionApi" -ForegroundColor White
                        Write-Host "========================================" -ForegroundColor Green
                    }
                    elseif ($p.SaveSec) {
                        Write-Host ""
                        Write-Host "========================================" -ForegroundColor Green
                        Write-Host "✓ Security configuration created successfully." -ForegroundColor Green
                        Write-Host "  Note: This is saved but NOT yet activated." -ForegroundColor Yellow
                        Write-Host "  To activate, run one of:" -ForegroundColor Yellow
                        Write-Host "    .\deploy.ps1 bmp -Env $($this.Environment) -ActivateStagingSec" -ForegroundColor White
                        Write-Host "    .\deploy.ps1 bmp -Env $($this.Environment) -ActivateProductionSec" -ForegroundColor White
                        Write-Host "========================================" -ForegroundColor Green
                    }
                    elseif ($p.ActivateStagingApi -or $p.ActivateProductionApi) {
                        [System.Collections.ArrayList]$networks = @()
                        if ($p.ActivateStagingApi)    { [void]$networks.Add("STAGING") }
                        if ($p.ActivateProductionApi) { [void]$networks.Add("PRODUCTION") }
                        $networkList = $networks -join " and "
                        Write-Host ""
                        Write-Host "========================================" -ForegroundColor Green
                        Write-Host "✓ API Definition deployed and activated to $networkList successfully." -ForegroundColor Green
                        Write-Host "========================================" -ForegroundColor Green
                    }
                    elseif ($p.ActivateStagingSec -or $p.ActivateProductionSec) {
                        [System.Collections.ArrayList]$networks = @()
                        if ($p.ActivateStagingSec)    { [void]$networks.Add("STAGING") }
                        if ($p.ActivateProductionSec) { [void]$networks.Add("PRODUCTION") }
                        $networkList = $networks -join " and "
                        Write-Host ""
                        Write-Host "========================================" -ForegroundColor Green
                        Write-Host "✓ Security Configuration deployed and activated to $networkList successfully." -ForegroundColor Green
                        Write-Host "========================================" -ForegroundColor Green
                    }
                    elseif ($p.ActivateStaging -or $p.ActivateProduction) {
                        [System.Collections.ArrayList]$networks = @()
                        if ($p.ActivateStaging)    { [void]$networks.Add("STAGING") }
                        if ($p.ActivateProduction) { [void]$networks.Add("PRODUCTION") }
                        $networkList = $networks -join " and "
                        Write-Host ""
                        Write-Host "========================================" -ForegroundColor Green
                        Write-Host "✓ BMP configuration deployed and activated to $networkList successfully." -ForegroundColor Green
                        Write-Host "========================================" -ForegroundColor Green
                    }
                    else {
                        Write-Host ""
                        Write-Host "✓ BMP deployment completed successfully." -ForegroundColor Green
                    }
                }
                else {
                    $retryCount++
                    Write-Warning "Terraform apply failed with exit code: $exitCode"

                    if ($retryCount -ge $maxRetries) {
                        throw "BMP deployment failed after $maxRetries attempts"
                    }
                    Write-Host "Retrying terraform apply..." -ForegroundColor Yellow
                }
            }
        }

        if ($params.Debug) {
            Disable-TerraformDebugLogging
        }
    }

    # -------------------------------------------------------------------------
    # Destroy
    # -------------------------------------------------------------------------

    [void] Destroy() {
        Write-Host "Destroying BMP configuration for environment: $($this.Environment)" -ForegroundColor Red

        $configPath    = "environments/$($this.Environment)"
        $stateFileName = "$($this.Environment)-terraform.tfstate"

        Initialize-TerraformBackend `
            -TemplateFolder $this.TemplateFolder `
            -ConfigPath $configPath `
            -StateFileName $stateFileName

        $varFile    = "./$configPath/$($this.Environment).tfvars"
        $maxRetries = 2
        $retryCount = 0
        $success    = $false

        while (-not $success -and $retryCount -lt $maxRetries) {
            $autoApprove = $retryCount -gt 0
            $exitCode    = Invoke-TerraformDestroy `
                -TemplateFolder $this.TemplateFolder `
                -VarFilePath $varFile `
                -AutoApprove:$autoApprove

            if ($exitCode -eq 0) {
                $success = $true
                Write-Host "✓ BMP destruction completed successfully" -ForegroundColor Green
            }
            else {
                $retryCount++
                if ($retryCount -ge $maxRetries) {
                    throw "BMP destruction failed after $maxRetries attempts"
                }
                Write-Host "Retrying terraform destroy..." -ForegroundColor Yellow
            }
        }
    }
}

function New-BMPTemplate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Environment,

        [Parameter(Mandatory = $true)]
        [string]$TemplateFolder
    )

    return [BMPTemplate]::new($Environment, $TemplateFolder)
}

function Get-BMPParamPolicy {
    <#
    .SYNOPSIS
    Returns the parameter policy for the BMP template.
    Called automatically by deploy.ps1 before routing begins.
    #>
    return @{
        Required      = @("Environment")
        RequiredHints = @{ Environment = "Use: -Env <environment>" }
        Allowed       = @(
            "Environment", "Destroy", "VersionNotes", "SkipValidation", "Dry",
            "ActivateStaging", "ActivateProduction",
            "SaveApi", "ActivateStagingApi", "ActivateProductionApi",
            "SaveSec", "ActivateStagingSec", "ActivateProductionSec"
        )
        MustHaveOneOf = @(
            "Destroy", "ActivateStaging", "ActivateProduction",
            "SaveApi", "ActivateStagingApi", "ActivateProductionApi",
            "SaveSec", "ActivateStagingSec", "ActivateProductionSec"
        )
    }
}

function Invoke-BMPTemplate {
    <#
    .SYNOPSIS
    Dispatches a BMP deployment request received from deploy.ps1.
    Owns all BMP-specific routing logic so that deploy.ps1 stays template-agnostic.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$TemplateFolder,

        [Parameter(Mandatory = $true)]
        [hashtable]$BoundParams
    )

    $template = New-BMPTemplate -Environment $BoundParams['Environment'] -TemplateFolder $TemplateFolder

    if ($BoundParams.ContainsKey('Destroy')) {
        $template.Destroy()
    }
    else {
        $template.Deploy(@{
            # Global scope
            ActivateStaging    = $BoundParams.ContainsKey('ActivateStaging')
            ActivateProduction = $BoundParams.ContainsKey('ActivateProduction')
            # API scope (Phase 1)
            SaveApi               = $BoundParams.ContainsKey('SaveApi')
            ActivateStagingApi    = $BoundParams.ContainsKey('ActivateStagingApi')
            ActivateProductionApi = $BoundParams.ContainsKey('ActivateProductionApi')
            # Security scope (Phase 2)
            SaveSec               = $BoundParams.ContainsKey('SaveSec')
            ActivateStagingSec    = $BoundParams.ContainsKey('ActivateStagingSec')
            ActivateProductionSec = $BoundParams.ContainsKey('ActivateProductionSec')
            # Common
            VersionNotes       = $BoundParams['VersionNotes']
            Dry                = $BoundParams.ContainsKey('Dry')
            SkipValidation     = $BoundParams.ContainsKey('SkipValidation')
            Force              = $BoundParams.ContainsKey('Force')
            Debug              = $BoundParams.ContainsKey('Debug')
        })
    }
}

Export-ModuleMember -Function New-BMPTemplate, Get-BMPParamPolicy, Invoke-BMPTemplate
