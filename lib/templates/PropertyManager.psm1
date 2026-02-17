<#
.SYNOPSIS
Property Manager template handler

.DESCRIPTION
Handles deployment, activation, and destruction of Property Manager configurations
#>

using module ../core/TerraformRunner.psm1
using module ../core/Validation.psm1
using module ../core/Logger.psm1

class PropertyManagerTemplate {
    [string]$Environment
    [string]$TemplateFolder
    [hashtable]$DeployParams
    
    PropertyManagerTemplate([string]$environment, [string]$templateFolder) {
        $this.Environment = $environment
        $this.TemplateFolder = $templateFolder
        $this.DeployParams = @{}
    }
    
    [void] ValidatePrerequisites() {
        Write-Host "Validating Property Manager prerequisites..." -ForegroundColor Cyan
        
        $tfvarsPath = "./$($this.TemplateFolder)/environments/$($this.Environment)/$($this.Environment).tfvars"
        if (-not (Test-Path $tfvarsPath)) {
            throw "Environment file not found: $tfvarsPath"
        }
        
        # Only validate if secure_by_default is enabled and not skipped
        if (-not $this.DeployParams.SkipValidation) {
            $secureByDefaultValue = Get-TfVarValue -FilePath $tfvarsPath -VarName "secure_by_default"
            
            if ($secureByDefaultValue -eq "true") {
                Write-Host "Secure by Default enabled - validating product ID" -ForegroundColor Cyan
                
                $expectedProducts = @(
                    @{Id = "M-LC-168555"; Name = "Default DV - SNI"}
                )
                
                Test-AkamaiProductId -TfVarsPath $tfvarsPath -ExpectedProducts $expectedProducts
            }
            else {
                Write-Host "Secure by Default not enabled - skipping product validation" -ForegroundColor Yellow
            }
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
        
        # Property Manager uses different resource names
        $stagingExists = Test-TerraformResourceExists -TemplateFolder $this.TemplateFolder -ResourceName "akamai_property_activation.staging"
        $prodExists = Test-TerraformResourceExists -TemplateFolder $this.TemplateFolder -ResourceName "akamai_property_activation.production"
        
        Write-Host "Previous activation to staging found: $stagingExists" -ForegroundColor Gray
        Write-Host "Previous activation to production found: $prodExists" -ForegroundColor Gray
        
        $vars["activation_to_staging_exists"] = $stagingExists ? "true" : "false"
        $vars["activation_to_production_exists"] = $prodExists ? "true" : "false"
        
        return $vars
    }
    
    [void] Deploy([hashtable]$params) {
        $this.DeployParams = $params
        
        Write-Host "Deploying Property Manager configuration for environment: $($this.Environment)" -ForegroundColor Green
        
        $this.ValidatePrerequisites()
        
        $configPath = "environments/$($this.Environment)"
        $stateFileName = "$($this.Environment)-terraform.tfstate"
        $logPath = "./$($this.TemplateFolder)/$configPath/$($this.Environment)-akamai_tf.log"
        
        Initialize-TerraformBackend -TemplateFolder $this.TemplateFolder -ConfigPath $configPath -StateFileName $stateFileName
        
        if ($params.Debug) {
            Enable-TerraformDebugLogging -LogPath $logPath
        }
        
        $vars = $this.BuildTerraformVars()
        
        $outFileName = if ($params.Save) { "$($this.Environment)-save.tfplan" }
                      elseif ($params.ActivateStaging -and -not $params.ActivateProduction) { "$($this.Environment)-staging.tfplan" }
                      elseif ($params.ActivateProduction -and -not $params.ActivateStaging) { "$($this.Environment)-production.tfplan" }
                      elseif ($params.ActivateStaging -and $params.ActivateProduction) { "$($this.Environment)-production.tfplan" }
                      else { "$($this.Environment)-default.tfplan" }
        
        $outFile = "./$configPath/$outFileName"
        $varFile = "./$configPath/$($this.Environment).tfvars"
        
        $exitCode = Invoke-TerraformPlan -TemplateFolder $this.TemplateFolder -Variables $vars -VarFilePath $varFile -OutFile $outFile
        
        if ($exitCode -ne 0) {
            if ($params.Debug) {
                Write-Host "`nDebug log saved to: $logPath" -ForegroundColor Yellow
            }
            throw "Terraform plan failed with exit code: $exitCode. Check the output above for details."
        }
        
        if (-not $params.Dry) {
            $maxRetries = 2
            $retryCount = 0
            $success = $false
            
            while (-not $success -and $retryCount -lt $maxRetries) {
                $exitCode = Invoke-TerraformApply -TemplateFolder $this.TemplateFolder -PlanFile $outFile
                
                if ($exitCode -eq 0) {
                    $success = $true
                    Write-Host "✓ Property Manager deployment completed successfully" -ForegroundColor Green
                }
                else {
                    $retryCount++
                    if ($retryCount -ge $maxRetries) {
                        throw "Property Manager deployment failed after $maxRetries attempts"
                    }
                    Write-Host "Retrying terraform apply..." -ForegroundColor Yellow
                }
            }
        }
        
        if ($params.Debug) {
            Disable-TerraformDebugLogging
        }
    }
    
    [void] Destroy() {
        Write-Host "Destroying Property Manager configuration for environment: $($this.Environment)" -ForegroundColor Red
        
        $configPath = "environments/$($this.Environment)"
        $stateFileName = "$($this.Environment)-terraform.tfstate"
        
        Initialize-TerraformBackend -TemplateFolder $this.TemplateFolder -ConfigPath $configPath -StateFileName $stateFileName
        
        $varFile = "./$configPath/$($this.Environment).tfvars"
        
        $maxRetries = 2
        $retryCount = 0
        $success = $false
        
        while (-not $success -and $retryCount -lt $maxRetries) {
            $autoApprove = $retryCount -gt 0
            $exitCode = Invoke-TerraformDestroy -TemplateFolder $this.TemplateFolder -VarFilePath $varFile -AutoApprove:$autoApprove
            
            if ($exitCode -eq 0) {
                $success = $true
                Write-Host "✓ Property Manager destruction completed successfully" -ForegroundColor Green
            }
            else {
                $retryCount++
                if ($retryCount -ge $maxRetries) {
                    throw "Property Manager destruction failed after $maxRetries attempts"
                }
                Write-Host "Retrying terraform destroy..." -ForegroundColor Yellow
            }
        }
    }
}

function New-PropertyManagerTemplate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Environment,
        
        [Parameter(Mandatory = $true)]
        [string]$TemplateFolder
    )
    
    return [PropertyManagerTemplate]::new($Environment, $TemplateFolder)
}

Export-ModuleMember -Function New-PropertyManagerTemplate
