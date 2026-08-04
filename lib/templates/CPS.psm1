<#
.SYNOPSIS
Certificate Provisioning System (CPS) template handler

.DESCRIPTION
Handles creation, upload, and destruction of CPS certificates
#>

using module ../core/TerraformRunner.psm1
using module ../core/Logger.psm1
using module ../core/Validation.psm1

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
    
    [void] CreateCert([bool]$dryRun, [bool]$force, [bool]$debug) {
        Write-Host "Creating CPS certificate: $($this.CertNumber)" -ForegroundColor Green
        
        $this.ValidatePrerequisites()
        
        $configPath = "certificates/$($this.CertNumber)"
        $stateFileName = "$($this.CertNumber)-terraform.tfstate"
        $logPath = "./$($this.TemplateFolder)/$configPath/$($this.CertNumber)-akamai_tf.log"

        if ($debug) {
            Enable-TerraformDebugLogging -LogPath $logPath
        }
        
        # Initialize Terraform (drift check runs automatically via -VarFilePath)
        # Pass vars so cert_name is available during the refresh-only plan and
        # terraform doesn't hang waiting for an interactive variable prompt.
        Initialize-TerraformBackend -TemplateFolder $this.TemplateFolder -ConfigPath $configPath -StateFileName $stateFileName `
            -VarFilePath "./$configPath/$($this.CertNumber).tfvars" -Variables $this.BuildTerraformVars() -Force $force
        
        $vars = $this.BuildTerraformVars()
        $outFile = "./$configPath/$($this.CertNumber).tfplan"
        $varFile = "./$configPath/$($this.CertNumber).tfvars"
        
        $exitCode = Invoke-TerraformPlan -TemplateFolder $this.TemplateFolder -Variables $vars -VarFilePath $varFile -OutFile $outFile
        
        if ($exitCode -ne 0) {
            if ($debug) {
                Write-Host "`nDebug log saved to: $logPath" -ForegroundColor Yellow
                Disable-TerraformDebugLogging
            }
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

        if ($debug) {
            Disable-TerraformDebugLogging
        }
    }
    
    [void] UploadCert([bool]$dryRun, [bool]$force, [bool]$debug) {
        # Upload is the same as create for CPS
        $this.CreateCert($dryRun, $force, $debug)
    }
    
    [void] DestroyCert([bool]$debug) {
        Write-Host "Destroying CPS certificate: $($this.CertNumber)" -ForegroundColor Red

        Confirm-DestroyOperation -ResourceDescription "CPS $($this.CpsType) certificate: $($this.CertNumber)"

        $configPath = "certificates/$($this.CertNumber)"
        $stateFileName = "$($this.CertNumber)-terraform.tfstate"
        $logPath = "./$($this.TemplateFolder)/$configPath/$($this.CertNumber)-akamai_tf.log"

        if ($debug) {
            Enable-TerraformDebugLogging -LogPath $logPath
        }
        
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

        if ($debug) {
            Disable-TerraformDebugLogging
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

function Get-CPSParamPolicy {
    <#
    .SYNOPSIS
    Returns the parameter policy for the CPS template.
    Called automatically by deploy.ps1 before routing begins.
    Note: CpsType presence is pre-validated in deploy.ps1 before this policy runs.
    #>
    return @{
        Allowed       = @("CpsType", "CreateCert", "UploadCert", "DestroyCert", "Dry")
        MustHaveOneOf = @("CreateCert", "UploadCert", "DestroyCert")
    }
}

function Get-CPSTemplateFolder {
    <#
    .SYNOPSIS
    Returns the CPS template folder derived from -CpsType.
    Overrides the default folder-map lookup in deploy.ps1 because the CPS folder
    is determined by the certificate type, not the template-type key alone.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$BoundParams
    )

    if (-not $BoundParams['CpsType']) {
        throw "CpsType is required for CPS template. Use: -CpsType dv-san-cert or -CpsType third-party-cert"
    }
    return "new-$($BoundParams['CpsType'])"
}

function Invoke-CPSTemplate {
    <#
    .SYNOPSIS
    Dispatches a CPS certificate operation received from deploy.ps1.
    Owns all CPS-specific routing logic so that deploy.ps1 stays template-agnostic.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$TemplateFolder,

        [Parameter(Mandatory = $true)]
        [hashtable]$BoundParams
    )

    $action     = $null
    $certNumber = $null

    if ($BoundParams.ContainsKey('CreateCert')) {
        $action     = 'create'
        $certNumber = $BoundParams['CreateCert']
    }
    elseif ($BoundParams.ContainsKey('UploadCert')) {
        $action     = 'upload'
        $certNumber = $BoundParams['UploadCert']
    }
    elseif ($BoundParams.ContainsKey('DestroyCert')) {
        $action     = 'destroy'
        $certNumber = $BoundParams['DestroyCert']
    }

    $template = New-CPSTemplate -CpsType $BoundParams['CpsType'] -CertNumber $certNumber -TemplateFolder $TemplateFolder

    $isDry   = $BoundParams.ContainsKey('Dry')
    $isForce = $BoundParams.ContainsKey('Force')
    $isDebug = $BoundParams.ContainsKey('Debug')

    switch ($action) {
        'create'  { $template.CreateCert($isDry, $isForce, $isDebug) }
        'upload'  { $template.UploadCert($isDry, $isForce, $isDebug) }
        'destroy' { $template.DestroyCert($isDebug) }
    }
}

Export-ModuleMember -Function New-CPSTemplate, Get-CPSParamPolicy, Get-CPSTemplateFolder, Invoke-CPSTemplate
