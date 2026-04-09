<#
.SYNOPSIS
Core Terraform execution functions

.DESCRIPTION
Provides shared functions for running Terraform commands across all templates
#>

function Initialize-TerraformBackend {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TemplateFolder,
        
        [Parameter(Mandatory = $true)]
        [string]$ConfigPath,
        
        [Parameter(Mandatory = $true)]
        [string]$StateFileName,

        # When provided, a refresh-only drift check runs after init.
        # Omit this parameter (destroy, CPS, etc.) to skip drift detection.
        [Parameter(Mandatory = $false)]
        [string]$VarFilePath = "",

        [Parameter(Mandatory = $false)]
        [bool]$Force = $false
    )
    
    # Create backend config file
    $backendConfig = "path=`"./$ConfigPath/$StateFileName`""
    $backendConfigPath = "./$TemplateFolder/$ConfigPath/config.backend"
    
    $backendConfig | Out-File -FilePath $backendConfigPath -Force
    
    Write-Host "Initializing Terraform..." -ForegroundColor Cyan
    terraform -chdir="./$TemplateFolder" init -upgrade `
        -backend-config "./$ConfigPath/config.backend" `
        -reconfigure | Out-Default
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "`nTerraform initialization failed with exit code: $LASTEXITCODE" -ForegroundColor Red
        throw "Terraform initialization failed"
    }

    # Drift detection — only when a varfile is supplied and -Force is not set
    if ($VarFilePath -and -not $Force) {
        $driftResult = Invoke-TerraformDriftCheck -TemplateFolder $TemplateFolder -VarFilePath $VarFilePath
        if ($driftResult.HasDrift) {
            Write-Host ""
            Write-Host "WARNING: Configuration drift detected!" -ForegroundColor Yellow
            Write-Host "Remote resources differ from the Terraform state." -ForegroundColor Yellow
            Write-Host "Pass -Force to skip this prompt." -ForegroundColor Gray
            $confirm = Read-Host "Continue with deployment? (y/N)"
            if ($confirm -ne 'y' -and $confirm -ne 'Y') {
                throw "Deployment aborted by user due to configuration drift."
            }
        }
        elseif ($driftResult.ExitCode -eq 1) {
            Write-Warning "Drift check encountered an error. Continuing without drift information."
        }
        else {
            Write-Host "No drift detected." -ForegroundColor Green
        }
    }
}

function Invoke-TerraformPlan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TemplateFolder,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Variables,
        
        [Parameter(Mandatory = $true)]
        [string]$VarFilePath,
        
        [Parameter(Mandatory = $true)]
        [string]$OutFile
    )
    
    # Build variable arguments
    $varArgs = @()
    foreach ($key in $Variables.Keys) {
        $value = $Variables[$key]
        $varArgs += "-var"
        $varArgs += "$key=$value"
    }
    
    # Add var-file
    $varArgs += "-var-file"
    $varArgs += $VarFilePath
    
    # Add output file
    $varArgs += "-out"
    $varArgs += $OutFile
    
    Write-Host "Running Terraform plan..." -ForegroundColor Cyan
    terraform -chdir="./$TemplateFolder" plan @varArgs | Out-Default
    
    return $LASTEXITCODE
}

function Invoke-TerraformApply {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TemplateFolder,
        
        [Parameter(Mandatory = $true)]
        [string]$PlanFile
    )
    
    Write-Host "Applying Terraform changes..." -ForegroundColor Cyan
    terraform -chdir="./$TemplateFolder" apply $PlanFile | Out-Default
    
    return $LASTEXITCODE
}

function Invoke-TerraformDestroy {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TemplateFolder,
        
        [Parameter(Mandatory = $true)]
        [string]$VarFilePath,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Variables = @{},
        
        [Parameter(Mandatory = $false)]
        [switch]$AutoApprove
    )
    
    # Build variable arguments
    $varArgs = @()
    foreach ($key in $Variables.Keys) {
        $value = $Variables[$key]
        $varArgs += "-var"
        $varArgs += "$key=$value"
    }
    
    # Add var-file
    $varArgs += "-var-file"
    $varArgs += $VarFilePath
    
    if ($AutoApprove) {
        $varArgs += "-auto-approve"
    }
    
    Write-Host "Destroying Terraform resources..." -ForegroundColor Red
    terraform -chdir="./$TemplateFolder" destroy @varArgs | Out-Default
    
    return $LASTEXITCODE
}

function Test-TerraformResourceExists {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TemplateFolder,
        
        [Parameter(Mandatory = $true)]
        [string]$ResourceName
    )
    
    $stateList = terraform -chdir="./$TemplateFolder" state list
    
    foreach ($resource in $stateList) {
        if ($resource -match $ResourceName) {
            return $true
        }
    }
    
    return $false
}

function Get-TerraformOutput {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TemplateFolder
    )
    
    $outputJson = terraform -chdir="./$TemplateFolder" output -json
    if ($LASTEXITCODE -eq 0 -and $outputJson) {
        return $outputJson | ConvertFrom-Json
    }
    
    return $null
}

function Invoke-TerraformDriftCheck {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TemplateFolder,

        [Parameter(Mandatory = $true)]
        [string]$VarFilePath,

        [Parameter(Mandatory = $false)]
        [hashtable]$Variables = @{}
    )

    # Build variable arguments
    $varArgs = @()
    foreach ($key in $Variables.Keys) {
        $varArgs += "-var"
        $varArgs += "$key=$($Variables[$key])"
    }
    $varArgs += "-var-file"
    $varArgs += $VarFilePath

    Write-Host "Checking for configuration drift (refresh-only)..." -ForegroundColor Cyan
    terraform -chdir="./$TemplateFolder" plan -refresh-only @varArgs | Out-Default

    # Exit codes: 0 = no changes, 1 = error, 2 = drift detected
    return @{
        HasDrift = ($LASTEXITCODE -eq 2)
        ExitCode = $LASTEXITCODE
    }
}

Export-ModuleMember -Function Initialize-TerraformBackend, Invoke-TerraformPlan, Invoke-TerraformApply, Invoke-TerraformDestroy, Test-TerraformResourceExists, Get-TerraformOutput, Invoke-TerraformDriftCheck
