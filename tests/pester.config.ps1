# Pester Configuration File
# This file can be used to customize Pester test runs

$PesterConfig = New-PesterConfiguration

# Test execution settings
$PesterConfig.Run.Path = './deploy.Tests.ps1'
$PesterConfig.Run.Exit = $true  # Exit with error code on failure (useful for CI/CD)

# Output settings
$PesterConfig.Output.Verbosity = 'Detailed'

# Code coverage settings (optional - uncomment to enable)
# $PesterConfig.CodeCoverage.Enabled = $true
# $PesterConfig.CodeCoverage.Path = '../deploy.ps1'
# $PesterConfig.CodeCoverage.OutputPath = './coverage.xml'
# $PesterConfig.CodeCoverage.OutputFormat = 'JaCoCo'

# Test result export (optional - uncomment to enable)
# $PesterConfig.TestResult.Enabled = $true
# $PesterConfig.TestResult.OutputPath = './tests/testResults.xml'
# $PesterConfig.TestResult.OutputFormat = 'NUnitXml'

# Return the configuration
$PesterConfig