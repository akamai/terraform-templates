<#
.SYNOPSIS
App & API Protector (AAP) template handler

.DESCRIPTION
Handles deployment, activation, and destruction of AAP configurations
#>

using module ../core/TerraformRunner.psm1
using module ../core/Validation.psm1
using module ../core/Logger.psm1

class AAPTemplate {
    [string]$Environment
    [string]$TemplateFolder
    [hashtable]$DeployParams
    
    AAPTemplate([string]$environment, [string]$templateFolder) {
        $this.Environment = $environment
        $this.TemplateFolder = $templateFolder
        $this.DeployParams = @{}
    }
    
    [void] ValidatePrerequisites() {
        Write-Host "Validating AAP prerequisites..." -ForegroundColor Cyan
        
        # Check tfvars file exists
        $tfvarsPath = "./$($this.TemplateFolder)/environments/$($this.Environment)/$($this.Environment).tfvars"
        if (-not (Test-Path $tfvarsPath)) {
            throw "Environment file not found: $tfvarsPath"
        }
        
        # Validate product IDs (unless skipped)
        if (-not $this.DeployParams.SkipValidation) {
            $expectedProducts = @(
                @{Id = "M-LC-169584"; Name = "App & API Protector - Included delivery"},
                @{Id = "M-LC-169585"; Name = "App & API Protector - Included advanced delivery"}
            )
            
            Test-AkamaiProductId -TfVarsPath $tfvarsPath -ExpectedProducts $expectedProducts
        }
    }
    
    [hashtable] BuildTerraformVars() {
        $username = Get-Username
        $emailsJson = ConvertTo-Json @("$username@akamai.com") -Compress
        
        $versionNotes = $this.DeployParams.VersionNotes
        if (-not $versionNotes) {
            $versionNotes = Read-Host "Please enter version/activation notes"
            if (-not $versionNotes) {
                $versionNotes = "Used Terraform PS Templates"
            }
        }
        Write-Host "Using version/activation notes: $versionNotes" -ForegroundColor Green
        
        $vars = @{
            "emails" = $emailsJson
            "activation_notes" = $versionNotes
            "version_notes" = $versionNotes
            "activate_to_staging" = $this.DeployParams.ActivateStaging ? "true" : "false"
            "activate_to_production" = $this.DeployParams.ActivateProduction ? "true" : "false"
        }
        
        # Check existing activations
        $stagingExists = Test-TerraformResourceExists -TemplateFolder $this.TemplateFolder -ResourceName "akamai_appsec_activations.staging"
        $prodExists = Test-TerraformResourceExists -TemplateFolder $this.TemplateFolder -ResourceName "akamai_appsec_activations.production"
        
        Write-Host "Previous activation to staging found: $stagingExists" -ForegroundColor Gray
        Write-Host "Previous activation to production found: $prodExists" -ForegroundColor Gray
        
        $vars["activation_to_staging_exists"] = $stagingExists ? "true" : "false"
        $vars["activation_to_production_exists"] = $prodExists ? "true" : "false"
        
        return $vars
    }
    
