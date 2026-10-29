<#
.SYNOPSIS
Core credentials-check capability

.DESCRIPTION
Calls Get-IAMAllowedAPIs for a given Akamai Identity & Access Management username and reports
whether the API client has the permissions this project needs (see README.md "Akamai API
Configuration" section), including whether each one requires READ-WRITE access vs READ-ONLY.

This is a standalone CLI capability (-CredentialsCheck), not tied to any TemplateType.
#>

# Matched by exact endPoint string equality against Get-IAMAllowedAPIs output - avoids apiName
# unicode/dash quirks and avoids collisions with unrelated sub-endpoints (e.g. DataStream's
# EDNS-specific log endpoint vs the base Datastream Config endpoint).
$script:RequiredApiPolicy = @(
    @{ Label = "Property Manager (PAPI)";   EndPoint = "/papi";                      RequireReadWrite = $true;  Covers = "pm" }
    @{ Label = "Edge Hostnames API (hapi)"; EndPoint = "/hapi";                      RequireReadWrite = $true;  Covers = "pm" }
    @{ Label = "Application Security";      EndPoint = "/appsec";                    RequireReadWrite = $true;  Covers = "aap, aapasm, bmp (Bot Manager shares this API)" }
    @{ Label = "API Definition";            EndPoint = "/api-definitions";            RequireReadWrite = $true; Covers = "bmp" }
    @{ Label = "Client List";               EndPoint = "/client-list";               RequireReadWrite = $true;  Covers = "aap, aapasm (client lists)" }
    @{ Label = "CPS";                       EndPoint = "/cps";                       RequireReadWrite = $true;  Covers = "cps" }
    @{ Label = "DNS—Zone Record Management"; EndPoint = "/config-dns";               RequireReadWrite = $true;  Covers = "edns" }
    @{ Label = "Datastream Config";         EndPoint = "/datastream-config-api/";    RequireReadWrite = $true;  Covers = "ds2" }
    @{ Label = "Domain Ownership Manager";  EndPoint = "/domain-validation/*";       RequireReadWrite = $true;  Covers = "dom" }
    @{ Label = "Contracts-API_Contracts";   EndPoint = "/contract-api/v1/contracts"; RequireReadWrite = $false; Covers = "product entitlement validation (all templates)" }
    @{ Label = "API Client Administration"; EndPoint = "/identity-management/v*"; RequireReadWrite = $false; Covers = "API credentials access level" }
)

function Test-RequiredApiAccess {
    <#
    .SYNOPSIS
    Evaluates one required-API policy entry against the live Get-IAMAllowedAPIs result set.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$PolicyEntry,

        [Parameter(Mandatory = $true)]
        [hashtable]$ApisByEndpoint
    )

    $api = $ApisByEndpoint[$PolicyEntry.EndPoint]

    if (-not $api) {
        return @{
            Status       = "MISSING"
            AccessLevels = ""
            Hint         = "Endpoint not found in Get-IAMAllowedAPIs output - the API catalog may have changed."
        }
    }

    $accessLevels = @($api.accessLevels) -join ", "

    if (-not $api.hasAccess) {
        return @{
            Status       = "FAIL"
            AccessLevels = $accessLevels
            Hint         = "No access. Add '$($PolicyEntry.Label)' to your API client in Identity & Access Management."
        }
    }

    if ($PolicyEntry.RequireReadWrite -and ($api.accessLevels -notcontains "READ-WRITE")) {
        return @{
            Status       = "FAIL"
            AccessLevels = $accessLevels
            Hint         = "Only $accessLevels access. Upgrade '$($PolicyEntry.Label)' to READ-WRITE in Identity & Access Management."
        }
    }

    return @{ Status = "PASS"; AccessLevels = $accessLevels; Hint = "" }
}

function Invoke-CredentialsCheck {
    <#
    .SYNOPSIS
    Core entry point for deploy.ps1 -CredentialsCheck.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Username,

        [Parameter(Mandatory = $false)]
        [ValidateSet('CLIENT', 'USER_CLIENT', 'SERVICE_ACCOUNT')]
        [string]$ClientType = 'USER_CLIENT',

        [Parameter(Mandatory = $false)]
        [string]$EdgeRCFile,

        [Parameter(Mandatory = $false)]
        [string]$Section
    )

    if (-not (Get-Command Get-IAMAllowedAPIs -ErrorAction SilentlyContinue)) {
        throw "Get-IAMAllowedAPIs cmdlet not found. Ensure the Akamai PowerShell module (>= 3.0.0) is installed and imported."
    }

    Write-Host "Checking API client permissions for '$Username'..." -ForegroundColor Cyan

    $getArgs = @{ Username = $Username; ClientType = $ClientType }
    if ($EdgeRCFile) { $getArgs['EdgeRCFile'] = $EdgeRCFile }
    if ($Section) { $getArgs['Section'] = $Section }
    $allowedApis = Get-IAMAllowedAPIs @getArgs

    $apisByEndpoint = @{}
    foreach ($api in $allowedApis) {
        $apisByEndpoint[$api.endPoint] = $api
    }

    $results = foreach ($policyEntry in $script:RequiredApiPolicy) {
        $eval = Test-RequiredApiAccess -PolicyEntry $policyEntry -ApisByEndpoint $apisByEndpoint
        [PSCustomObject]@{
            Capability   = $policyEntry.Label
            EndPoint     = $policyEntry.EndPoint
            AccessLevels = $eval.AccessLevels
            Status       = $eval.Status
            Hint         = $eval.Hint
        }
    }

    $capWidth = ($results | ForEach-Object { $_.Capability.Length } | Measure-Object -Maximum).Maximum
    $epWidth  = ($results | ForEach-Object { $_.EndPoint.Length } | Measure-Object -Maximum).Maximum
    $alWidth  = [Math]::Max(13, ($results | ForEach-Object { $_.AccessLevels.Length } | Measure-Object -Maximum).Maximum)

    Write-Host ""
    Write-Host "================================" -ForegroundColor Green
    Write-Host "Credentials Check - $Username" -ForegroundColor Green
    Write-Host "================================" -ForegroundColor Green

    $header = "{0,-$capWidth}  {1,-$epWidth}  {2,-$alWidth}  {3}" -f "Capability", "Endpoint", "Access Levels", "Status"
    Write-Host $header -ForegroundColor Cyan
    Write-Host ("-" * $header.Length) -ForegroundColor DarkGray

    foreach ($result in $results) {
        $color = switch ($result.Status) {
            "PASS"  { "Green" }
            "FAIL"  { "Red" }
            default { "Yellow" }
        }
        $line = "{0,-$capWidth}  {1,-$epWidth}  {2,-$alWidth}  {3}" -f $result.Capability, $result.EndPoint, $result.AccessLevels, $result.Status
        Write-Host $line -ForegroundColor $color
    }

    $passCount = ($results | Where-Object { $_.Status -eq "PASS" }).Count
    $total     = $results.Count

    Write-Host ""
    $summaryColor = if ($passCount -eq $total) { "Green" } else { "Yellow" }
    Write-Host "$passCount/$total required permissions satisfied." -ForegroundColor $summaryColor

    $failures = $results | Where-Object { $_.Status -ne "PASS" }
    if ($failures) {
        Write-Host ""
        Write-Host "Action needed:" -ForegroundColor Yellow
        foreach ($failure in $failures) {
            Write-Host "  - $($failure.Capability) ($($failure.EndPoint)): $($failure.Hint)" -ForegroundColor Yellow
        }
    }

    Write-Host ""
}

Export-ModuleMember -Function Invoke-CredentialsCheck
