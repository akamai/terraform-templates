<#
.SYNOPSIS
Domain Ownership Management (DOM) template handler

.DESCRIPTION
Handles DOM run operations (create/update/search/validate) through Terraform.
#>

using module ../core/TerraformRunner.psm1
using module ../core/Logger.psm1
using module ../core/Validation.psm1

class DOMTemplate {
    [string]$TemplateFolder
    [hashtable]$DeployParams

    DOMTemplate([string]$templateFolder) {
        $this.TemplateFolder = $templateFolder
        $this.DeployParams = @{}
    }

    [void] ValidatePrerequisites() {
        Write-Host "Validating DOM prerequisites..." -ForegroundColor Cyan

        $tfvarsPath = "./$($this.TemplateFolder)/terraform.tfvars"
        if (-not (Test-Path $tfvarsPath)) {
            throw "Configuration file not found: $tfvarsPath"
        }
    }

    [hashtable] BuildTerraformVars() {
        return @{}
    }

    [void] Deploy([hashtable]$params) {
        $this.DeployParams = $params

        Write-Host "Running DOM configuration..." -ForegroundColor Green

        $this.ValidatePrerequisites()

        $configPath = "."
        $stateFileName = "terraform.tfstate"
        $logPath = "./$($this.TemplateFolder)/dom-akamai_tf.log"

        Initialize-TerraformBackend `
            -TemplateFolder $this.TemplateFolder `
            -ConfigPath $configPath `
            -StateFileName $stateFileName `
            -VarFilePath "./terraform.tfvars" `
            -Force $params.Force

        if ($params.Debug) {
            Enable-TerraformDebugLogging -LogPath $logPath
        }

        $vars = $this.BuildTerraformVars()
        $varFile = "./terraform.tfvars"
        $outFile = "./dom-run.tfplan"

        $exitCode = Invoke-TerraformPlan `
            -TemplateFolder $this.TemplateFolder `
            -Variables $vars `
            -VarFilePath $varFile `
            -OutFile $outFile

        if ($exitCode -ne 0) {
            if ($params.Debug) {
                Write-Host "`nDebug log saved to: $logPath" -ForegroundColor Yellow
                Disable-TerraformDebugLogging
            }
            throw "Terraform plan failed for DOM"
        }

        if (-not $params.Dry) {
            $exitCode = Invoke-TerraformApply `
                -TemplateFolder $this.TemplateFolder `
                -PlanFile $outFile

            if ($exitCode -ne 0) {
                if ($params.Debug) {
                    Write-Host "`nDebug log saved to: $logPath" -ForegroundColor Yellow
                    Disable-TerraformDebugLogging
                }
                throw "Terraform apply failed for DOM"
            }
        }

        if ($params.Debug) {
            Disable-TerraformDebugLogging
        }

        Write-Host "✓ DOM run completed successfully" -ForegroundColor Green
    }
}

function New-DOMTemplate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TemplateFolder
    )

    return [DOMTemplate]::new($TemplateFolder)
}

function Get-DOMParamPolicy {
    return @{
        Allowed       = @("Run", "Dry")
        MustHaveOneOf = @("Run")
    }
}

function Invoke-DOMTemplate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TemplateFolder,

        [Parameter(Mandatory = $true)]
        [hashtable]$BoundParams
    )

    $template = New-DOMTemplate -TemplateFolder $TemplateFolder

    $template.Deploy(@{
        Run   = $BoundParams.ContainsKey('Run')
        Dry   = $BoundParams.ContainsKey('Dry')
        Force = $BoundParams.ContainsKey('Force')
        Debug = $BoundParams.ContainsKey('Debug')
    })
}

Export-ModuleMember -Function New-DOMTemplate, Get-DOMParamPolicy, Invoke-DOMTemplate
