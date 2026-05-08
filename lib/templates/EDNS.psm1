<#
.SYNOPSIS
Akamai Edge DNS (EDNS) template handler

.DESCRIPTION
Handles PRIMARY and SECONDARY Edge DNS zones.
Supports plan, apply and safe destroy workflow.
#>

using module ../core/TerraformRunner.psm1
using module ../core/Logger.psm1

class EDNSTemplate {
  [string]$Environment
  [string]$ZoneType
  [string]$TemplateFolder

  EDNSTemplate(
    [string]$environment,
    [string]$zoneType,
    [string]$templateFolder
  ) {
    $this.Environment = $environment
    $this.ZoneType = $zoneType
    $this.TemplateFolder = $templateFolder
  }
  [string] GetRepoRoot() {
    return (Resolve-Path (Join-Path $PSScriptRoot "../../")).Path
  }
  [string] GetTfvarsPath() {
    $repoRoot = $this.GetRepoRoot()

    $path = Join-Path `
      -Path $repoRoot `
      -ChildPath "$($this.TemplateFolder)/environments/$($this.Environment)/$($this.ZoneType).tfvars"

    if (-not (Test-Path $path)) {
      throw "EDNS tfvars file not found on disk: $path"
    }

    return (Resolve-Path $path).Path
  }
  [void] CleanupTerraformState() {
    Write-Host "Cleaning Terraform state for EDNS zone" -ForegroundColor Yellow

    terraform -chdir="./$($this.TemplateFolder)" state rm `
      'module.edns.akamai_dns_zone.dns_zone' 2>$null

    terraform -chdir="./$($this.TemplateFolder)" state rm `
      'module.edns.akamai_dns_record.ns_records["@"]' 2>$null

    terraform -chdir="./$($this.TemplateFolder)" state rm `
      'module.edns.akamai_dns_record.apex_soa["apex"]' 2>$null
  }

  [void] ValidatePrerequisites() {
    $tfvars = $this.GetTfvarsPath()
    if (-not (Test-Path $tfvars)) {
      throw "EDNS tfvars file not found: $tfvars"
    }
    if ($this.ZoneType -notin @("primary", "secondary")) {
      throw "Invalid ZoneType: $($this.ZoneType)"
    }
  }
  [void] ConfirmDestroy() {
    $zoneName = "$($this.Environment) / $($this.ZoneType)"

    Write-Host ""
    Write-Host "WARNING: You are about to DESTROY an Edge DNS zone!" -ForegroundColor Red
    Write-Host "Zone: $zoneName" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Type YES to confirm destruction:" -ForegroundColor Cyan

    $confirmation = Read-Host

    if ($confirmation -ne "YES") {
      throw "Destroy operation cancelled by user."
    }
  }

  [void] Save([bool]$dryRun, [bool]$force, [bool]$debug) {
    Write-Host "Saving EDNS zone ($($this.ZoneType)) for environment $($this.Environment)" -ForegroundColor Cyan

    $this.ValidatePrerequisites()

    $configPath = "environments/$($this.Environment)"
    $stateFileName = "edns-$($this.ZoneType).tfstate"
    $logPath = "./$($this.TemplateFolder)/$configPath/$($this.Environment)-$($this.ZoneType)-akamai_tf.log"

    $tfvars = $this.GetTfvarsPath()
    $repoRoot = $this.GetRepoRoot()

    # Initialize Terraform (drift check runs automatically when VarFilePath is supplied)
    Initialize-TerraformBackend `
      -TemplateFolder $this.TemplateFolder `
      -ConfigPath $configPath `
      -StateFileName $stateFileName `
      -VarFilePath $tfvars `
      -Force $force

    if ($debug) {
      Enable-TerraformDebugLogging -LogPath $logPath
    }

    $planFile = Join-Path `
      -Path $repoRoot `
      -ChildPath "$($this.TemplateFolder)/environments/$($this.Environment)/$($this.ZoneType).tfplan"

    $exitCode = Invoke-TerraformPlan `
      -Variables @{} `
      -TemplateFolder $this.TemplateFolder `
      -VarFilePath $tfvars `
      -OutFile $planFile

    if ($exitCode -ne 0) {
      if ($debug) {
        Write-Host "`nDebug log saved to: $logPath" -ForegroundColor Yellow
        Disable-TerraformDebugLogging
      }
      throw "Terraform plan failed for EDNS"
    }

    if (-not $dryRun) {
      $exitCode = Invoke-TerraformApply `
        -TemplateFolder $this.TemplateFolder `
        -PlanFile $planFile

      if ($exitCode -ne 0) {
        if ($debug) {
          Write-Host "`nDebug log saved to: $logPath" -ForegroundColor Yellow
          Disable-TerraformDebugLogging
        }
        throw "Terraform apply failed for EDNS"
      }
    }

    if ($debug) {
      Disable-TerraformDebugLogging
    }

    Write-Host "✓ EDNS deployment completed successfully" -ForegroundColor Green
  }

