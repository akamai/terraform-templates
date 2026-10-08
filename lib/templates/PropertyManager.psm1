<#
.SYNOPSIS
Property Manager template handler

.DESCRIPTION
Handles deployment, activation, and destruction of Property Manager configurations
#>

using module ../core/TerraformRunner.psm1
using module ../core/Validation.psm1
using module ../core/Logger.psm1

function Get-TfVarList {
    <#
    .SYNOPSIS
    Reads a Terraform list-of-strings variable from a tfvars file.

    .DESCRIPTION
    Parses simple HCL list literals of the form: name = ["a", "b", "c"].
    Whitespace and newlines inside the brackets are tolerated. Returns an
    empty array if the variable is not found.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [string]$VarName
    )

    if (-not (Test-Path $FilePath)) {
        throw "File not found: $FilePath"
    }

    $content = Get-Content -Path $FilePath -Raw
    $pattern = "(?ms)^\s*$([regex]::Escape($VarName))\s*=\s*\[(?<body>.*?)\]"

    if ($content -notmatch $pattern) {
        return @()
    }

    $body = $matches['body']
    $items = [regex]::Matches($body, '"([^"]+)"') | ForEach-Object { $_.Groups[1].Value }
    return @($items)
}

function Test-DomainOwnership {
    <#
    .SYNOPSIS
    Verifies every hostname listed in tfvars has completed Akamai Domain Ownership validation.

    .DESCRIPTION
    Calls Get-DOMDomain (Akamai.Property module) to query existing Domain Ownership 
    validations. Checks each hostname against three validation scopes (HOST, WILDCARD, DOMAIN).
    A hostname is considered validated if it is validated under any scope. Any hostname that
    is not validated under any scope causes a hard failure.

    .PARAMETER TfVarsPath
    Path to the environment tfvars file containing edgerc_path, edgerc_section, and hostnames.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TfVarsPath
    )

    Write-Host "Validating Akamai Domain Ownership for configured hostnames..." -ForegroundColor Cyan

    $edgercPath = Get-TfVarValue -FilePath $TfVarsPath -VarName "edgerc_path"
    $edgercSection = Get-TfVarValue -FilePath $TfVarsPath -VarName "edgerc_section"

    if (-not $edgercPath -or -not $edgercSection) {
        throw "Missing edgerc_path or edgerc_section in tfvars file: $TfVarsPath"
    }

    $hostnames = @(Get-TfVarList -FilePath $TfVarsPath -VarName "hostnames")
    if ($hostnames.Count -eq 0) {
        throw "No hostnames found in tfvars file: $TfVarsPath. Add a 'hostnames = [`"...`"]' entry before deploying."
    }

    if (-not (Get-Command -Name Get-DOMDomain -ErrorAction SilentlyContinue)) {
        throw "Get-DOMDomain cmdlet not found. Install Akamai.Property >= 3.0.0 (Install-Module Akamai.Property -MinimumVersion 3.0.0)."
    }

    Write-Host "Checking DOM status for $($hostnames.Count) hostname(s): $($hostnames -join ', ')" -ForegroundColor Gray

    $validationScopes = @("HOST", "WILDCARD", "DOMAIN")
    $notValidated = @()

    foreach ($hostname in $hostnames) {
        $isValidated = $false
        $validatedScope = $null

        # Ancestors of the hostname, nearest first, down to the registrable-level (two labels).
        $labels = $hostname.ToLower().TrimEnd('.') -split '\.'
        $ancestors = @()
        for ($i = 1; $i -le $labels.Count - 2; $i++) {
            $ancestors += ($labels[$i..($labels.Count - 1)] -join '.')
        }

        # Supports HOST, WILDCARD and DOMAIN validation scopes.
        $candidatesByScope = [ordered]@{
            HOST     = @($hostname)
            WILDCARD = @($ancestors | Select-Object -First 1)
            DOMAIN   = @($hostname) + $ancestors
        }

        foreach ($scope in $validationScopes) {
            foreach ($candidate in $candidatesByScope[$scope]) {
                try {
                    # Get-DOMDomain returns HTTP 404 when no entry exists
                    $domEntry = Get-DOMDomain `
                        -DomainName $candidate `
                        -ValidationScope $scope `
                        -EdgeRCFile $edgercPath `
                        -Section $edgercSection `
                        -ErrorAction Stop

                    if ($domEntry -and $domEntry.domainStatus -eq "VALIDATED") {
                        $isValidated = $true
                        $validatedScope = "$scope ($candidate)"
                        break
                    }
                }
                catch {
                    continue
                }
            }
            if ($isValidated) { break }
        }

        if ($isValidated) {
            Write-Host "  ✓ $hostname : VALIDATED (scope: $validatedScope)" -ForegroundColor Green
        }
        else {
            $notValidated += [pscustomobject]@{ Hostname = $hostname; Scopes = $validationScopes -join ", " }
        }
    }

    if ($notValidated.Count -gt 0) {
        $pad = ($notValidated | ForEach-Object { $_.Hostname.Length } | Measure-Object -Maximum).Maximum
        $affected = ($notValidated | ForEach-Object {
            "  • {0}  (tried scopes: {1})" -f $_.Hostname.PadRight($pad), $_.Scopes
        }) -join "`n"

        throw @"
DOM validation is not completed for the following hostname(s):

Affected hostnames:
$affected

Action required:
Ensure these hostnames are validated in at least one validation scope (HOST, WILDCARD, or DOMAIN)
via the Akamai Domain Ownership Manager (DOM) workflow before activating this property.
"@
    }

    Write-Host "✓ All hostnames have completed Domain Ownership validation" -ForegroundColor Green
    return $true
}

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

        # DOM must be run before the property is activated; fail fast if any hostname is not VALIDATED.
        if ($this.DeployParams.ActivateStaging -or $this.DeployParams.ActivateProduction) {
            Test-DomainOwnership -TfVarsPath $tfvarsPath
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

        # Only validate if enable_mpulse is enabled and not skipped
        if (-not $this.DeployParams.SkipValidation) {
            $enableMPulseValue = Get-TfVarValue -FilePath $tfvarsPath -VarName "enable_mPulse"
        
            if ($enableMPulseValue -eq "true") {
                Write-Host "mPulse enabled - validating product ID" -ForegroundColor Cyan

                $expectedProducts = @(
                    @{Id = "M-LC-161244"; Name = "mPulse::mPulse"}
                )

                Test-AkamaiProductId -TfVarsPath $tfvarsPath -ExpectedProducts $expectedProducts
            }
            else {
                Write-Host "mPulse not enabled - skipping product validation" -ForegroundColor Yellow
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
        
        # Initialize Terraform (drift check runs automatically when VarFilePath is supplied)
        Initialize-TerraformBackend -TemplateFolder $this.TemplateFolder -ConfigPath $configPath -StateFileName $stateFileName `
            -VarFilePath "./$configPath/$($this.Environment).tfvars" -Force $params.Force

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

        Confirm-DestroyOperation -ResourceDescription "Property Manager configuration for environment: $($this.Environment)"

        $configPath = "environments/$($this.Environment)"
        $stateFileName = "$($this.Environment)-terraform.tfstate"
        
        Initialize-TerraformBackend -TemplateFolder $this.TemplateFolder -ConfigPath $configPath -StateFileName $stateFileName
        
        $varFile = "./$configPath/$($this.Environment).tfvars"
        
        $maxRetries = 2
        $retryCount = 0
        $success = $false
        
        while (-not $success -and $retryCount -lt $maxRetries) {
            $exitCode = Invoke-TerraformDestroy `
                -TemplateFolder $this.TemplateFolder `
                -VarFilePath $varFile `
                -AutoApprove `
                -NoRefresh
            
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

function Get-PropertyManagerParamPolicy {
    <#
    .SYNOPSIS
    Returns the parameter policy for the Property Manager template.
    Called automatically by deploy.ps1 before routing begins.
    #>
    return @{
        Required      = @("Environment")
        RequiredHints = @{ Environment = "Use: -Env <environment>" }
        Allowed       = @(
            "Environment", "Save", "ActivateStaging", "ActivateProduction",
            "Destroy", "VersionNotes", "SkipValidation", "Dry",
            "BackendType"
        )
        MustHaveOneOf = @("Save", "ActivateStaging", "ActivateProduction", "Destroy")
    }
}

function Invoke-PropertyManagerTemplate {
    <#
    .SYNOPSIS
    Dispatches a Property Manager deployment request received from deploy.ps1.
    Owns all PM-specific routing logic so that deploy.ps1 stays template-agnostic.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$TemplateFolder,

        [Parameter(Mandatory = $true)]
        [hashtable]$BoundParams
    )

    $template = New-PropertyManagerTemplate -Environment $BoundParams['Environment'] -TemplateFolder $TemplateFolder

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

Export-ModuleMember -Function New-PropertyManagerTemplate, Get-PropertyManagerParamPolicy, Invoke-PropertyManagerTemplate