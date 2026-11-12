<#
.SYNOPSIS
Core credentials-check capability

.DESCRIPTION
Reads the access levels actually granted to the API client behind the current credentials
(Get-IAMAPIClient -ClientID self -APIAccess) and reports whether it has the permissions this
project needs (see README.md "Akamai API Configuration" section). Most APIs strictly require
READ-WRITE; Contracts and API Client Administration accept READ-ONLY or READ-WRITE.
Get-IAMAllowedAPIs (for the given username) is used for hints and catalog validation.

This is a standalone CLI capability (-CredentialsCheck), not tied to any TemplateType.
#>

# Matched by exact endPoint string equality against Get-IAMAllowedAPIs / Get-IAMAPIClient output - avoids apiName
# unicode/dash quirks and avoids collisions with unrelated sub-endpoints (e.g. DataStream's
# EDNS-specific log endpoint vs the base Datastream Config endpoint).
$script:ReadWriteOnly       = @("READ-WRITE")
$script:ReadOnlyOrReadWrite = @("READ-ONLY", "READ-WRITE")

# AllowedLevels is the set of access levels actually GRANTED to the API client that satisfy the
# requirement. Entries limited to READ-WRITE are strict: a READ-ONLY grant is a FAIL.
$script:RequiredApiPolicy = @(
    @{ Label = "Property Manager (PAPI)";   EndPoint = "/papi";                      AllowedLevels = $script:ReadWriteOnly;  Covers = "pm" }
    @{ Label = "Edge Hostnames API (hapi)"; EndPoint = "/hapi";                      AllowedLevels = $script:ReadWriteOnly;  Covers = "pm" }
    @{ Label = "Application Security";      EndPoint = "/appsec";                    AllowedLevels = $script:ReadWriteOnly;  Covers = "aap, aapasm, bmp (Bot Manager shares this API)" }
    @{ Label = "API Definition";            EndPoint = "/api-definitions";            AllowedLevels = $script:ReadWriteOnly; Covers = "bmp" }
    @{ Label = "Client List";               EndPoint = "/client-list";               AllowedLevels = $script:ReadWriteOnly;  Covers = "aap, aapasm (client lists)" }
    @{ Label = "CPS";                       EndPoint = "/cps";                       AllowedLevels = $script:ReadWriteOnly;  Covers = "cps" }
    @{ Label = "DNS—Zone Record Management"; EndPoint = "/config-dns";               AllowedLevels = $script:ReadWriteOnly;  Covers = "edns" }
    @{ Label = "Datastream Config";         EndPoint = "/datastream-config-api/";    AllowedLevels = $script:ReadWriteOnly;  Covers = "ds2" }
    @{ Label = "Domain Ownership Manager";  EndPoint = "/domain-validation/*";       AllowedLevels = $script:ReadWriteOnly;  Covers = "dom" }
    @{ Label = "Contracts-API_Contracts";   EndPoint = "/contract-api/v1/contracts"; AllowedLevels = $script:ReadOnlyOrReadWrite; Covers = "product entitlement validation (all templates)" }
    @{ Label = "API Client Administration"; EndPoint = "/identity-management/v*"; AllowedLevels = $script:ReadOnlyOrReadWrite; Covers = "API credentials access level" }
)

