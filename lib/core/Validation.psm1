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

Export-ModuleMember -Function Get-TfVarValue, Test-AkamaiProductId
