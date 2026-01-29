<#
.SYNOPSIS 
Save and/or activate resources via Terraform

.DESCRIPTION 
Can be used to 'save' only the changes to the Akamai resource or activate to either staging or production networks, 
or activate to both networks simultaneously.

.PARAMETER TemplateType
Specifies the template type. Available values: aap, aapasm, pm

.PARAMETER Environment
The environment to deploy to (e.g., prod, dev, qa)

.PARAMETER VersionNotes
Specifies the notes to be appended to the configuration version.

.PARAMETER Save
Saves only the modifications to the Akamai resource. Cannot be used with activation parameters.

.PARAMETER ActivateStaging
Activates the Akamai resource to the staging network.

.PARAMETER ActivateProduction
Activates the Akamai resource to the production network.

.PARAMETER Dry
Outputs the terraform plan and performs no actions.

.PARAMETER Destroy
Deactivates and destroys all the resources.

.PARAMETER Debug
Enables debug logging. Saved in ./akamai_tf.log

.PARAMETER SkipValidation
Skips product ID validation. Use this if product IDs have changed or for testing purposes.

.PARAMETER Help
Displays detailed help information about the script.

.EXAMPLE
PS> .\deploy.ps1 aap -Env prod -Save -Notes "Some user user notes"
Create/Save AAP configuration for prod environment without activations, and add custom version and activation notes

.EXAMPLE
PS> .\deploy.ps1 aapasm -Env dev -ActivateStaging -Debug
Create and Activate to staging network an AAP+ASM configuration for the dev environment with debug logging

.EXAMPLE
PS> .\deploy.ps1 pm -Env qa -ActivateProduction -Notes "Some user user notes"
Create and Activate to production network a property manager configuration for qa QA environment, and add custom version and activation notes

.EXAMPLE
PS> .\deploy.ps1 pm -Env prod -ActivateStaging -ActivateProduction
Create and Activate to both staging and production networks simultaneously a property manager configuration for the prod environment

.EXAMPLE
PS> .\deploy.ps1 aap -Env dev -Save -Dry
Preview changes with Terraform plan without applying (dry run)

.EXAMPLE
PS> .\deploy.ps1 aap -Env dev -Save -SkipValidation
Create/Save AAP configuration while skipping product ID validation

.LINK
https://git.source.akamai.com/projects/GSS-DEVOPS/repos/ps-terraform-templates/browse
#>