    [void] HandleApplyFailure() {
        Write-Host "Handling AAP-specific failure: Importing rate policies..." -ForegroundColor Yellow

        $configPath = "environments/$($this.Environment)"
        $varFile    = "./$configPath/$($this.Environment).tfvars"
        # Build the -chdir argument as a plain variable so PowerShell expands it
        # reliably when passing to an external command inside a class method.
        $chdir = "-chdir=./$($this.TemplateFolder)"

        # Read current outputs
        $output   = Get-TerraformOutput -TemplateFolder $this.TemplateFolder
        $configId = if ($output -and $output.config_id) { $output.config_id.value } else { $null }
        $rate     = if ($output -and $output.rate)      { $output.rate.value      } else { $null }

        # On a fresh first deployment the apply fails before data sources are
        # fully evaluated, leaving rate policy IDs empty in the outputs.
        # A refresh-only pass forces Terraform to re-evaluate data sources and
        # write the populated outputs back to state.
        if (-not $configId -or -not $rate -or -not $rate.origin -or -not $rate.post -or -not $rate.page) {
            Write-Host "Rate policy IDs not yet in state; refreshing data sources..." -ForegroundColor Yellow

            $versionNotes = if ($this.DeployParams.VersionNotes) { $this.DeployParams.VersionNotes } else { "refresh" }
            $username     = Get-Username
            $emailsJson   = ConvertTo-Json @("$username@akamai.com") -Compress

            $refreshArgs = @(
                "apply", "-refresh-only", "-auto-approve",
                "-var", "emails=$emailsJson",
                "-var", "version_notes=$versionNotes",
                "-var", "activation_notes=$versionNotes",
                "-var", "activate_to_staging=false",
                "-var", "activate_to_production=false",
                "-var", "activation_to_staging_exists=false",
                "-var", "activation_to_production_exists=false",
                "-var-file", $varFile
            )

            terraform $chdir @refreshArgs | Out-Default

            $output   = Get-TerraformOutput -TemplateFolder $this.TemplateFolder
            $configId = if ($output -and $output.config_id) { $output.config_id.value } else { $null }
            $rate     = if ($output -and $output.rate)      { $output.rate.value      } else { $null }
        }

        if (-not $configId) {
            throw "config_id is empty after refresh. The security configuration may not have been created. Check the apply output above."
        }
        if (-not $rate -or -not $rate.origin -or -not $rate.post -or -not $rate.page) {
            throw "Rate policy IDs are still empty after refresh. Inspect outputs manually: terraform $chdir output -json"
        }

        # Import rate policies
        terraform $chdir import -var-file $varFile `
            "module.security.akamai_appsec_rate_policy.origin_error" "${configId}:$($rate.origin)"
        terraform $chdir import -var-file $varFile `
            "module.security.akamai_appsec_rate_policy.post_page_requests" "${configId}:$($rate.post)"
        terraform $chdir import -var-file $varFile `
            "module.security.akamai_appsec_rate_policy.page_view_requests" "${configId}:$($rate.page)"

        Write-Host "Resources imported successfully" -ForegroundColor Green
    }
    
    [void] Deploy([hashtable]$params) {
        $this.DeployParams = $params
        
        Write-Host "Deploying AAP configuration for environment: $($this.Environment)" -ForegroundColor Green
        
        $this.ValidatePrerequisites()
        
        $configPath = "environments/$($this.Environment)"
        $stateFileName = "$($this.Environment)-terraform.tfstate"
        $logPath = "./$($this.TemplateFolder)/$configPath/$($this.Environment)-akamai_tf.log"
        
        # Initialize Terraform (drift check runs automatically when VarFilePath is supplied)
        Initialize-TerraformBackend -TemplateFolder $this.TemplateFolder -ConfigPath $configPath -StateFileName $stateFileName `
            -VarFilePath "./$configPath/$($this.Environment).tfvars" -Force $params.Force

        # Enable debug logging if requested
        if ($params.Debug) {
            Enable-TerraformDebugLogging -LogPath $logPath
        }
        
        # Build variables
        $vars = $this.BuildTerraformVars()
        
        # Determine output filename
        $outFileName = if ($params.Save) { "$($this.Environment)-save.tfplan" }
                      elseif ($params.ActivateStaging -and -not $params.ActivateProduction) { "$($this.Environment)-staging.tfplan" }
                      elseif ($params.ActivateProduction -and -not $params.ActivateStaging) { "$($this.Environment)-production.tfplan" }
                      elseif ($params.ActivateStaging -and $params.ActivateProduction) { "$($this.Environment)-production.tfplan" }
                      else { "$($this.Environment)-default.tfplan" }
        
        $outFile = "./$configPath/$outFileName"
        $varFile = "./$configPath/$($this.Environment).tfvars"
        
        # Plan
        $exitCode = Invoke-TerraformPlan -TemplateFolder $this.TemplateFolder -Variables $vars -VarFilePath $varFile -OutFile $outFile
        
        if ($exitCode -ne 0) {
            if ($params.Debug) {
                Write-Host "`nDebug log saved to: $logPath" -ForegroundColor Yellow
            }
            throw "Terraform plan failed with exit code: $exitCode. Check the output above for details."
        }
        
        # Apply (with retry logic for AAP quirks)
        if (-not $params.Dry) {
            $maxRetries = 2
            $retryCount = 0
            $success = $false
            
            while (-not $success -and $retryCount -lt $maxRetries) {
                $exitCode = Invoke-TerraformApply -TemplateFolder $this.TemplateFolder -PlanFile $outFile
                
                if ($exitCode -eq 0) {
                    $success = $true
                    Write-Host "✓ AAP deployment completed successfully" -ForegroundColor Green
                }
                else {
                    $retryCount++
                    Write-Warning "Terraform apply failed with exit code: $exitCode"
                    
                    if ($retryCount -lt $maxRetries) {
                        $this.HandleApplyFailure()

                        # Re-plan after imports/refresh — the state changed so the
                        # original plan file is stale and cannot be applied as-is.
                        Write-Host "Re-planning after import..." -ForegroundColor Yellow
                        $exitCode = Invoke-TerraformPlan -TemplateFolder $this.TemplateFolder -Variables $vars -VarFilePath $varFile -OutFile $outFile
                        if ($exitCode -ne 0) {
                            throw "Terraform re-plan failed after import with exit code: $exitCode"
                        }

                        Write-Host "Retrying terraform apply..." -ForegroundColor Yellow
                    }
                    else {
                        throw "AAP deployment failed after $maxRetries attempts"
                    }
                }
            }
        }
        
        # Cleanup debug logging
        if ($params.Debug) {
            Disable-TerraformDebugLogging
        }
    }
    
