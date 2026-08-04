# PSM1 Module Anatomy

Full annotated breakdown of a standard template module. Every section is mandatory unless marked **optional**.

---

## File Header

```powershell
<#
.SYNOPSIS
{Short product name} template handler

.DESCRIPTION
Handles deployment, activation, and destruction of {Product} configurations
#>

using module ../core/TerraformRunner.psm1
using module ../core/Validation.psm1
using module ../core/Logger.psm1
```

The three `using module` statements import all core helpers. Do not add extra imports unless the template genuinely needs them.

---

## Class Definition

```powershell
class {Name}Template {
    [string]$Environment
    [string]$TemplateFolder
    [hashtable]$DeployParams

    # ── Constructor ───────────────────────────────────────────────────────────
    {Name}Template([string]$environment, [string]$templateFolder) {
        $this.Environment    = $environment
        $this.TemplateFolder = $templateFolder
        $this.DeployParams   = @{}
    }

    # ── ValidatePrerequisites ─────────────────────────────────────────────────
    # Runs before any Terraform command. At minimum, verify the tfvars file.
    [void] ValidatePrerequisites() {
        Write-Host "Validating {Name} prerequisites..." -ForegroundColor Cyan

        $tfvarsPath = "./$($this.TemplateFolder)/environments/$($this.Environment)/$($this.Environment).tfvars"
        if (-not (Test-Path $tfvarsPath)) {
            throw "Environment file not found: $tfvarsPath"
        }

        # Optional: validate product IDs when SkipValidation is not set.
        if (-not $this.DeployParams.SkipValidation) {
            $expectedProducts = @(
                @{Id = "M-LC-XXXXXX"; Name = "Product display name"}
            )
            Test-AkamaiProductId -TfVarsPath $tfvarsPath -ExpectedProducts $expectedProducts
        }
    }

    # ── BuildTerraformVars ────────────────────────────────────────────────────
    # Returns the hashtable of -var values passed to Invoke-TerraformPlan.
    # Keys must match variable names declared in variables.tf.
    [hashtable] BuildTerraformVars() {
        $username   = Get-Username
        $emailsJson = ConvertTo-Json @("$username@akamai.com") -Compress

        $versionNotes = $this.DeployParams.VersionNotes
        if (-not $versionNotes) {
            $versionNotes = Read-Host "Please enter version/activation notes"
            if (-not $versionNotes) { $versionNotes = "Used Terraform PS Templates" }
        }
        Write-Host "Using version/activation notes: $versionNotes" -ForegroundColor Green

        $vars = @{
            "emails"                = $emailsJson
            "activation_notes"      = $versionNotes
            "version_notes"         = $versionNotes
            "activate_to_staging"   = $this.DeployParams.ActivateStaging   ? "true" : "false"
            "activate_to_production"= $this.DeployParams.ActivateProduction ? "true" : "false"
        }

        # Check existing activation resources (prevents duplicate activation errors).
        $stagingExists = Test-TerraformResourceExists -TemplateFolder $this.TemplateFolder `
                            -ResourceName "akamai_appsec_activations.staging"
        $prodExists    = Test-TerraformResourceExists -TemplateFolder $this.TemplateFolder `
                            -ResourceName "akamai_appsec_activations.production"

        Write-Host "Previous activation to staging found: $stagingExists"   -ForegroundColor Gray
        Write-Host "Previous activation to production found: $prodExists"   -ForegroundColor Gray

        $vars["activation_to_staging_exists"]   = $stagingExists ? "true" : "false"
        $vars["activation_to_production_exists"] = $prodExists    ? "true" : "false"

        return $vars
    }

    # ── HandleApplyFailure [OPTIONAL] ─────────────────────────────────────────
    # Add this method only when the template has a known first-run import quirk
    # (like AAP auto-creating rate policies). Omit entirely otherwise.
    [void] HandleApplyFailure() {
        Write-Host "Handling {Name}-specific failure..." -ForegroundColor Yellow
        # Import logic here — see AAP.psm1 for a complete example.
    }

    # ── Deploy ────────────────────────────────────────────────────────────────
    [void] Deploy([hashtable]$params) {
        $this.DeployParams = $params

        Write-Host "Deploying {Name} configuration for environment: $($this.Environment)" -ForegroundColor Green

        $this.ValidatePrerequisites()

        $configPath    = "environments/$($this.Environment)"
        $stateFileName = "$($this.Environment)-terraform.tfstate"
        $logPath       = "./$($this.TemplateFolder)/$configPath/$($this.Environment)-akamai_tf.log"

        # Init (drift check runs automatically when VarFilePath is supplied).
        Initialize-TerraformBackend `
            -TemplateFolder $this.TemplateFolder `
            -ConfigPath     $configPath `
            -StateFileName  $stateFileName `
            -VarFilePath    "./$configPath/$($this.Environment).tfvars" `
            -Force          $params.Force

        if ($params.Debug) { Enable-TerraformDebugLogging -LogPath $logPath }

        $vars    = $this.BuildTerraformVars()
        $varFile = "./$configPath/$($this.Environment).tfvars"

        # Determine output plan filename.
        $outFileName = if ($params.Save) { "$($this.Environment)-save.tfplan" }
                       elseif ($params.ActivateStaging -and -not $params.ActivateProduction) { "$($this.Environment)-staging.tfplan" }
                       elseif ($params.ActivateProduction -and -not $params.ActivateStaging) { "$($this.Environment)-production.tfplan" }
                       elseif ($params.ActivateStaging -and $params.ActivateProduction)      { "$($this.Environment)-production.tfplan" }
                       else { "$($this.Environment)-default.tfplan" }
        $outFile = "./$configPath/$outFileName"

        $exitCode = Invoke-TerraformPlan -TemplateFolder $this.TemplateFolder `
                        -Variables $vars -VarFilePath $varFile -OutFile $outFile

        if ($exitCode -ne 0) {
            if ($params.Debug) { Write-Host "`nDebug log saved to: $logPath" -ForegroundColor Yellow }
            throw "Terraform plan failed with exit code: $exitCode"
        }

        if (-not $params.Dry) {
            # Basic apply — add retry loop (see AAP.psm1) only if HandleApplyFailure is implemented.
            $exitCode = Invoke-TerraformApply -TemplateFolder $this.TemplateFolder -PlanFile $outFile
            if ($exitCode -eq 0) {
                Write-Host "✓ {Name} deployment completed successfully" -ForegroundColor Green
            }
            else {
                throw "{Name} deployment failed with exit code: $exitCode"
            }
        }

        if ($params.Debug) { Disable-TerraformDebugLogging }
    }

    # ── Destroy ───────────────────────────────────────────────────────────────
    [void] Destroy() {
        Write-Host "Destroying {Name} configuration for environment: $($this.Environment)" -ForegroundColor Red

        Confirm-DestroyOperation -ResourceDescription "{Name} configuration for environment: $($this.Environment)"

        $configPath    = "environments/$($this.Environment)"
        $stateFileName = "$($this.Environment)-terraform.tfstate"

        Initialize-TerraformBackend -TemplateFolder $this.TemplateFolder `
            -ConfigPath $configPath -StateFileName $stateFileName

        $varFile  = "./$configPath/$($this.Environment).tfvars"
        $exitCode = Invoke-TerraformDestroy -TemplateFolder $this.TemplateFolder `
                        -VarFilePath $varFile -NoRefresh

        if ($exitCode -eq 0) {
            Write-Host "✓ {Name} destruction completed successfully" -ForegroundColor Green
        }
        else {
            throw "{Name} destruction failed with exit code: $exitCode"
        }
    }
}
```

---

## Factory Function

```powershell
function New-{Name}Template {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] [string]$Environment,
        [Parameter(Mandatory = $true)] [string]$TemplateFolder
    )
    return [{Name}Template]::new($Environment, $TemplateFolder)
}
```

No logic here — just a constructor wrapper. If the class needs additional constructor args (like CPS needs `$CpsType` and `$CertNumber`), add them to both the `param` block and the `::new(...)` call.

---

## Param Policy Function

```powershell
function Get-{Name}ParamPolicy {
    return @{
        Required      = @("Environment")
        RequiredHints = @{ Environment = "Use: -Env <environment>" }
        Allowed       = @(
            "Environment", "Save", "ActivateStaging", "ActivateProduction",
            "Destroy", "VersionNotes", "SkipValidation", "Dry", "Debug", "Force"
        )
        MustHaveOneOf = @("Save", "ActivateStaging", "ActivateProduction", "Destroy")
    }
}
```

**Rules for `Allowed`:**
- Include every parameter (from `deploy.ps1`'s `Param(...)`) that this template accepts.
- Any bound parameter NOT in this list causes `Assert-TemplateParameters` to reject the call with a clear error message.
- Do **not** list params from other templates (e.g. `SaveApi`, `ZoneType`, `CpsType`) unless this template genuinely uses them.

**Rules for `MustHaveOneOf`:**
- Every template should have at least one action gate.
- Adjust the values if the template uses different action switches than the standard `Save / ActivateStaging / ActivateProduction / Destroy`.

---

## Dispatch Function

```powershell
function Invoke-{Name}Template {
    param(
        [Parameter(Mandatory = $true)] [string]$TemplateFolder,
        [Parameter(Mandatory = $true)] [hashtable]$BoundParams
    )

    $template = New-{Name}Template -Environment $BoundParams['Environment'] -TemplateFolder $TemplateFolder

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
```

This function is called directly by `deploy.ps1` as `& $invokeFnName -TemplateFolder ... -BoundParams $PSBoundParameters`. Its signature is fixed — do not change the parameter names.

---

## Export Statement

```powershell
Export-ModuleMember -Function New-{Name}Template, Get-{Name}ParamPolicy, Invoke-{Name}Template
```

If `Get-{Name}TemplateFolder` is implemented, add it to this list:

```powershell
Export-ModuleMember -Function New-{Name}Template, Get-{Name}ParamPolicy, Invoke-{Name}Template, Get-{Name}TemplateFolder
```

Missing this line means `deploy.ps1` cannot find any of the dispatch functions and will throw at runtime.
