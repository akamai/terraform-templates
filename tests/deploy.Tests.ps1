<#
.SYNOPSIS
Pester tests for modular deployment architecture

.DESCRIPTION
Comprehensive test suite for the refactored deployment system.
Tests core modules (TerraformRunner, Validation, Logger) and template modules.

.NOTES
Requires Pester 5.x or later
Run with: Invoke-Pester -Path .\tests\deploy.Tests.ps1
#>

BeforeAll {
    # Import the modules for testing
    Import-Module "$PSScriptRoot/../lib/core/TerraformRunner.psm1" -Force
    Import-Module "$PSScriptRoot/../lib/core/Validation.psm1" -Force
    Import-Module "$PSScriptRoot/../lib/core/Logger.psm1" -Force
}

Describe "Core Modules - Module Loading" {
    Context "All modules should be available" {
        It "Should have TerraformRunner module" {
            $modulePath = "$PSScriptRoot/../lib/core/TerraformRunner.psm1"
            Test-Path $modulePath | Should -Be $true
        }
        
        It "Should have Validation module" {
            $modulePath = "$PSScriptRoot/../lib/core/Validation.psm1"
            Test-Path $modulePath | Should -Be $true
        }
        
        It "Should have Logger module" {
            $modulePath = "$PSScriptRoot/../lib/core/Logger.psm1"
            Test-Path $modulePath | Should -Be $true
        }
    }
}

Describe "Template Modules - Module Loading" {
    Context "All template modules should be available" {
        It "Should load AAP module" {
            { Import-Module "$PSScriptRoot/../lib/templates/AAP.psm1" -Force } | Should -Not -Throw
        }
        
        It "Should load AAPASM module" {
            { Import-Module "$PSScriptRoot/../lib/templates/AAPASM.psm1" -Force } | Should -Not -Throw
        }
        
        It "Should load PropertyManager module" {
            { Import-Module "$PSScriptRoot/../lib/templates/PropertyManager.psm1" -Force } | Should -Not -Throw
        }
        
        It "Should load CPS module" {
            { Import-Module "$PSScriptRoot/../lib/templates/CPS.psm1" -Force } | Should -Not -Throw
        }
    }
}

Describe "Validation Module - Get-TfVarValue Function" {
    
    BeforeAll {
        # Create a temporary test tfvars file
        $TestTfVarsPath = Join-Path $TestDrive "test.tfvars"
        $TfVarsContent = @"
# Test tfvars file
edgerc_path = "~/.edgerc"
edgerc_section = "default"
property_name = "test-property"
contract_id = "ctr_C-1234567"
group_id = "grp_12345"
product_id = "prd_Site_Accel"
rule_format = "v2023-01-05"
secure_by_default = true
activate_staging = false
activate_production = false
version_notes = "Test deployment"
numeric_value = 12345
"@
        Set-Content -Path $TestTfVarsPath -Value $TfVarsContent
    }
    
    Context "When parsing quoted string values" {
        It "Should extract edgerc_path correctly" {
            $result = Get-TfVarValue -FilePath $TestTfVarsPath -VarName "edgerc_path"
            $result | Should -Be "~/.edgerc"
        }
        
        It "Should extract edgerc_section correctly" {
            $result = Get-TfVarValue -FilePath $TestTfVarsPath -VarName "edgerc_section"
            $result | Should -Be "default"
        }
        
        It "Should extract property_name correctly" {
            $result = Get-TfVarValue -FilePath $TestTfVarsPath -VarName "property_name"
            $result | Should -Be "test-property"
        }
    }
    
    Context "When parsing unquoted values" {
        It "Should extract boolean value" {
            $result = Get-TfVarValue -FilePath $TestTfVarsPath -VarName "secure_by_default"
            $result | Should -Be "true"
        }
        
        It "Should extract numeric value" {
            $result = Get-TfVarValue -FilePath $TestTfVarsPath -VarName "numeric_value"
            $result | Should -Be "12345"
        }
    }
    
    Context "When variable does not exist" {
        It "Should return null for non-existent variable" {
            $result = Get-TfVarValue -FilePath $TestTfVarsPath -VarName "nonexistent_var"
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context "When file does not exist" {
        It "Should throw error for missing file" {
            { Get-TfVarValue -FilePath "/nonexistent/file.tfvars" -VarName "test" } | Should -Throw
        }
    }
}

Describe "Logger Module - Get-Username Function" {
    
    Context "When running on different platforms" {
        It "Should return current username" {
            $result = Get-Username
            $result | Should -Not -BeNullOrEmpty
        }
        
        It "Should return USERNAME on Windows" {
            if ($PSVersionTable.Platform -eq 'Win32NT' -or -not $PSVersionTable.Platform) {
                $result = Get-Username
                $result | Should -Be $env:USERNAME
            }
        }
        
        It "Should return USER on Unix/Linux/macOS" {
            if ($PSVersionTable.Platform -eq 'Unix') {
                $result = Get-Username
                $result | Should -Be $env:USER
            }
        }
    }
}