[CmdletBinding(DefaultParameterSetName = 'save-activate')]
Param(
    [Parameter(Position = 0, Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("aap", "aapasm", "pm")]
    [string]
    $TemplateType,

    [Parameter(Mandatory = $false)]
    [Alias("Env")]
    [string]
    $Environment,

    [Parameter(ParameterSetName = 'save')]
    [switch]
    $Save,
    
    [Parameter(ParameterSetName = 'activate')]
    [switch]
    $ActivateStaging,
    
    [Parameter(ParameterSetName = 'activate')]
    [switch]
    $ActivateProduction,

    [Parameter(ParameterSetName = 'save')]
    [Parameter(ParameterSetName = 'activate')]
    [switch]
    $Dry,

    [Parameter(ParameterSetName = 'activate')]
    [Parameter(ParameterSetName = 'save')]
    [ValidateNotNullOrEmpty()]
    [Alias("Notes")]
    [string]
    $VersionNotes,

    [Parameter(ParameterSetName = 'destroy')]
    [switch]
    $Destroy,

    [Parameter()]
    [switch]
    $SkipValidation,

    [Parameter()]
    [switch]
    $Help
)


# Start timing the script execution
$ScriptStartTime = Get-Date

# Handle common help invocation patterns
if ($args -contains "Help" -or $args -contains "-Help" -or $args -contains "--help" -or $args -contains "help" -or $args -contains "-h") {
    Get-Help $PSCommandPath -Full
    exit 0
}

# Display help if requested
if ($Help) {
    Get-Help $PSCommandPath -Full
    exit 0
}

# Validate required parameters
if (-not $TemplateType) {
    throw "TemplateType is required. Available values: aap, aapasm, pm"
}

if (-not $Environment) {
    throw "Environment parameter is required. Use -Env <environment>"
}

# Map the TemplateType to the actual template folder
switch ($TemplateType) {
    "aap" {
        $TemplateFolder = "new-aap-configuration"
    }
    "aapasm" {
        $TemplateFolder = "new-aapasm-configuration"
    }
    "pm" {
        $TemplateFolder = "new-property"
    }
}


# Validate environment parameter
if (-not (Test-Path "./$TemplateFolder/environments/$Environment/$Environment.tfvars")) {
    throw "Environment file './$TemplateFolder/environments/$Environment/$Environment.tfvars' does not exist"
}

# Validate that at least one parameter is provided
if ($PSCmdlet.ParameterSetName -eq '__AllParameterSets') {
    throw "Please specify at least one parameter: -Save, -ActivateStaging, -ActivateProduction, or -Destroy"
}

# Function to extract tfvars values
function Get-TfVarValue {
    param (
        [string]$FilePath,
        [string]$VarName
    )
    
    $content = Get-Content -Path $FilePath -Raw
    
    # Pattern to match both quoted and unquoted values
    # Matches: var = "value" OR var = value
    $quotedPattern = "$VarName\s*=\s*`"([^`"]+)`""
    $unquotedPattern = "$VarName\s*=\s*(\S+)"
    
    # Try quoted pattern first
    if ($content -match $quotedPattern) {
        return $matches[1]
    }
    # Try unquoted pattern (for booleans, numbers, etc.)
    elseif ($content -match $unquotedPattern) {
        return $matches[1]
    }
    
    return $null
}

# Function to validate product IDs for AAP/AAPASM/PM templates
function Test-AkamaiProductId {
    param (
        [string]$TemplateType,
        [string]$TfVarsPath
    )
    
    # Skip validation for templates that don't require it
    if ($TemplateType -notin @("aap", "aapasm", "pm")) {
        Write-Host "Skipping product validation for template type: $TemplateType" -ForegroundColor Yellow
        return $true
    }
    
    Write-Host "Validating Akamai product ID for template: $TemplateType" -ForegroundColor Cyan
    
    # Extract edgerc values from tfvars
    $edgercPath = Get-TfVarValue -FilePath $TfVarsPath -VarName "edgerc_path"
    $edgercSection = Get-TfVarValue -FilePath $TfVarsPath -VarName "edgerc_section"
    
    if (-not $edgercPath -or -not $edgercSection) {
        Write-Warning "Could not extract edgerc_path or edgerc_section from $TfVarsPath"
        throw "Missing edgerc configuration in tfvars file"
    }
    
    Write-Host "Using EdgeRC: $edgercPath, Section: $edgercSection" -ForegroundColor Gray
    
    # For PM template, check if secure_by_default validation is needed
    $secureByDefault = $false
    if ($TemplateType -eq "pm") {
        $secureByDefaultValue = Get-TfVarValue -FilePath $TfVarsPath -VarName "secure_by_default"
        Write-Host "Secure by Default value: $secureByDefaultValue" -ForegroundColor Gray
        if ($secureByDefaultValue -eq "true") {
            $secureByDefault = $true
            Write-Host "Secure by Default enabled - validating product ID M-LC-168555" -ForegroundColor Cyan
        } else {
            Write-Host "Secure by Default not enabled - skipping product validation for PM template" -ForegroundColor Yellow
            return $true
        }
    }
    
    # Get contracts
    try {
        $contracts = Get-Contract -Section $edgercSection -EdgeRCFile $edgercPath -Depth TOP
        
        if (-not $contracts -or $contracts.Count -eq 0) {
            throw "No contracts found for section: $edgercSection. Check the account_key in your $edgercPath file is correct."
        }
        
        Write-Host "Found $($contracts.Count) contract(s)" -ForegroundColor Gray
        
        # Define valid product IDs and names for each template type
        $validProductIds = @{
            "aap"    = @(
                @{Id = "M-LC-169584"; Name = "App & API Protector - Included delivery"}
                @{Id = "M-LC-169585"; Name = "App & API Protector - Included advanced delivery"}
            )
            "aapasm" = @(
                @{Id = "M-LC-169586"; Name = "App & API Protector with Advanced Security Management - Included delivery"}
                @{Id = "M-LC-169587"; Name = "App & API Protector with Advanced Security Management - Included advanced delivery"}
            )
            "pm"     = @(
                @{Id = "M-LC-168555"; Name = "Default DV - SNI"}
            )
        }
        
        $expectedProducts = $validProductIds[$TemplateType]
        $foundValidProduct = $false
        
        # Check products for each contract
        foreach ($contractId in $contracts) {
            
            Write-Host "Checking products for contract: $contractId" -ForegroundColor Gray
            
            if ([string]::IsNullOrWhiteSpace($contractId)) {
                Write-Warning "Could not extract contract ID from contract object"
                continue
            }
            
            try {
                $products = Get-ProductsPerContract -ContractID $contractId -Section $edgercSection -EdgeRCFile $edgercPath
                
                if ($products) {
                    Write-Host "  Products found for contract ${contractId}:" -ForegroundColor Gray
                    
                    # Debug: Show first product structure
                    # if ($products.Count -gt 0) {
                    #     Write-Host "  [Debug] First product properties: $($products[0] | Get-Member -MemberType Properties | Select-Object -ExpandProperty Name)" -ForegroundColor DarkGray
                    # }
                    
                    foreach ($product in $products) {
                        # Try different property names for product ID
                        $productId = $product.marketingProductId 
                        
                        # Try different property names for product name
                        $productName = $product.marketingProductName
                        
                        if ($productId) {
                            Write-Host "    - $productId ($productName)" -ForegroundColor Gray
                            
                            # Check if product ID matches any expected product
                            $matchedProduct = $expectedProducts | Where-Object { $_.Id -eq $productId }
                            if ($matchedProduct) {
                                Write-Host "✓ Valid product ID found: $productId ($productName) for template: $TemplateType" -ForegroundColor Green
                                $foundValidProduct = $true
                                break
                            }
                        }
                    }
                }
                else {
                    Write-Host "  No products found for contract ${contractId}" -ForegroundColor Yellow
                }
            }
            catch {
                Write-Warning "Failed to get products for contract ${contractId}: $($_.Exception.Message)"
            }
            
            if ($foundValidProduct) {
                break
            }
        }
        
        if (-not $foundValidProduct) {
            $expectedList = ($expectedProducts | ForEach-Object { "$($_.Id) ($($_.Name))" }) -join ", "
            throw "Product validation failed: No valid product ID found for template '$TemplateType'. Expected one of: $expectedList"
        }
        
        return $true
    }
    catch {
        Write-Error "Product validation failed: $_"
        throw $_
    }
}

# Validate product ID before proceeding with Terraform
if (-not $SkipValidation) {
    $tfVarsPath = "./$TemplateFolder/environments/$Environment/$Environment.tfvars"
    try {
        $null = Test-AkamaiProductId -TemplateType $TemplateType -TfVarsPath $tfVarsPath
    }
    catch {
        Write-Error "Deployment aborted due to product validation failure"
        exit 1
    }
}
else {
    Write-Host "Skipping product ID validation (SkipValidation flag set)" -ForegroundColor Yellow
}

# Request the version/activation notes if Save or Activate parameters are used. For now the version notes and activation notes are the same.
if ($Save -or $ActivateStaging -or $ActivateProduction ) {
    
    # Request VersionNotes only if those were not provided in the command line
    if ($VersionNotes) {
        Write-Host "Using provided version/activation notes: $($VersionNotes)" -ForegroundColor Green
    } else {
        # Prompt the user to enter activation notes
        $VersionNotes = Read-Host "Please enter version/activation notes"
        # Display the entered notes
        if ($VersionNotes) {
            Write-Host "You entered the following version/activation notes: $($VersionNotes)" -ForegroundColor Green
        } else {
            $VersionNotes = "Used Terraform PS Templates"
            Write-Host "Using the following version/activation notes: $($VersionNotes)" -ForegroundColor Green
        }
    }
}

function Get-Username {
    $Platform = $PSVersionTable.Platform
    if (-not $Platform -or $Platform -eq 'Win32NT') {
        $Username = $Env:USERNAME
    }
    else {
        $Username = $env:USER
    }
    return $Username
}

# Get commit notes from Git. These are not used at the moment.
$CommitNotes = git log -1 --format='%h %s'

# Get user mail in an automated way and format it as a JSON array
$Email = Get-Username
$EmailList = @($Email + "@akamai.com")
$EmailsJson = ConvertTo-Json -InputObject $EmailList -Compress

$ActivationNotes = $VersionNotes

# Environments directory
$EnvironmentPath = "environments/$Environment"

# Create the config.backend file with the appropriate path
$backendConfig = @"
path="./$EnvironmentPath/$Environment-terraform.tfstate"
"@

# Write the content to config.backend file
$backendConfig | Out-File -FilePath "./$TemplateFolder/$EnvironmentPath/config.backend" -Force

# Reconfigure the backend based on the environment to avoid overwriting the state file
Write-Host "Initializing Terraform"
terraform -chdir="./$TemplateFolder" init -upgrade `
    -backend-config "./$EnvironmentPath/config.backend" `
    -reconfigure

# Function to check if a resource exists in Terraform state
function Test-TerraformResourceExists {
    param (
        [string]$ResourceName
    )
    
    # Keep in mind that the config.backend already knows the location of the state file within the TemplateFolder
    $StateList = terraform -chdir="./$TemplateFolder" state list
    
    foreach ($Resource in $StateList) {
        if ($Resource -match $ResourceName) {
            return $true
        }
    }
    return $false
}

# Determine first activation exists for staging and production
switch ($TemplateType) {
    "pm" {
        $stagingRes = "akamai_property_activation.staging"
        $prodRes = "akamai_property_activation.production"
    }
    default {
        $stagingRes = "akamai_appsec_activations.staging"
        $prodRes = "akamai_appsec_activations.production"
    }
}

Write-Host "Checking for an existing state file..."
$ExistingActivationStaging = Test-TerraformResourceExists $stagingRes
Write-Host "Previous activation to staging found: $ExistingActivationStaging"
$ExistingActivationProduction = Test-TerraformResourceExists $prodRes
Write-Host "Previous activation to production found: $ExistingActivationProduction"

# Determine the output filename based on the mode
$OutFileName = switch ($true) {
    $Save { "$Environment-save.tfplan" }
    ($ActivateStaging -and -not $ActivateProduction) { "$Environment-staging.tfplan" }
    ($ActivateProduction -and -not $ActivateStaging) { "$Environment-production.tfplan" }
    ($ActivateStaging -and $ActivateProduction) { "$Environment-production.tfplan" }
    default { "$Environment-default.tfplan" }
}

# Set debug environment variables if Debug switch is provided
if ($PSBoundParameters.Debug) {
    $logPath = "./$TemplateFolder/$EnvironmentPath/$Environment-akamai_tf.log"

    Write-Host "Debug mode enabled - Logging to: $logPath" -ForegroundColor Yellow
    $env:TF_LOG = "DEBUG"
    $env:TF_LOG_PATH = $logPath
    $env:AKAMAI_HTTP_TRACE_ENABLED = "true"
}

if ($Save -or $ActivateStaging -or $ActivateProduction) {
    Write-Host "Running Terraform now ..." -ForegroundColor Cyan

    # Enabling variables for retry on TF errors
    $maxRetries = 2
    $retryCount = 0
    $success = $false

    while (-not $success -and $retryCount -lt $maxRetries) {        
        # Performing a Terraform plan with the correct set of variables
        terraform -chdir="./$TemplateFolder" plan `
            -var "emails=$EmailsJson" `
            -var activation_notes="$ActivationNotes" `
            -var version_notes="$VersionNotes" `
            -var activate_to_staging="$($ActivateStaging.IsPresent ? "true" : "false")" `
            -var activate_to_production="$($ActivateProduction.IsPresent ? "true" : "false")" `
            -var activation_to_staging_exists="$($ExistingActivationStaging ? "true" : "false")" `
            -var activation_to_production_exists="$($ExistingActivationProduction ? "true" : "false")" `
            -var-file "./$EnvironmentPath/$Environment.tfvars" `
            -out "./$EnvironmentPath/$OutFileName"

        # Proceed with apply (if not dry run)
        if (-Not $Dry) {
            terraform -chdir="./$TemplateFolder" apply "./$EnvironmentPath/$OutFileName"
            
            # Check if terraform apply succeeded
            if ($LASTEXITCODE -ne 0) {
                $retryCount++
                Write-Warning "Terraform apply failed with exit code: $LASTEXITCODE"
                
                if ($retryCount -ge $maxRetries) {
                    Write-Error "Failed to run terraform apply after $maxRetries attempts."
                    throw "Maximum retry attempts reached for terraform execution."
                }
                elseif ($TemplateType -eq "aap") {
                    Write-Host "Importing missing resources before retry..."

                    # Import rate policies. Keep in mind that the config.backend already knows the location of the state 
                    # file within the TemplateFolder
                    $terraformOutput = terraform -chdir="$TemplateFolder" output -json | ConvertFrom-Json
                    $configid = $terraformOutput.config_id.value
                    $rate = $terraformOutput.rate.value
                    $origin = $rate.origin
                    $post = $rate.post
                    $page = $rate.page
                    terraform -chdir="./$TemplateFolder" import -var-file="./$EnvironmentPath/$Environment.tfvars" module.security.akamai_appsec_rate_policy.origin_error "${configid}:${origin}"
                    terraform -chdir="./$TemplateFolder" import -var-file="./$EnvironmentPath/$Environment.tfvars" module.security.akamai_appsec_rate_policy.post_page_requests "${configid}:${post}"
                    terraform -chdir="./$TemplateFolder" import -var-file="./$EnvironmentPath/$Environment.tfvars" module.security.akamai_appsec_rate_policy.page_view_requests "${configid}:${page}"

                    Write-Host "Resources imported. Retrying terraform apply ..."
                    continue
                }
                else {
                    Write-Host "Retrying terraform apply..."
                    continue
                }
            }
        }

        # If we reach here the apply succeeded
        $success = $true
        Write-Host "Terraform execution completed successfully."
    }
}

# Destroy all resources. Allow for TF's "Do you really want to destroy all resources?" prompt.
if ($Destroy) {
    Write-Host "Running Terraform now ..." -ForegroundColor Cyan

    # Enabling variables for retry on TF errors
    $maxRetries = 2
    $retryCount = 0
    $success = $false

    while (-not $success -and $retryCount -lt $maxRetries) { 

        Write-Host "Destroying infrastructure for environment: $Environment" -ForegroundColor Red
        terraform -chdir="./$TemplateFolder" destroy -var-file="./$EnvironmentPath/$Environment.tfvars" 

        # Check if terraform destroy succeeded
        if ($LASTEXITCODE -ne 0) {
            $retryCount++
            Write-Warning "Terraform destroy failed with exit code: $LASTEXITCODE"
            
            if ($retryCount -ge $maxRetries) {
                Write-Error "Failed to run terraform destroy after $maxRetries attempts."
                throw "Maximum retry attempts reached for terraform execution."
            }
            else {
                Write-Host "Retrying terraform destroy..."
                terraform -chdir="./$TemplateFolder" destroy -var-file="./$EnvironmentPath/$Environment.tfvars" --auto-approve
            }
        }

        # If we reach here the apply succeeded
        $success = $true
        Write-Host "Terraform execution completed successfully."
    }
}

# Calculate and display execution time
$ScriptEndTime = Get-Date
$ExecutionDuration = $ScriptEndTime - $ScriptStartTime

Write-Host ""
Write-Host "================================" -ForegroundColor Green
Write-Host "Script Execution Summary" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green
Write-Host "Started:  $($ScriptStartTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Cyan
Write-Host "Finished: $($ScriptEndTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Cyan
Write-Host "Total Duration (hh:mm:ss): $($ExecutionDuration.ToString('hh\:mm\:ss'))" -ForegroundColor Yellow
Write-Host "================================" -ForegroundColor Green