function Test-RequiredApiAccess {
    <#
    .SYNOPSIS
    Evaluates one required-API policy entry against the access level actually granted to the API
    client (Get-IAMAPIClient -ClientID self -APIAccess).

    .NOTES
    Get-IAMAllowedAPIs' accessLevels lists the levels the user is ALLOWED to grant (typically
    both READ-ONLY and READ-WRITE), not what the client has - so it is only used for hints and as
    a fallback when the client is configured with allAccessibleApis.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$PolicyEntry,

        [Parameter(Mandatory = $true)]
        [hashtable]$ApisByEndpoint,

        [Parameter(Mandatory = $true)]
        [hashtable]$GrantedByEndpoint,

        [Parameter(Mandatory = $false)]
        [bool]$AllAccessibleApis = $false
    )

    $allowedApi    = $ApisByEndpoint[$PolicyEntry.EndPoint]
    $grantableRW   = $allowedApi -and (@($allowedApi.accessLevels) -contains "READ-WRITE")
    $requiredText  = $PolicyEntry.AllowedLevels -join " or "

    if ($AllAccessibleApis) {
        # Client inherits every API the user can access, at the user's level.
        if (-not $allowedApi) {
            return @{ Status = "MISSING"; AccessLevel = ""; Hint = "Endpoint not found in Get-IAMAllowedAPIs output - the API catalog may have changed." }
        }
        if (-not $allowedApi.hasAccess) {
            return @{ Status = "FAIL"; AccessLevel = ""; Hint = "User has no access to '$($PolicyEntry.Label)'. Ask an administrator to grant it to your user role." }
        }
        $granted = if ($grantableRW) { "READ-WRITE" } else { "READ-ONLY" }
    }
    else {
        $granted = $GrantedByEndpoint[$PolicyEntry.EndPoint]
        if (-not $granted) {
            if (-not $allowedApi) {
                return @{ Status = "MISSING"; AccessLevel = ""; Hint = "Endpoint not found in Get-IAMAllowedAPIs output - the API catalog may have changed." }
            }
            return @{ Status = "FAIL"; AccessLevel = "NONE"; Hint = "Not granted. Add '$($PolicyEntry.Label)' ($requiredText) to your API client in Identity & Access Management." }
        }
    }

    if ($PolicyEntry.AllowedLevels -notcontains $granted) {
        $hint = if ($grantableRW) {
            "Granted $granted, requires $requiredText. Upgrade '$($PolicyEntry.Label)' to READ-WRITE on your API client in Identity & Access Management."
        }
        else {
            "Granted $granted, requires $requiredText. Your user cannot grant READ-WRITE for '$($PolicyEntry.Label)' - ask an administrator to update your role."
        }
        return @{ Status = "FAIL"; AccessLevel = $granted; Hint = $hint }
    }

    return @{ Status = "PASS"; AccessLevel = $granted; Hint = "" }
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

    if (@(Get-Command Get-IAMAllowedAPIs, Get-IAMAPIClient -ErrorAction SilentlyContinue).Count -ne 2) {
        throw "Get-IAMAllowedAPIs / Get-IAMAPIClient cmdlets not found. Ensure the Akamai PowerShell module (>= 3.0.0) is installed and imported."
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

    # Access levels actually granted to the API client behind these credentials.
    $clientArgs = @{ ClientID = 'self'; APIAccess = $true }
    if ($EdgeRCFile) { $clientArgs['EdgeRCFile'] = $EdgeRCFile }
    if ($Section) { $clientArgs['Section'] = $Section }
    $apiClient = Get-IAMAPIClient @clientArgs

    $allAccessibleApis = [bool]$apiClient.apiAccess.allAccessibleApis
    $grantedByEndpoint = @{}
    foreach ($api in @($apiClient.apiAccess.apis)) {
        if ($api.endPoint) { $grantedByEndpoint[$api.endPoint] = $api.accessLevel }
    }

    $results = foreach ($policyEntry in $script:RequiredApiPolicy) {
        $eval = Test-RequiredApiAccess -PolicyEntry $policyEntry -ApisByEndpoint $apisByEndpoint `
            -GrantedByEndpoint $grantedByEndpoint -AllAccessibleApis $allAccessibleApis
        [PSCustomObject]@{
            Capability  = $policyEntry.Label
            EndPoint    = $policyEntry.EndPoint
            Required    = $policyEntry.AllowedLevels -join " | "
            AccessLevel = $eval.AccessLevel
            Status      = $eval.Status
            Hint        = $eval.Hint
        }
    }

    $capWidth = ($results | ForEach-Object { $_.Capability.Length } | Measure-Object -Maximum).Maximum
    $epWidth  = ($results | ForEach-Object { $_.EndPoint.Length } | Measure-Object -Maximum).Maximum
    $rqWidth  = [Math]::Max(8, ($results | ForEach-Object { $_.Required.Length } | Measure-Object -Maximum).Maximum)
    $alWidth  = [Math]::Max(7, ($results | ForEach-Object { $_.AccessLevel.Length } | Measure-Object -Maximum).Maximum)

    Write-Host ""
    Write-Host "================================" -ForegroundColor Green
    Write-Host "Credentials Check - $Username" -ForegroundColor Green
    Write-Host "================================" -ForegroundColor Green

    $header = "{0,-$capWidth}  {1,-$epWidth}  {2,-$rqWidth}  {3,-$alWidth}  {4}" -f "Capability", "Endpoint", "Required", "Granted", "Status"
    Write-Host $header -ForegroundColor Cyan
    Write-Host ("-" * $header.Length) -ForegroundColor DarkGray

    foreach ($result in $results) {
        $color = switch ($result.Status) {
            "PASS"  { "Green" }
            "FAIL"  { "Red" }
            default { "Yellow" }
        }
        $line = "{0,-$capWidth}  {1,-$epWidth}  {2,-$rqWidth}  {3,-$alWidth}  {4}" -f $result.Capability, $result.EndPoint, $result.Required, $result.AccessLevel, $result.Status
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
