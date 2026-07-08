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

    # Path used by CLI parameter-validation tests
    $Script:DeployScript = Join-Path $PSScriptRoot "../deploy.ps1"
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

        It "Should load BMP module" {
            { Import-Module "$PSScriptRoot/../lib/templates/BMP.psm1" -Force } | Should -Not -Throw
        }
        
        It "Should load CPS module" {
            { Import-Module "$PSScriptRoot/../lib/templates/CPS.psm1" -Force } | Should -Not -Throw
        }
        
        It "Should load EDNS module" {
            { Import-Module "$PSScriptRoot/../lib/templates/EDNS.psm1" -Force } | Should -Not -Throw
        }
        
        It "Should load PropertyManager module" {
            { Import-Module "$PSScriptRoot/../lib/templates/PropertyManager.psm1" -Force } | Should -Not -Throw
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

Describe "deploy.ps1 - CLI Parameter Validation" {

    BeforeAll {
        # Invoke deploy.ps1 in a child process and return captured output + exit code.
        # 2>&1 merges stderr (Write-Error, parameter-set errors) into the output stream.
        function Invoke-Deploy {
            param([string[]]$Arguments)
            $output = & pwsh -NonInteractive -File $Script:DeployScript @Arguments 2>&1
            return @{
                Output   = ($output | Out-String)
                ExitCode = $LASTEXITCODE
            }
        }
    }

    Context "AAP (aap) parameter validation" {
        It "Should fail without -Env parameter" {
            $r = Invoke-Deploy @("aap")
            $r.ExitCode | Should -Not -Be 0
            $r.Output | Should -Match "Environment parameter required"
        }

        It "Should fail without an action parameter" {
            $r = Invoke-Deploy @("aap", "-Env", "dev")
            $r.ExitCode | Should -Not -Be 0
            $r.Output | Should -Match "Please specify at least one parameter"
        }

        It "Should fail when -Save and -ActivateStaging are combined" {
            $r = Invoke-Deploy @("aap", "-Env", "dev", "-Save", "-ActivateStaging")
            $r.ExitCode | Should -Not -Be 0
            $r.Output | Should -Match "One or more parameters issued cannot be used together"
        }

        It "Should fail when -Save and -ActivateProduction are combined" {
            $r = Invoke-Deploy @("aap", "-Env", "dev", "-Save", "-ActivateProduction")
            $r.ExitCode | Should -Not -Be 0
            $r.Output | Should -Match "One or more parameters issued cannot be used together"
        }

        It "Should fail when -Destroy is combined with other parameters" {
            $r = Invoke-Deploy @("aap", "-Env", "dev", "-Destroy", "-ActivateProduction")
            $r.ExitCode | Should -Not -Be 0
            $r.Output | Should -Match "One or more parameters issued cannot be used together"
        }

        It "Should fail when CPS parameters are passed" {
            $r = Invoke-Deploy @("aap", "-Env", "dev", "-Save", "-CpsType", "dv-san-cert")
            $r.ExitCode | Should -Not -Be 0
            $r.Output | Should -Match "CPS parameters not applicable"
        }
        

        # TEST CURRENTLY FAILS. ONCE THE SCRIPT IS UPDATED WITH CLI OPTIONS FRAMEWORK, UNCOMMENT THE TEST CASE BELOW
        # It "Should fail when EDNS parameters are passed" {
        #     $r = Invoke-Deploy @("aap", "-Env", "dev", "-Save", "-ZoneType", "primary")
        #     $r.ExitCode | Should -Not -Be 0
        #     $r.Output | Should -Match "EDNS parameters not applicable"
        # }

        # TEST CURRENTLY FAILS. ONCE THE SCRIPT IS UPDATED WITH CLI OPTIONS FRAMEWORK, UNCOMMENT THE TEST CASE BELOW
        # It "Should fail when BMP parameters are passed" {
        #     $r = Invoke-Deploy @("aap", "-Env", "dev", "-Save", "-SaveApi")
        #     $r.ExitCode | Should -Not -Be 0
        #     $r.Output | Should -Match "BMP parameters not applicable"
        # }
    }

    Context "AAP+ASM (aapasm) parameter validation" {
        It "Should fail without -Env parameter" {
            $r = Invoke-Deploy @("aapasm")
            $r.ExitCode | Should -Not -Be 0
            $r.Output | Should -Match "Environment parameter required"
        }

        It "Should fail without an action parameter" {
            $r = Invoke-Deploy @("aapasm", "-Env", "dev")
            $r.ExitCode | Should -Not -Be 0
            $r.Output | Should -Match "Please specify at least one parameter"
        }

        It "Should fail when -Save and -ActivateStaging are combined" {
            $r = Invoke-Deploy @("aapasm", "-Env", "dev", "-Save", "-ActivateStaging")
            $r.ExitCode | Should -Not -Be 0
            $r.Output | Should -Match "One or more parameters issued cannot be used together"
        }

        It "Should fail when -Save and -ActivateProduction are combined" {
            $r = Invoke-Deploy @("aapasm", "-Env", "dev", "-Save", "-ActivateProduction")
            $r.ExitCode | Should -Not -Be 0
            $r.Output | Should -Match "One or more parameters issued cannot be used together"
        }

        It "Should fail when CPS parameters are passed" {
            $r = Invoke-Deploy @("aapasm", "-Env", "dev", "-Save", "-CpsType", "dv-san-cert")
            $r.ExitCode | Should -Not -Be 0
            $r.Output | Should -Match "CPS parameters not applicable"
        }
        # TEST CURRENTLY FAILS. ONCE THE SCRIPT IS UPDATED WITH CLI OPTIONS FRAMEWORK, UNCOMMENT THE TEST CASE BELOW
        # It "Should fail when EDNS parameters are passed" {
        #     $r = Invoke-Deploy @("aapasm", "-Env", "dev", "-Save", "-ZoneType", "primary")
        #     $r.ExitCode | Should -Not -Be 0
        #     $r.Output | Should -Match "EDNS parameters not applicable"
        # }
        # TEST CURRENTLY FAILS. ONCE THE SCRIPT IS UPDATED WITH CLI OPTIONS FRAMEWORK, UNCOMMENT THE TEST CASE BELOW
        # It "Should fail when BMP parameters are passed" {
        #     $r = Invoke-Deploy @("aapasm", "-Env", "dev", "-Save", "-SaveApi")
        #     $r.ExitCode | Should -Not -Be 0
        #     $r.Output | Should -Match "BMP parameters not applicable"
        # }
    }

    Context "Property Manager (pm) parameter validation" {
        It "Should fail without -Env parameter" {
            $r = Invoke-Deploy @("pm")
            $r.ExitCode | Should -Not -Be 0
            $r.Output | Should -Match "Environment parameter required"
        }

        It "Should fail without an action parameter" {
            $r = Invoke-Deploy @("pm", "-Env", "dev")
            $r.ExitCode | Should -Not -Be 0
            $r.Output | Should -Match "Please specify at least one parameter"
        }

        It "Should fail when -Save and -ActivateStaging are combined" {
            $r = Invoke-Deploy @("pm", "-Env", "dev", "-Save", "-ActivateStaging")
            $r.ExitCode | Should -Not -Be 0
            $r.Output | Should -Match "One or more parameters issued cannot be used together"
        }

        It "Should fail when -Save and -ActivateProduction are combined" {
            $r = Invoke-Deploy @("pm", "-Env", "dev", "-Save", "-ActivateProduction")
            $r.ExitCode | Should -Not -Be 0
            $r.Output | Should -Match "One or more parameters issued cannot be used together"
        }

        It "Should fail when CPS parameters are passed" {
            $r = Invoke-Deploy @("pm", "-Env", "dev", "-Save", "-CpsType", "dv-san-cert")
            $r.ExitCode | Should -Not -Be 0
            $r.Output | Should -Match "CPS parameters not applicable"
        }
        # TEST CURRENTLY FAILS. ONCE THE SCRIPT IS UPDATED WITH CLI OPTIONS FRAMEWORK, UNCOMMENT THE TEST CASE BELOW
        # It "Should fail when EDNS parameters are passed" {
        #     $r = Invoke-Deploy @("pm", "-Env", "dev", "-Save", "-ZoneType", "primary)
        #     $r.ExitCode | Should -Not -Be 0
        #     $r.Output | Should -Match "EDNS parameters not applicable"
        # }
        # TEST CURRENTLY FAILS. ONCE THE SCRIPT IS UPDATED WITH CLI OPTIONS FRAMEWORK, UNCOMMENT THE TEST CASE BELOW
        # It "Should fail when BMP parameters are passed" {
        #     $r = Invoke-Deploy @("pm", "-Env", "dev", "-Save", "-SaveApi")
        #     $r.ExitCode | Should -Not -Be 0
        #     $r.Output | Should -Match "BMP parameters not applicable"
        # }
    }

    Context "BMP (bmp) parameter validation" {
        It "Should fail without -Env parameter" {
            $r = Invoke-Deploy @("bmp")
            $r.ExitCode | Should -Not -Be 0
            $r.Output | Should -Match "Environment parameter required"
        }

        It "Should fail without an action parameter" {
            $r = Invoke-Deploy @("bmp", "-Env", "dev")
            $r.ExitCode | Should -Not -Be 0
            $r.Output | Should -Match "Please specify at least one parameter"
        }

        It "Should NOT fail when -Save alone is passed" {
            $r = Invoke-Deploy @("bmp", "-Env", "dev", "-Save")
            $r.ExitCode | Should -Be 0
        }

        It "Should fail when -Save and -ActivateStaging are combined" {
            $r = Invoke-Deploy @("bmp", "-Env", "dev", "-Save", "-ActivateStaging")
            $r.ExitCode | Should -Not -Be 0
            $r.Output | Should -Match "One or more parameters issued cannot be used together"
        }

        It "Should fail when -Save and -ActivateProduction are combined" {
            $r = Invoke-Deploy @("bmp", "-Env", "dev", "-Save", "-ActivateProduction")
            $r.ExitCode | Should -Not -Be 0
            $r.Output | Should -Match "One or more parameters issued cannot be used together"
        }

        It "Should fail when -SaveApi and -ActivateStagingApi are combined" {
            $r = Invoke-Deploy @("bmp", "-Env", "dev", "-SaveApi", "-ActivateStagingApi")
            $r.ExitCode | Should -Not -Be 0
            $r.Output | Should -Match "One or more parameters issued cannot be used together"
        }

        It "Should fail when -SaveApi and -SaveSec are combined" {
            $r = Invoke-Deploy @("bmp", "-Env", "dev", "-SaveApi", "-SaveSec")
            $r.ExitCode | Should -Not -Be 0
            $r.Output | Should -Match "One or more parameters issued cannot be used together"
        }

        It "Should fail when -SaveSec and -ActivateProductionSec are combined" {
            $r = Invoke-Deploy @("bmp", "-Env", "dev", "-SaveSec", "-ActivateProductionSec")
            $r.ExitCode | Should -Not -Be 0
            $r.Output | Should -Match "One or more parameters issued cannot be used together"
        }

        It "Should fail when -SaveApi and -ActivateStaging are combined" {
            $r = Invoke-Deploy @("bmp", "-Env", "dev", "-SaveSec", "-ActivateStaging")
            $r.ExitCode | Should -Not -Be 0
            $r.Output | Should -Match "One or more parameters issued cannot be used together"
        }

        It "Should fail when -ActivateStagingApi and -ActivateStaging are combined" {
            $r = Invoke-Deploy @("bmp", "-Env", "dev", "-ActivateStagingApi", "-ActivateStaging")
            $r.ExitCode | Should -Not -Be 0
            $r.Output | Should -Match "One or more parameters issued cannot be used together"
        }

        # THIS IS CURRENTLY COMMENTED OUT BECAUSE THE SCRIPT DOES NOT CURRENTLY FAIL WHEN CPS PARAMETERS ARE PASSED TO BMP
        # It "Should fail when CPS parameters are passed" {
        #     $r = Invoke-Deploy @("bmp", "-Env", "dev", "-ActivateStaging", "-CpsType", "dv-san-cert")
        #     $r.ExitCode | Should -Not -Be 0
        #     $r.Output | Should -Match "CPS parameters not applicable"
        # }

        # THIS IS CURRENTLY COMMENTED OUT BECAUSE THE SCRIPT DOES NOT CURRENTLY FAIL WHEN EDNS PARAMETERS ARE PASSED TO BMP
        # It "Should fail when EDNS parameters are passed" {
        #     $r = Invoke-Deploy @("bmp", "-Env", "dev", "-SaveApi", "-ZoneType", "primary")
        #     $r.ExitCode | Should -Not -Be 0
        #     $r.Output | Should -Match "EDNS parameters not applicable"
        # }
    }

    Context "CPS (cps) parameter validation" {
        It "Should fail without any parameters" {
            $r = Invoke-Deploy @("cps")
            $r.ExitCode | Should -Not -Be 0
            $r.Output | Should -Match "CpsType is required"
        }

        It "Should fail without -CpsType parameter" {
            $r = Invoke-Deploy @("cps", "-CreateCert", "cert1")
            $r.ExitCode | Should -Not -Be 0
            $r.Output | Should -Match "CpsType is required"
        }

        It "Should fail for invalid CPS type" {
            $r = Invoke-Deploy @("cps", "-CpsType", "invalid-type", "-CreateCert", "cert1")
            $r.ExitCode | Should -Not -Be 0
            $r.Output | Should -Match 'The argument "invalid-type" does not belong to the set'
        }

        It "Should fail without a cert action parameter" {
            $r = Invoke-Deploy @("cps", "-CpsType", "dv-san-cert")
            $r.ExitCode | Should -Not -Be 0
            $r.Output | Should -Match "Please specify at least one parameter"
        }

        It "Should fail without a cert name argument when -CreateCert is specified" {
            $r = Invoke-Deploy @("cps", "-CpsType", "dv-san-cert", "-CreateCert")
            $r.ExitCode | Should -Not -Be 0
            $r.Output | Should -Match "Missing an argument for parameter 'CreateCert'."
        }

        It "Should fail without a cert name argument when -UploadCert is specified" {
            $r = Invoke-Deploy @("cps", "-CpsType", "dv-san-cert", "-UploadCert")
            $r.ExitCode | Should -Not -Be 0
            $r.Output | Should -Match "Missing an argument for parameter 'UploadCert'."
        }

        It "Should fail when -CreateCert and -UploadCert are combined" {
            $r = Invoke-Deploy @("cps", "-CpsType", "third-party-cert", "-CreateCert", "cert1", "-UploadCert", "cert1")
            $r.ExitCode | Should -Not -Be 0
            $r.Output | Should -Match "One or more parameters issued cannot be used together"
        }

        It "Should fail when -CreateCert and -DestroyCert are combined" {
            $r = Invoke-Deploy @("cps", "-CpsType", "dv-san-cert", "-CreateCert", "cert1", "-DestroyCert", "cert1")
            $r.ExitCode | Should -Not -Be 0
            $r.Output | Should -Match "One or more parameters issued cannot be used together"
        }

        It "Should fail when -UploadCert and -DestroyCert are combined" {
            $r = Invoke-Deploy @("cps", "-CpsType", "third-party-cert", "-UploadCert", "cert1", "-DestroyCert", "cert1")
            $r.ExitCode | Should -Not -Be 0
            $r.Output | Should -Match "One or more parameters issued cannot be used together"
        }

        It "Should fail when EDNS parameters are passed" {
            $r = Invoke-Deploy @("cps", "-CpsType", "dv-san-cert", "-ZoneType", "secondary")
            $r.ExitCode | Should -Not -Be 0
            $r.Output | Should -Match "Deployment failed: Please specify at least one parameter: -CreateCert, -UploadCert, or -DestroyCert"
        }

        It "Should fail when BMP parameters are passed" {
            $r = Invoke-Deploy @("cps", "-CpsType", "dv-san-cert", "-SaveApi")
            $r.ExitCode | Should -Not -Be 0
            $r.Output | Should -Match "Deployment failed: Please specify at least one parameter: -CreateCert, -UploadCert, or -DestroyCert"
        }

        It "Should fail when AAP or PM parameters are passed" {
            $r = Invoke-Deploy @("cps", "-CpsType", "dv-san-cert", "-ActivateStaging")
            $r.ExitCode | Should -Not -Be 0
            $r.Output | Should -Match "template parameters not applicable for CPS template"
        }
    }

    Context "Edge DNS (edns) parameter validation" {
        It "Should fail without -Env parameter" {
            $r = Invoke-Deploy @("edns")
            $r.ExitCode | Should -Not -Be 0
            $r.Output | Should -Match "Environment parameter required"
        }

        It "Should fail without -ZoneType parameter" {
            $r = Invoke-Deploy @("edns", "-Env", "dev")
            $r.ExitCode | Should -Not -Be 0
            $r.Output | Should -Match "ZoneType parameter required"
        }

        It "Should fail for invalid ZoneType" {
            $r = Invoke-Deploy @("edns", "-Env", "dev", "-ZoneType", "invalid-type")
            $r.ExitCode | Should -Not -Be 0
            $r.Output | Should -Match 'The argument "invalid-type" does not belong to the set'
        }


        It "Should fail when -Destroy is combined with other parameters" {
            $r = Invoke-Deploy @("aap", "-Env", "dev", "-Destroy", "-ActivateProduction")
            $r.ExitCode | Should -Not -Be 0
            $r.Output | Should -Match "One or more parameters issued cannot be used together"
        }

        It "Should fail when CPS parameters are passed" {
            $r = Invoke-Deploy @("edns", "-Env", "dev", "-ZoneType", "primary", "-CpsType", "dv-san-cert")
            $r.ExitCode | Should -Not -Be 0
            $r.Output | Should -Match "CPS parameters are not applicable"
        }

        # THIS IS CURRENTLY COMMENTED OUT BECAUSE THE SCRIPT DOES NOT CURRENTLY FAIL WHEN -Destroy IS COMBINED WITH OTHER PARAMETERS
        # It "Should fail when AAP or PM parameters are passed" {
        #     $r = Invoke-Deploy @("edns", "-Env", "dev", "-ZoneType", "primary", "-Destroy")
        #     $r.ExitCode | Should -Not -Be 0
        #     $r.Output | Should -Match "template parameters not applicable for EDNS template"
        # }
    }

    Context "Invalid TemplateType" {
        It "Should fail with an invalid TemplateType value" {
            $r = Invoke-Deploy @("invalid")
            $r.ExitCode | Should -Not -Be 0
            $r.Output | Should -Match 'The argument "invalid" does not belong to the set'
        }
    }

    # -----------------------------------------------------------------------
    # Global options
    # "accepted" tests use a nonexistent environment/cert so the script fails
    # fast at prerequisite validation (file-not-found) rather than reaching
    # terraform, while still proving the parameter binding succeeded.
    # -----------------------------------------------------------------------

    # WE NEED TO RE-ARCHITECTURE HOW THE COMMANDS ARE EVALUATED TO MAKE THESE TESTS MORE STANDARD
    # ACROSS THE DIFFERENT TEMPLATES. CURRENTLY, THE TESTS ARE NOT CONSISTENT IN THEIR BEHAVIOR AND OUTPUT.
    # FOR EXAMPLE -Dry DOESN'T CURRENTLY WORK ON THE edns TEMPLATE.
    Context "Global -Help option" {
        It "Should display the script synopsis in help output and exit 0 when passed with a template type" {
            $r = Invoke-Deploy @("pm", "-Help")
            $r.ExitCode | Should -Be 0
            $r.Output | Should -Match "Save and/or activate resources via Terraform"
        }

        It "Should display the script synopsis in help output and exit 0 when combined with other valid parameters" {
            $r = Invoke-Deploy @("aap", "-Env", "dev", "-Save", "-Help")
            $r.ExitCode | Should -Be 0
            $r.Output | Should -Match "Save and/or activate resources via Terraform"
        }
    }

    Context "Global -Dry option" {
        It "Should be accepted alongside -Save (no parameter set conflict)" {
            $r = Invoke-Deploy @("pm", "-Env", "nonexistent", "-Save", "-Dry")
            $r.ExitCode | Should -Not -Be 0
            $r.Output | Should -Not -Match "Parameter set cannot be resolved"
        }

        It "Should be accepted alongside -ActivateStaging (no parameter set conflict)" {
            $r = Invoke-Deploy @("aap", "-Env", "nonexistent", "-ActivateStaging", "-Dry")
            $r.ExitCode | Should -Not -Be 0
            $r.Output | Should -Not -Match "Parameter set cannot be resolved"
        }

        It "Should be accepted alongside BMP -SaveApi (no parameter set conflict)" {
            $r = Invoke-Deploy @("bmp", "-Env", "nonexistent", "-SaveApi", "-Dry")
            $r.ExitCode | Should -Not -Be 0
            $r.Output | Should -Not -Match "Parameter set cannot be resolved"
        }

        It "Should fail without an action parameter because the parameter set is ambiguous" {
            $r = Invoke-Deploy @("pm", "-Env", "nonexistent", "-Dry")
            $r.ExitCode | Should -Not -Be 0
            $r.Output | Should -Match "Parameter set cannot be resolved"
        }

        It "Should fail when combined with a CPS cert action (-Dry not valid in cps parameter sets)" {
            $r = Invoke-Deploy @("cps", "-CpsType", "dv-san-cert", "-CreateCert", "cert1", "-Dry")
            $r.ExitCode | Should -Not -Be 0
            $r.Output | Should -Match "Parameter set cannot be resolved"
        }
    }

    Context "Global -Force option" {
        It "Should be accepted alongside -Save (no parameter set conflict)" {
            $r = Invoke-Deploy @("pm", "-Env", "nonexistent", "-Save", "-Force")
            $r.ExitCode | Should -Not -Be 0
            $r.Output | Should -Not -Match "Parameter set cannot be resolved"
        }

        It "Should be accepted alongside -ActivateStaging (no parameter set conflict)" {
            $r = Invoke-Deploy @("aap", "-Env", "nonexistent", "-ActivateStaging", "-Force")
            $r.ExitCode | Should -Not -Be 0
            $r.Output | Should -Not -Match "Parameter set cannot be resolved"
        }

        It "Should be accepted with CPS cert actions (-Force not in the CPS exclusion list)" {
            $r = Invoke-Deploy @("cps", "-CpsType", "dv-san-cert", "-CreateCert", "cert999", "-Force")
            $r.ExitCode | Should -Not -Be 0
            $r.Output | Should -Not -Match "Parameter set cannot be resolved"
            $r.Output | Should -Not -Match "Security template parameters not applicable"
        }
    }

    Context "Global -SkipValidation option" {
        It "Should fail when passed to the CPS template" {
            $r = Invoke-Deploy @("cps", "-CpsType", "dv-san-cert", "-CreateCert", "cert1", "-SkipValidation")
            $r.ExitCode | Should -Not -Be 0
            $r.Output | Should -Match "Security template parameters not applicable"
        }

        It "Should be accepted for pm template without parameter set conflicts" {
            $r = Invoke-Deploy @("pm", "-Env", "nonexistent", "-Save", "-SkipValidation")
            $r.ExitCode | Should -Not -Be 0
            $r.Output | Should -Not -Match "Parameter set cannot be resolved"
        }

        It "Should be accepted for aap template without parameter set conflicts" {
            $r = Invoke-Deploy @("aap", "-Env", "nonexistent", "-ActivateStaging", "-SkipValidation")
            $r.ExitCode | Should -Not -Be 0
            $r.Output | Should -Not -Match "Parameter set cannot be resolved"
        }
    }

    Context "Global -Debug option" {
        It "Should be accepted alongside -Save (no parameter set conflict)" {
            $r = Invoke-Deploy @("pm", "-Env", "nonexistent", "-Save", "-Debug")
            $r.ExitCode | Should -Not -Be 0
            $r.Output | Should -Not -Match "Parameter set cannot be resolved"
        }

        It "Should be accepted alongside BMP -SaveApi (no parameter set conflict)" {
            $r = Invoke-Deploy @("bmp", "-Env", "nonexistent", "-SaveApi", "-Debug")
            $r.ExitCode | Should -Not -Be 0
            $r.Output | Should -Not -Match "Parameter set cannot be resolved"
        }
    }
}
