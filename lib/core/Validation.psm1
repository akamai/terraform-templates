<#
.SYNOPSIS
Validation functions for Terraform templates

.DESCRIPTION
Provides product ID validation and other prerequisite checks
#>

function Get-TfVarValue {
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
    
    # Pattern to match both quoted and unquoted values
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

function Test-AkamaiProductId {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TfVarsPath,
        
        [Parameter(Mandatory = $true)]
        [array]$ExpectedProducts
    )
    
    Write-Host "Validating Akamai product ID..." -ForegroundColor Cyan
    
    # Extract edgerc values from tfvars
    $edgercPath = Get-TfVarValue -FilePath $TfVarsPath -VarName "edgerc_path"
    $edgercSection = Get-TfVarValue -FilePath $TfVarsPath -VarName "edgerc_section"
    
    if (-not $edgercPath -or -not $edgercSection) {
        throw "Missing edgerc_path or edgerc_section in tfvars file"
    }
    
    Write-Host "Using EdgeRC: $edgercPath, Section: $edgercSection" -ForegroundColor Gray
    
    # Get contracts
    try {
        $contracts = Get-Contract -Section $edgercSection -EdgeRCFile $edgercPath -Depth TOP
        
        if (-not $contracts -or $contracts.Count -eq 0) {
            throw "No contracts found for section: $edgercSection"
        }
        
        Write-Host "Found $($contracts.Count) contract(s)" -ForegroundColor Gray
        
        $foundValidProduct = $false
        
        # Check products for each contract
        foreach ($contractId in $contracts) {
            Write-Host "Checking products for contract: $contractId" -ForegroundColor Gray
            
            if ([string]::IsNullOrWhiteSpace($contractId)) {
                continue
            }
            
            try {
                $products = Get-ProductsPerContract -ContractID $contractId -Section $edgercSection -EdgeRCFile $edgercPath
                
                if ($products) {
                    foreach ($product in $products) {
                        $productId = $product.marketingProductId
                        $productName = $product.marketingProductName
                        
                        if ($productId) {
                            Write-Host "  - $productId ($productName)" -ForegroundColor Gray
                            
                            $matchedProduct = $ExpectedProducts | Where-Object { $_.Id -eq $productId }
                            if ($matchedProduct) {
                                Write-Host "✓ Valid product ID found: $productId" -ForegroundColor Green
                                $foundValidProduct = $true
                                break
                            }
                        }
                    }
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
            $expectedList = ($ExpectedProducts | ForEach-Object { "$($_.Id) ($($_.Name))" }) -join ", "
            throw "Product validation failed. Expected one of: $expectedList"
        }
        
        return $true
    }
    catch {
        Write-Error "Product validation failed: $_"
        throw
    }
}


# Parameters always allowed for every template type.
# 'Debug' is a PowerShell common parameter that may appear in $PSBoundParameters.
$script:GlobalAllowedParams = @("TemplateType", "Help", "Force", "Debug")

function Assert-TemplateParameters {
    <#
    .SYNOPSIS
    Validates that $PSBoundParameters contains only parameters declared as allowed
    by the template's policy, that all required parameters are present, and that
    at least one action parameter is provided when the policy requires it.

    .DESCRIPTION
    Called from deploy.ps1 after importing a template module. The template module
    must export a Get-<Name>ParamPolicy function that returns a hashtable with:

        Required      - [string[]] Parameters that must be present. Optional.
        RequiredHints - [hashtable] Per-parameter hint appended to the Required error. Optional.
        Allowed       - [string[]] Template-specific parameters that are permitted.
                        The global params (TemplateType, Help, Force, Debug) are always
                        added automatically.
        MustHaveOneOf - [string[]] At least one of these must be present. Optional.

    .PARAMETER TemplateType
    The template type string (e.g. 'aap', 'cps'). Used in error messages.

    .PARAMETER Policy
    Hashtable returned by the template's Get-<Name>ParamPolicy function.

    .PARAMETER BoundParams
    Pass $PSBoundParameters from deploy.ps1.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TemplateType,

        [Parameter(Mandatory = $true)]
        [hashtable]$Policy,

        [Parameter(Mandatory = $true)]
        [hashtable]$BoundParams
    )

    $allAllowed = @($Policy.Allowed) + $script:GlobalAllowedParams

    # 1. Required parameters
    if ($Policy.Required) {
        foreach ($param in $Policy.Required) {
            if (-not $BoundParams.ContainsKey($param)) {
                $hint = if ($Policy.RequiredHints -and $Policy.RequiredHints[$param]) {
                    " $($Policy.RequiredHints[$param])"
                }
                else { "" }
                throw "$param parameter required for '$TemplateType' template.$hint"
            }
        }
    }

    # 2. Forbidden parameters — report the first offender with the full allowed list
    $forbidden = @($BoundParams.Keys | Where-Object { $_ -notin $allAllowed })
    if ($forbidden.Count -gt 0) {
        $allowedDisplay = ($Policy.Allowed | Sort-Object | ForEach-Object { "-$_" }) -join ", "
        throw "Parameter '-$($forbidden[0])' is not applicable for the '$TemplateType' template. " +
              "Allowed parameters: $allowedDisplay"
    }

    # 3. At least one action required
    if ($Policy.MustHaveOneOf) {
        $present = @($Policy.MustHaveOneOf | Where-Object { $BoundParams.ContainsKey($_) })
        if ($present.Count -eq 0) {
            $paramList = ($Policy.MustHaveOneOf | ForEach-Object { "-$_" }) -join ", "
            throw "Please specify at least one parameter: $paramList"
        }
    }
}

Export-ModuleMember -Function Get-TfVarValue, Test-AkamaiProductId, Assert-TemplateParameters