  [void] Deploy([bool]$dryRun, [bool]$force, [bool]$debug) {
    $this.Save($dryRun, $force, $debug)
  }

  [void] Destroy([bool]$debug) {
    Write-Host "Destroying EDNS zone ($($this.ZoneType)) for environment $($this.Environment)" -ForegroundColor Red
    # --- Safety check: does zone exist in Terraform state? ---
    $stateList = terraform -chdir="./$($this.TemplateFolder)" state list 2>$null

    $this.ValidatePrerequisites()

    $this.ConfirmDestroy()

    $configPath = "environments/$($this.Environment)"
    $stateFileName = "edns-$($this.ZoneType).tfstate"
    $logPath = "./$($this.TemplateFolder)/$configPath/$($this.Environment)-$($this.ZoneType)-akamai_tf.log"

    Initialize-TerraformBackend `
      -TemplateFolder $this.TemplateFolder `
      -ConfigPath $configPath `
      -StateFileName $stateFileName

    if ($debug) {
      Enable-TerraformDebugLogging -LogPath $logPath
    }

    $tfvars = $this.GetTfvarsPath()
    $repoRoot = $this.GetRepoRoot()

    Write-Host "Phase 1: Removing DNS records (NS and SOA preserved)" -ForegroundColor Yellow

    # --- Phase 1a: PLAN (force_empty_records) ---
    $planFile = Join-Path `
      -Path $repoRoot `
      -ChildPath "$($this.TemplateFolder)/environments/$($this.Environment)/$($this.ZoneType).destroy.tfplan"

    $exitCode = Invoke-TerraformPlan `
      -Variables @{ force_empty_records = "true" } `
      -TemplateFolder $this.TemplateFolder `
      -VarFilePath $tfvars `
      -OutFile $planFile

    if ($exitCode -ne 0) {
      if ($debug) {
        Write-Host "`nDebug log saved to: $logPath" -ForegroundColor Yellow
        Disable-TerraformDebugLogging
      }
      throw "Phase 1 plan failed: could not generate cleanup plan"
    }

# --- Phase 1b: APPLY plan ---
$exitCode = Invoke-TerraformApply `
  -TemplateFolder $this.TemplateFolder `
  -PlanFile $planFile

if ($exitCode -ne 0) {
  if ($debug) {
    Write-Host "`nDebug log saved to: $logPath" -ForegroundColor Yellow
    Disable-TerraformDebugLogging
  }
  throw "Phase 1 failed: could not remove DNS records"
}

    Write-Host "Phase 2: Detaching NS and SOA from Terraform state" -ForegroundColor Yellow

    terraform -chdir="./$($this.TemplateFolder)" state rm `
      'module.edns.akamai_dns_record.ns_records["@"]' 2>$null

    terraform -chdir="./$($this.TemplateFolder)" state rm `
      'module.edns.akamai_dns_record.apex_soa["apex"]' 2>$null

    Write-Host "Phase 3: Destroying DNS zone" -ForegroundColor Red

    $exitCode = Invoke-TerraformDestroy `
      -Variables @{} `
      -TemplateFolder $this.TemplateFolder `
      -VarFilePath $tfvars `
      -AutoApprove
    if ($exitCode -ne 0) {
      if ($debug) {
        Write-Host "`nDebug log saved to: $logPath" -ForegroundColor Yellow
        Disable-TerraformDebugLogging
      }
      throw "Terraform destroy failed for EDNS"
    }

    if ($debug) {
      Disable-TerraformDebugLogging
    }

    Write-Host "EDNS zone destroyed successfully" -ForegroundColor Green
  }
}

function New-EDNSTemplate {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$Environment,

    [Parameter(Mandatory)]
    [ValidateSet("primary", "secondary")]
    [string]$ZoneType,

    [Parameter(Mandatory)]
    [string]$TemplateFolder
  )

  return [EDNSTemplate]::new($Environment, $ZoneType, $TemplateFolder)
}

Export-ModuleMember -Function New-EDNSTemplate