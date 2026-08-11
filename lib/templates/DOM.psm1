<#
.SYNOPSIS
Akamai Domain Ownership Management (DOM) template handler

.DESCRIPTION
Handles DOM plan/apply flow using the new-dom Terraform folder.
DOM is exposed as a run-style template action: -Run [-Dry].
#>

using module ../core/TerraformRunner.psm1
using module ../core/Logger.psm1

class DOMTemplate {
    [string]$TemplateFolder

    DOMTemplate([string]$templateFolder) {
        $this.TemplateFolder = $templateFolder
    }

    [void] ValidatePrerequisites() {
        Write-Host "Validating DOM prerequisites..." -ForegroundColor Cyan

        $tfvarsPath = "./$($this.TemplateFolder)/terraform.tfvars"
        if (-not (Test-Path $tfvarsPath)) {
            throw "DOM terraform.tfvars file not found: $tfvarsPath. Copy terraform.tfvars.dist to terraform.tfvars and update values."
        }
    }

    [hashtable] BuildTerraformVars() {
        return @{}
    }

    [void] Deploy([bool]$dryRun) {
        Write-Host "Running DOM template" -ForegroundColor Green

        $this.ValidatePrerequisites()

        $varFile = "./terraform.tfvars"

        Initialize-TerraformBackend `
            -TemplateFolder $this.TemplateFolder `
            -ConfigPath "." `
            -StateFileName "dom-terraform.tfstate" `
            -VarFilePath $varFile

        $vars = $this.BuildTerraformVars()
        $outFile = "./dom-run.tfplan"

        $exitCode = Invoke-TerraformPlan `
            -TemplateFolder $this.TemplateFolder `
            -Variables $vars `
            -VarFilePath $varFile `
            -OutFile $outFile

        if ($exitCode -ne 0) {
            throw "Terraform plan failed for DOM"
        }

        if (-not $dryRun) {
            $exitCode = Invoke-TerraformApply `
                -TemplateFolder $this.TemplateFolder `
                -PlanFile $outFile

            if ($exitCode -ne 0) {
                throw "Terraform apply failed for DOM"
            }
        }

        Write-Host "DOM run completed successfully" -ForegroundColor Green
        Write-Host "Generated output files in ./new-dom: dom_challenges.txt, dom_validation_entries.txt, dom_search_results.txt" -ForegroundColor Cyan
    }

    [void] Destroy() {
        throw "Destroy is not supported for DOM. Use: .\deploy.ps1 dom -Run [-Dry]"
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
        Required      = @("Run")
        RequiredHints = @{ Run = "Use: -Run" }
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

    if (-not $BoundParams.ContainsKey('Run')) {
        throw "Run parameter required for 'dom' template. Use: -Run"
    }

    $template = New-DOMTemplate -TemplateFolder $TemplateFolder
    $template.Deploy($BoundParams.ContainsKey('Dry'))
}

Export-ModuleMember -Function New-DOMTemplate, Get-DOMParamPolicy, Invoke-DOMTemplate