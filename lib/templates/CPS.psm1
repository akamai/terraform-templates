<#
.SYNOPSIS
Certificate Provisioning System (CPS) template handler

.DESCRIPTION
Handles creation, upload, and destruction of CPS certificates
#>

using module ../core/TerraformRunner.psm1
using module ../core/Logger.psm1

class CPSTemplate {
    [string]$CpsType
    [string]$CertNumber
    [string]$TemplateFolder
    
    CPSTemplate([string]$cpsType, [string]$certNumber, [string]$templateFolder) {
        $this.CpsType = $cpsType
        $this.CertNumber = $certNumber
        $this.TemplateFolder = $templateFolder
    }
    
    [void] ValidatePrerequisites() {
        Write-Host "Validating CPS prerequisites..." -ForegroundColor Cyan
        
        $tfvarsPath = "./$($this.TemplateFolder)/certificates/$($this.CertNumber)/$($this.CertNumber).tfvars"
        if (-not (Test-Path $tfvarsPath)) {
            throw "Certificate file not found: $tfvarsPath"
        }
    }
    
    [hashtable] BuildTerraformVars() {
        return @{
            "cert_name" = $this.CertNumber
        }
    }
    
    [void] CreateCert([bool]$dryRun) {
        Write-Host "Creating CPS certificate: $($this.CertNumber)" -ForegroundColor Green
        
        $this.ValidatePrerequisites()
        
        $configPath = "certificates/$($this.CertNumber)"
        $stateFileName = "$($this.CertNumber)-terraform.tfstate"
        
        Initialize-TerraformBackend -TemplateFolder $this.TemplateFolder -ConfigPath $configPath -StateFileName $stateFileName
        
        $vars = $this.BuildTerraformVars()
        $outFile = "./$configPath/$($this.CertNumber).tfplan"
        $varFile = "./$configPath/$($this.CertNumber).tfvars"
        
        $exitCode = Invoke-TerraformPlan -TemplateFolder $this.TemplateFolder -Variables $vars -VarFilePath $varFile -OutFile $outFile
        
        if ($exitCode -ne 0) {
            throw "Terraform plan failed"
        }
        
        if (-not $dryRun) {
            $maxRetries = 2
            $retryCount = 0
            $success = $false
            
            while (-not $success -and $retryCount -lt $maxRetries) {
                $exitCode = Invoke-TerraformApply -TemplateFolder $this.TemplateFolder -PlanFile $outFile
                
                if ($exitCode -eq 0) {
                    $success = $true
                    Write-Host "✓ CPS certificate creation completed successfully" -ForegroundColor Green
                }
                else {
                    $retryCount++
                    if ($retryCount -ge $maxRetries) {
                        throw "CPS certificate creation failed after $maxRetries attempts"
                    }
                    Write-Host "Retrying terraform apply..." -ForegroundColor Yellow
                }
            }
        }
    }
    
    [void] UploadCert([bool]$dryRun) {
        # Upload is the same as create for CPS
        $this.CreateCert($dryRun)
    }
    
    [void] DestroyCert() {
        Write-Host "Destroying CPS certificate: $($this.CertNumber)" -ForegroundColor Red
        
        $configPath = "certificates/$($this.CertNumber)"
        $stateFileName = "$($this.CertNumber)-terraform.tfstate"
        
        Initialize-TerraformBackend -TemplateFolder $this.TemplateFolder -ConfigPath $configPath -StateFileName $stateFileName
        
        $vars = $this.BuildTerraformVars()
        $varFile = "./$configPath/$($this.CertNumber).tfvars"
        
        $maxRetries = 2
        $retryCount = 0
        $success = $false
        
        while (-not $success -and $retryCount -lt $maxRetries) {
            $autoApprove = $retryCount -gt 0
            $exitCode = Invoke-TerraformDestroy -TemplateFolder $this.TemplateFolder -VarFilePath $varFile -Variables $vars -AutoApprove:$autoApprove
            
            if ($exitCode -eq 0) {
                $success = $true
                Write-Host "✓ CPS certificate destruction completed successfully" -ForegroundColor Green
            }
            else {
                $retryCount++
                if ($retryCount -ge $maxRetries) {
                    throw "CPS certificate destruction failed after $maxRetries attempts"
                }
                Write-Host "Retrying terraform destroy..." -ForegroundColor Yellow
            }
        }
    }
}

function New-CPSTemplate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$CpsType,
        
        [Parameter(Mandatory = $true)]
        [string]$CertNumber,
        
        [Parameter(Mandatory = $true)]
        [string]$TemplateFolder
    )
    
    return [CPSTemplate]::new($CpsType, $CertNumber, $TemplateFolder)
}

Export-ModuleMember -Function New-CPSTemplate