    [void] Destroy() {
        Write-Host "Destroying AAP configuration for environment: $($this.Environment)" -ForegroundColor Red
        
        $configPath = "environments/$($this.Environment)"
        $stateFileName = "$($this.Environment)-terraform.tfstate"
        
        # Initialize Terraform
        Initialize-TerraformBackend -TemplateFolder $this.TemplateFolder -ConfigPath $configPath -StateFileName $stateFileName
        
        $varFile = "./$configPath/$($this.Environment).tfvars"
        
        # Destroy with retry
        $maxRetries = 2
        $retryCount = 0
        $success = $false
        
        while (-not $success -and $retryCount -lt $maxRetries) {
            $autoApprove = $retryCount -gt 0
            $exitCode = Invoke-TerraformDestroy -TemplateFolder $this.TemplateFolder -VarFilePath $varFile -AutoApprove:$autoApprove -NoRefresh
            
            if ($exitCode -eq 0) {
                $success = $true
                Write-Host "✓ AAP destruction completed successfully" -ForegroundColor Green
            }
            else {
                $retryCount++
                if ($retryCount -ge $maxRetries) {
                    throw "AAP destruction failed after $maxRetries attempts"
                }
                Write-Host "Retrying terraform destroy..." -ForegroundColor Yellow
            }
        }
    }
}

function New-AAPTemplate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Environment,
        
        [Parameter(Mandatory = $true)]
        [string]$TemplateFolder
    )
    
    return [AAPTemplate]::new($Environment, $TemplateFolder)
}

function Get-AAPParamPolicy {
    <#
    .SYNOPSIS
    Returns the parameter policy for the AAP template.
    Called automatically by deploy.ps1 before routing begins.
    #>
    return @{
        Required      = @("Environment")
        RequiredHints = @{ Environment = "Use: -Env <environment>" }
        Allowed       = @(
            "Environment", "Save", "ActivateStaging", "ActivateProduction",
            "Destroy", "VersionNotes", "SkipValidation", "Dry"
        )
        MustHaveOneOf = @("Save", "ActivateStaging", "ActivateProduction", "Destroy")
    }
}

function Invoke-AAPTemplate {
    <#
    .SYNOPSIS
    Dispatches an AAP deployment request received from deploy.ps1.
    Owns all AAP-specific routing logic so that deploy.ps1 stays template-agnostic.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$TemplateFolder,

        [Parameter(Mandatory = $true)]
        [hashtable]$BoundParams
    )

    $template = New-AAPTemplate -Environment $BoundParams['Environment'] -TemplateFolder $TemplateFolder

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

Export-ModuleMember -Function New-AAPTemplate, Get-AAPParamPolicy, Invoke-AAPTemplate
