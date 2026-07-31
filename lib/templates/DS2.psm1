<#
.SYNOPSIS
DataStream 2 (DS2) template handler

.DESCRIPTION
Handles deployment and destruction of a DataStream 2 (DS-managed / decoupled)
configuration.

Unlike Property Manager or AAP, DataStream has a single activation dimension
(the stream is either active or not) — there is no separate staging network.
Activation is therefore modelled as follows:

  -Save                 Deploy the stream; the `activate_stream` value from the
                        tfvars file drives whether it is activated.
  -ActivateProduction   Deploy the stream and force `activate_stream = true`
                        (activate the stream without editing the tfvars file).
  -Destroy              Tear the stream down (with confirmation).

To deactivate a running stream, set `activate_stream = false` in the tfvars file
and run -Save.
#>

using module ../core/TerraformRunner.psm1
using module ../core/Logger.psm1
using module ../core/Validation.psm1

class DS2Template {
  [string]$Environment
  [string]$TemplateFolder
  [hashtable]$DeployParams

  DS2Template([string]$environment, [string]$templateFolder) {
    $this.Environment = $environment
    $this.TemplateFolder = $templateFolder
    $this.DeployParams = @{}
  }

  [string] GetRepoRoot() {
    return (Resolve-Path (Join-Path $PSScriptRoot "../../")).Path
  }

  [string] GetTfvarsRelPath() {
    return "./environments/$($this.Environment)/$($this.Environment).tfvars"
  }

  [void] ValidatePrerequisites() {
    Write-Host "Validating DataStream 2 prerequisites..." -ForegroundColor Cyan

    $tfvarsPath = "./$($this.TemplateFolder)/environments/$($this.Environment)/$($this.Environment).tfvars"
    if (-not (Test-Path $tfvarsPath)) {
      throw "Environment file not found: $tfvarsPath"
    }
  }

  [hashtable] BuildTerraformVars() {
    $vars = @{}

    # DataStream has a single activation dimension. Only override the tfvars
    # value when the caller explicitly asks to activate the stream; -Save leaves
    # `activate_stream` under the control of the tfvars file so an already-active
    # stream is never silently deactivated.
    if ($this.DeployParams.ActivateProduction) {
      Write-Host "Activation requested: forcing activate_stream = true" -ForegroundColor Cyan
      $vars["activate_stream"] = "true"
    }

    return $vars
  }

  [void] Deploy([hashtable]$params) {
    $this.DeployParams = $params

    Write-Host "Deploying DataStream 2 configuration for environment: $($this.Environment)" -ForegroundColor Green

    $this.ValidatePrerequisites()

    $configPath = "environments/$($this.Environment)"
    $stateFileName = "$($this.Environment)-terraform.tfstate"
    $logPath = "./$($this.TemplateFolder)/$configPath/$($this.Environment)-akamai_tf.log"
    $varFile = $this.GetTfvarsRelPath()

    # Initialize Terraform (drift check runs automatically when VarFilePath is supplied)
    Initialize-TerraformBackend `
      -TemplateFolder $this.TemplateFolder `
      -ConfigPath $configPath `
      -StateFileName $stateFileName `
      -VarFilePath $varFile `
      -Force $params.Force

    if ($params.Debug) {
      Enable-TerraformDebugLogging -LogPath $logPath
    }

    $vars = $this.BuildTerraformVars()

    $outFileName = if ($params.ActivateProduction) { "$($this.Environment)-activate.tfplan" }
    else { "$($this.Environment)-save.tfplan" }
    $outFile = "./$configPath/$outFileName"

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
      throw "Terraform plan failed for DataStream 2"
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
        throw "Terraform apply failed for DataStream 2"
      }
    }

    if ($params.Debug) {
      Disable-TerraformDebugLogging
    }

    Write-Host "✓ DataStream 2 deployment completed successfully" -ForegroundColor Green
  }

  [void] Destroy([bool]$debug) {
    Write-Host "Destroying DataStream 2 configuration for environment: $($this.Environment)" -ForegroundColor Red

    $this.ValidatePrerequisites()
    Confirm-DestroyOperation -ResourceDescription "DataStream 2 configuration for environment: $($this.Environment)"

    $configPath = "environments/$($this.Environment)"
    $stateFileName = "$($this.Environment)-terraform.tfstate"
    $logPath = "./$($this.TemplateFolder)/$configPath/$($this.Environment)-akamai_tf.log"
    $varFile = $this.GetTfvarsRelPath()

    Initialize-TerraformBackend `
      -TemplateFolder $this.TemplateFolder `
      -ConfigPath $configPath `
      -StateFileName $stateFileName

    if ($debug) {
      Enable-TerraformDebugLogging -LogPath $logPath
    }

    $exitCode = Invoke-TerraformDestroy `
      -TemplateFolder $this.TemplateFolder `
      -VarFilePath $varFile `
      -AutoApprove

    if ($exitCode -ne 0) {
      if ($debug) {
        Write-Host "`nDebug log saved to: $logPath" -ForegroundColor Yellow
        Disable-TerraformDebugLogging
      }
      throw "Terraform destroy failed for DataStream 2"
    }

    if ($debug) {
      Disable-TerraformDebugLogging
    }

    Write-Host "✓ DataStream 2 destruction completed successfully" -ForegroundColor Green
  }
}

function New-DS2Template {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [string]$Environment,

    [Parameter(Mandatory = $true)]
    [string]$TemplateFolder
  )

  return [DS2Template]::new($Environment, $TemplateFolder)
}

function Get-DS2ParamPolicy {
  return @{
    Required      = @("Environment")
    RequiredHints = @{ Environment = "Use: -Env <environment>" }
    Allowed       = @("Environment", "Save", "ActivateProduction", "Destroy", "VersionNotes", "Dry")
    MustHaveOneOf = @("Save", "ActivateProduction", "Destroy")
  }
}

function Invoke-DS2Template {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [string]$TemplateFolder,

    [Parameter(Mandatory = $true)]
    [hashtable]$BoundParams
  )

  $template = New-DS2Template -Environment $BoundParams['Environment'] -TemplateFolder $TemplateFolder

  if ($BoundParams.ContainsKey('Destroy')) {
    $template.Destroy($BoundParams.ContainsKey('Debug'))
  }
  else {
    $template.Deploy(@{
        Save               = $BoundParams.ContainsKey('Save')
        ActivateProduction = $BoundParams.ContainsKey('ActivateProduction')
        Dry                = $BoundParams.ContainsKey('Dry')
        Force              = $BoundParams.ContainsKey('Force')
        Debug              = $BoundParams.ContainsKey('Debug')
      })
  }
}

Export-ModuleMember -Function New-DS2Template, Get-DS2ParamPolicy, Invoke-DS2Template
