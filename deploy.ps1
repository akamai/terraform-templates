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

.PARAMETER Help
Displays detailed help information about the script.

.EXAMPLE
PS> .\deploy.ps1 aap -Env prod -Save -Notes "Some user user notes" 

.EXAMPLE
PS> .\deploy.ps1 aapasm -Env dev -ActivateStaging -Debug

.EXAMPLE
PS> .\deploy.ps1 pm -Env qa -ActivateProduction -Notes "Some user user notes" 

.EXAMPLE
PS> .\deploy.ps1 pm -Env prod -ActivateStaging -ActivateProduction

.LINK
https://git.source.akamai.com/projects/GSS-DEVOPS/repos/ps-terraform-templates/browse
#>

[CmdletBinding(DefaultParameterSetName = 'save-activate')]
Param(
    [Parameter(Position = 0, Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("aap", "aapasm", "pm")]
    [string]
    $TemplateType,

    [Parameter(Mandatory = $true)]
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
    $Help
)


# Start timing the script execution
$ScriptStartTime = Get-Date

# Display help if requested
if ($Help) {
    Get-Help $PSCommandPath -Full
    exit 0
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