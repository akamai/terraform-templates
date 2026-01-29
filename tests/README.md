# Testing Guide for deploy.ps1

This directory contains comprehensive tests for the `deploy.ps1` Terraform deployment script using **Pester**, PowerShell's testing framework.

## Table of Contents
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Running Tests](#running-tests)
- [Test Structure](#test-structure)
- [Test Coverage](#test-coverage)
- [Writing New Tests](#writing-new-tests)
- [Continuous Integration](#continuous-integration)

## Prerequisites

- **PowerShell 7.2+** (recommended) or **Windows PowerShell 5.1+**
- **Pester 5.x** testing framework
- The `deploy.ps1` script in the parent directory

## Installation

### 1. Check if Pester is installed

```powershell
Get-Module -ListAvailable Pester
```

### 2. Install or Update Pester

#### On Windows (PowerShell 5.1)
```powershell
# Install Pester 5.x
Install-Module -Name Pester -Force -SkipPublisherCheck
```

#### On macOS/Linux (PowerShell 7+)
```powershell
# Install Pester 5.x
Install-Module -Name Pester -Scope CurrentUser -Force
```

#### Verify Installation
```powershell
Import-Module Pester
Get-Module Pester
```

Expected output should show version 5.x or higher.

## Running Tests

### Run All Tests

From the `ps-terraform-templates` directory:

```powershell
# Run all tests in the test file
Invoke-Pester -Path ./tests/deploy.Tests.ps1
```

### Run Tests with Detailed Output

```powershell
# Show detailed test results
Invoke-Pester -Path ./tests/deploy.Tests.ps1 -Output Detailed
```

### Run Specific Test Groups

```powershell
# Run only parameter validation tests
Invoke-Pester -Path ./tests/deploy.Tests.ps1 -TagFilter "ParameterValidation"

# Run tests for a specific Describe block
Invoke-Pester -Path ./tests/deploy.Tests.ps1 -FullNameFilter "*Get-TfVarValue*"
```

### Generate Code Coverage Report

```powershell
# Run tests with code coverage analysis
$config = New-PesterConfiguration
$config.Run.Path = './tests/deploy.Tests.ps1'
$config.CodeCoverage.Enabled = $true
$config.CodeCoverage.Path = './deploy.ps1'
$config.CodeCoverage.OutputPath = './tests/coverage.xml'
$config.Output.Verbosity = 'Detailed'

Invoke-Pester -Configuration $config
```

### Run Tests in CI/CD Mode

```powershell
# Exit with error code if tests fail (for CI/CD pipelines)
$result = Invoke-Pester -Path ./tests/deploy.Tests.ps1 -PassThru
exit $result.FailedCount
```

## Test Structure

The test suite is organized into the following sections:

### 1. **Parameter Validation Tests**
- Validates required parameters
- Tests parameter combinations
- Ensures proper error messages for invalid inputs

### 2. **Function Unit Tests**
- `Get-TfVarValue`: Parsing tfvars files
- `Get-Username`: Cross-platform username retrieval
- Template folder mapping logic
- Resource name determination

### 3. **Logic Tests**
- Backend configuration generation
- Output filename determination
- Email list JSON formatting
- Version notes handling

### 4. **Product ID Validation Tests**
- AAP product ID validation
- AAPASM product ID validation
- PM (Property Manager) product ID validation

### 5. **Feature Tests**
- Retry mechanism logic
- Debug mode configuration
- Dry run mode behavior
- Skip validation flag

### 6. **Integration Tests**
- Directory structure validation
- File existence checks
- End-to-end workflow simulations

## Test Coverage

The test suite covers:

| Area | Coverage |
|------|----------|
| Parameter Validation | ✅ Complete |
| Helper Functions | ✅ Complete |
| Template Mapping | ✅ Complete |
| File Operations | ✅ Complete |
| Product Validation Logic | ⚠️ Partial (mocked) |
| Terraform Commands | ⚠️ Mocked |
| Akamai API Calls | ⚠️ Mocked |

### Coverage Metrics

Run the coverage report to see detailed metrics:
```powershell
Invoke-Pester -Path ./tests/deploy.Tests.ps1 -CodeCoverage ./deploy.ps1
```

## Writing New Tests

### Test Naming Convention

Follow Pester's BDD-style naming:

```powershell
Describe "Component or Function Name" {
    Context "When [specific condition]" {
        It "Should [expected behavior]" {
            # Test code
        }
    }
}
```

### Example: Adding a New Test

```powershell
Describe "deploy.ps1 - New Feature" {
    
    Context "When feature is enabled" {
        It "Should perform expected action" {
            # Arrange
            $input = "test-value"
            
            # Act
            $result = SomeFunction -Parameter $input
            
            # Assert
            $result | Should -Be "expected-value"
        }
    }
}
```

### Mocking External Commands

```powershell
BeforeAll {
    # Mock terraform command
    Mock terraform {
        return 0  # Simulate successful execution
    }
    
    # Mock with specific parameters
    Mock terraform {
        return @{
            config_id = "12345"
            version = "v1"
        }
    } -ParameterFilter { $args -contains "output" }
}
```

## Test Fixtures

The `tests/fixtures/` directory contains:

- **sample-dev.tfvars**: Mock development environment configuration
- **sample-prod.tfvars**: Mock production environment configuration
- **mock-edgerc**: Sample Akamai EdgeGrid credentials file

These files are used for isolated testing without requiring real infrastructure.

## Continuous Integration

### Jenkins Pipeline Example

```groovy
stage('Test') {
    steps {
        pwsh '''
            Install-Module -Name Pester -Force -Scope CurrentUser
            $result = Invoke-Pester -Path ./ps-terraform-templates/tests/deploy.Tests.ps1 -PassThru
            if ($result.FailedCount -gt 0) {
                throw "Tests failed: $($result.FailedCount) failures"
            }
        '''
    }
}
```

### GitHub Actions Example

```yaml
- name: Run Pester Tests
  shell: pwsh
  run: |
    Install-Module -Name Pester -Force -Scope CurrentUser
    Invoke-Pester -Path ./ps-terraform-templates/tests/deploy.Tests.ps1 -Output Detailed
```

### GitLab CI Example

```yaml
test:
  script:
    - pwsh -Command "Install-Module -Name Pester -Force -Scope CurrentUser"
    - pwsh -Command "Invoke-Pester -Path ./ps-terraform-templates/tests/deploy.Tests.ps1 -Output Detailed"
```

## Test Maintenance

### When to Update Tests

Update tests when:
- Adding new parameters to deploy.ps1
- Modifying validation logic
- Adding new template types
- Changing Terraform command structure
- Updating product IDs or validation rules

### Best Practices

1. **Keep tests independent** - Each test should run in isolation
2. **Use descriptive names** - Test names should clearly describe what's being tested
3. **Mock external dependencies** - Don't rely on real Terraform or Akamai API calls
4. **Test edge cases** - Include tests for error conditions and boundary values
5. **Maintain test fixtures** - Keep mock data files up to date with real configurations

## Troubleshooting

### Common Issues

#### "Cannot find path" errors
```powershell
# Ensure you're running tests from the correct directory
Set-Location /path/to/ps-terraform-templates
Invoke-Pester -Path ./tests/deploy.Tests.ps1
```

#### "Command not found: terraform"
```powershell
# The tests mock terraform commands, but if errors persist:
Mock terraform { return 0 } -ModuleName 'Global'
```

#### Pester version conflicts
```powershell
# Remove old versions and install latest
Get-Module Pester -ListAvailable | Uninstall-Module -Force
Install-Module -Name Pester -Force -SkipPublisherCheck
```

## Additional Resources

- [Pester Documentation](https://pester.dev/docs/quick-start)
- [PowerShell Testing Best Practices](https://pester.dev/docs/usage/mocking)
- [Code Coverage with Pester](https://pester.dev/docs/usage/code-coverage)

## Contributing

When contributing new features to `deploy.ps1`:

1. Write tests first (TDD approach recommended)
2. Ensure all existing tests pass
3. Add tests for new functionality
4. Update this README if adding new test categories
5. Maintain >80% code coverage

## Support

For questions or issues with tests:
- Create an issue in the repository
- Contact the DevOps team
- Review the Pester documentation
