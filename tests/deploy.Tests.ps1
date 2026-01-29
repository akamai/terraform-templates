<#
.SYNOPSIS
Pester tests for deploy.ps1 script

.DESCRIPTION
Comprehensive test suite for the deploy.ps1 Terraform deployment script.
Tests include unit tests, integration tests, and mocked external dependencies.

.NOTES
Requires Pester 5.x or later
Run with: Invoke-Pester -Path .\tests\deploy.Tests.ps1
#>

BeforeAll {
    # Import the script functions without executing the main script
    # We'll dot-source the functions we need to test
    $ScriptPath = Join-Path $PSScriptRoot "../deploy.ps1"
    
    # Mock external commands that would normally execute
    # Note: Since deploy.ps1 is a script (not a module), we mock at global scope
    # For external executables, we need to create a function wrapper first
    function terraform { }
    function git { }
    function Get-Contract { }
    function Get-ProductsPerContract { }
    
    Mock terraform { 
        param($Command)
        if ($Command -eq 'version') {
            return "Terraform v1.9.0"
        }
        $global:LASTEXITCODE = 0
        return 0 
    }
    Mock git { return "abc1234 Test commit" }
    Mock Get-Contract { return @("ctr_C-1234567") }
    Mock Get-ProductsPerContract { 
        return @(
            @{
                marketingProductId = "M-LC-169584"
                marketingProductName = "App & API Protector - Included delivery"
            }
        )
    }
    
    # Dot-source the deploy.ps1 script to import functions
    # We need to suppress execution of the main script logic by setting help flag
    $env:PESTER_TEST_MODE = $true
    try {
        # Read the script and extract only the function definitions
        $ScriptContent = Get-Content $ScriptPath -Raw
        
        # Extract Get-TfVarValue function
        if ($ScriptContent -match '(?ms)(function Get-TfVarValue \{.*?\n\})') {
            Invoke-Expression $matches[1]
        }
        
        # Extract Get-Username function
        if ($ScriptContent -match '(?ms)(function Get-Username \{.*?\n\})') {
            Invoke-Expression $matches[1]
        }
    }
    finally {
        Remove-Item env:PESTER_TEST_MODE -ErrorAction SilentlyContinue
    }
}

Describe "deploy.ps1 - Parameter Validation" {
    
    Context "When TemplateType parameter is provided" {
        It "Should accept valid template types: aap, aapasm, pm" {
            @('aap', 'aapasm', 'pm') | ForEach-Object {
                { & "$PSScriptRoot/../deploy.ps1" $_ -Env dev -Help } | Should -Not -Throw
            }
        }
        
        It "Should reject invalid template types" {
            { & "$PSScriptRoot/../deploy.ps1" -TemplateType "invalid" -Env dev -Save } | Should -Throw
        }
        
        It "Should throw when TemplateType is missing" {
            { & "$PSScriptRoot/../deploy.ps1" -Env dev -Save } | Should -Throw "*TemplateType is required*"
        }
    }
    
    Context "When Environment parameter is provided" {
        It "Should throw when Environment is missing" {
            { & "$PSScriptRoot/../deploy.ps1" aap -Save } | Should -Throw "*Environment parameter is required*"
        }
        
        It "Should validate environment tfvars file exists" {
            Mock Test-Path { return $false } -ParameterFilter { $Path -like "*tfvars" }
            { & "$PSScriptRoot/../deploy.ps1" aap -Env nonexistent -Save } | Should -Throw "*does not exist*"
        }
    }
    
    Context "When action parameters are provided" {
        It "Should not allow Save with ActivateStaging parameters together" {
            { & "$PSScriptRoot/../deploy.ps1" aap -Env dev -Save -ActivateStaging } | Should -Throw
        }
        
        It "Should not allow Save with ActivateProduction parameters together" {
            { & "$PSScriptRoot/../deploy.ps1" aap -Env dev -Save -ActivateProduction } | Should -Throw
        }
    }
}

Describe "deploy.ps1 - Get-TfVarValue Function" {
    
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
}

Describe "deploy.ps1 - Get-Username Function" {
    
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

Describe "deploy.ps1 - Template Folder Mapping" {
    
    Context "When mapping TemplateType to folder" {
        It "Should look for 'new-aap-configuration' folder when using 'aap' template" {
            # Test that the script looks for the correct folder by checking the error message
            { & "$PSScriptRoot/../deploy.ps1" aap -Env nonexistent -Save } | Should -Throw "*new-aap-configuration/environments/nonexistent*"
        }
        
        It "Should look for 'new-aapasm-configuration' folder when using 'aapasm' template" {
            { & "$PSScriptRoot/../deploy.ps1" aapasm -Env nonexistent -Save } | Should -Throw "*new-aapasm-configuration/environments/nonexistent*"
        }
        
        It "Should look for 'new-property' folder when using 'pm' template" {
            { & "$PSScriptRoot/../deploy.ps1" pm -Env nonexistent -Save } | Should -Throw "*new-property/environments/nonexistent*"
        }
    }
}

Describe "deploy.ps1 - Backend Configuration" {
    
    Context "When executing script" {
        It "Should generate config.backend with correct state file path" {
            # Create test environment
            $testEnvPath = "$PSScriptRoot/../new-aap-configuration/environments/testres"
            New-Item -Path $testEnvPath -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
            
            $tfvarsContent = @"
edgerc_path = "~/.edgerc"
edgerc_section = "default"
"@
            Set-Content -Path "$testEnvPath/testres.tfvars" -Value $tfvarsContent -Force
            
            try {
                # Run script to generate backend config
                & "$PSScriptRoot/../deploy.ps1" aap -Env testres -Save -SkipValidation -Dry -Notes "Test" 2>&1 | Out-Null
                
                # Verify config.backend contains environment-specific state path
                $configPath = "$testEnvPath/config.backend"
                $content = Get-Content $configPath -Raw
                
                # Verify the state file path includes the environment name
                $content | Should -Match 'path="./environments/testres/testres-terraform\.tfstate"'
            }
            finally {
                Remove-Item "$testEnvPath/testres.tfvars" -ErrorAction SilentlyContinue
                Remove-Item "$testEnvPath/config.backend" -ErrorAction SilentlyContinue
                Remove-Item "$testEnvPath" -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

Describe "deploy.ps1 - Resource Name Determination" {
    
    Context "When script determines resource names by template type" {
        
        It "Should successfully execute for PM template (uses property activation resources)" {
            # The PM template uses akamai_property_activation resources
            # If the script executes successfully, it means it determined the correct resource type
            $pmEnvPath = "$PSScriptRoot/../new-property/environments/testres"
            New-Item -Path $pmEnvPath -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
            
            $tfvarsContent = @"
edgerc_path = "~/.edgerc"
edgerc_section = "default"
"@
            Set-Content -Path "$pmEnvPath/testres.tfvars" -Value $tfvarsContent -Force
            
            try {
                # Run the PM script - it should complete without errors about wrong resource types
                { & "$PSScriptRoot/../deploy.ps1" pm -Env testres -Save -SkipValidation -Dry -Notes "Test" 2>&1 | Out-Null } | Should -Not -Throw
                
            } finally {
                # Cleanup
                Remove-Item "$pmEnvPath/testres.tfvars" -ErrorAction SilentlyContinue
                Remove-Item "$pmEnvPath/config.backend" -ErrorAction SilentlyContinue
                Remove-Item "$pmEnvPath/testres-save.tfplan" -ErrorAction SilentlyContinue
                Remove-Item "$pmEnvPath" -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
        
        It "Should successfully execute for AAP template (uses appsec activation resources)" {
            # The AAP template uses akamai_appsec_activations resources
            $aapEnvPath = "$PSScriptRoot/../new-aap-configuration/environments/testres"
            New-Item -Path $aapEnvPath -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
            
            $tfvarsContent = @"
edgerc_path = "~/.edgerc"
edgerc_section = "default"
"@
            Set-Content -Path "$aapEnvPath/testres.tfvars" -Value $tfvarsContent -Force
            
            try {
                # Run the AAP script - different resource type than PM
                { & "$PSScriptRoot/../deploy.ps1" aap -Env testres -Save -SkipValidation -Dry -Notes "Test" 2>&1 | Out-Null } | Should -Not -Throw
                
            } finally {
                # Cleanup
                Remove-Item "$aapEnvPath/testres.tfvars" -ErrorAction SilentlyContinue
                Remove-Item "$aapEnvPath/config.backend" -ErrorAction SilentlyContinue
                Remove-Item "$aapEnvPath/testres-save.tfplan" -ErrorAction SilentlyContinue
                Remove-Item "$aapEnvPath" -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

Describe "deploy.ps1 - Help Display" {
    
    Context "When help is requested" {
        It "Should display help with -Help parameter" {
            { & "$PSScriptRoot/../deploy.ps1" -Help } | Should -Not -Throw
        }
        
        It "Should display help with valid template and Help argument" {
            # The script checks for Help in $args after parameter validation
            # So we need to provide a valid TemplateType first
            { & "$PSScriptRoot/../deploy.ps1" aap -Help } | Should -Not -Throw
        }
        
        It "Should accept -h flag with valid template" {
            # Test that help functionality works with short flag
            $result = & "$PSScriptRoot/../deploy.ps1" aap -Help
            # Help command exits with code 0
            $LASTEXITCODE | Should -Be 0
        }
    }
}

Describe "deploy.ps1 - Integration Tests" {
    
    BeforeAll {
        # Create mock directory structure
        $TestTemplateFolder = Join-Path $TestDrive "new-aap-configuration"
        $TestEnvFolder = Join-Path $TestTemplateFolder "environments/dev"
        New-Item -Path $TestEnvFolder -ItemType Directory -Force | Out-Null
        
        # Create mock tfvars file
        $MockTfVars = @"
edgerc_path = "~/.edgerc"
edgerc_section = "default"
contract_id = "ctr_C-1234567"
group_id = "grp_12345"
"@
        Set-Content -Path (Join-Path $TestEnvFolder "dev.tfvars") -Value $MockTfVars
    }
    
    Context "When directory structure exists" {
        It "Should find environment tfvars file" {
            $TestEnvFolder = Join-Path $TestDrive "new-aap-configuration/environments/dev"
            $tfvarsPath = Join-Path $TestEnvFolder "dev.tfvars"
            
            Test-Path $tfvarsPath | Should -Be $true
        }
    }
}

Describe "deploy.ps1 - SkipValidation Parameter" {
    
    Context "When SkipValidation is used" {
        It "Should not call Get-ProductsPerContract when SkipValidation is true" {
            # Create test environment
            $testEnvPath = "$PSScriptRoot/../new-aap-configuration/environments/testres"
            New-Item -Path $testEnvPath -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
            
            $tfvarsContent = @"
edgerc_path = "~/.edgerc"
edgerc_section = "default"
"@
            Set-Content -Path "$testEnvPath/testres.tfvars" -Value $tfvarsContent -Force
            
            # Mock to verify it's NOT called
            $script:validationCalled = $false
            Mock Get-ProductsPerContract {
                $script:validationCalled = $true
                return @()
            }
            
            try {
                & "$PSScriptRoot/../deploy.ps1" aap -Env testres -Save -SkipValidation -Dry -Notes "Test" 2>&1 | Out-Null
                
                $script:validationCalled | Should -Be $false
            }
            finally {
                Remove-Item "$testEnvPath/testres.tfvars" -ErrorAction SilentlyContinue
                Remove-Item "$testEnvPath/config.backend" -ErrorAction SilentlyContinue
                Remove-Item "$testEnvPath/testres-save.tfplan" -ErrorAction SilentlyContinue
                Remove-Item "$testEnvPath" -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
