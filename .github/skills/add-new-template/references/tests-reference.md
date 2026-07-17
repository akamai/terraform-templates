# Pester Tests Reference

Copy-paste blocks for each of the four locations in `tests/deploy.Tests.ps1` that require additions when a new template is added.

In all examples, replace `{Name}` with the PascalCase module name (e.g. `CloudWrapper`) and `{key}` with the lowercase template type key (e.g. `cw`).

---

## 7a — Module Loading

**Location:** inside `Describe "Template Modules - Module Loading"` → `Context "All template modules should be available"`.

```powershell
It "Should load {Name} module" {
    { Import-Module "$PSScriptRoot/../lib/templates/{Name}.psm1" -Force } | Should -Not -Throw
}
```

Also add to the `BeforeAll` block of the **Param Policy Contract** describe block (the `BeforeAll` that imports all template modules before the three Policy Contract contexts):

```powershell
Import-Module "$PSScriptRoot/../lib/templates/{Name}.psm1" -Force
```

---

## 7b — Param Policy Contract

Three contexts within `Describe "Template Modules - Param Policy Contract"`.

### Context "Every template module exports a Get-*ParamPolicy function"

```powershell
It "{Name} module exports Get-{Name}ParamPolicy" {
    Get-Command "Get-{Name}ParamPolicy" -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
}
```

### Context "Each Get-*ParamPolicy returns a valid hashtable with an Allowed list"

```powershell
It "Get-{Name}ParamPolicy returns a hashtable with Allowed" {
    $p = Get-{Name}ParamPolicy
    $p | Should -BeOfType [hashtable]
    $p.Allowed | Should -Not -BeNullOrEmpty
}
```

### Context "Every template module exports an Invoke-*Template dispatch function"

```powershell
It "{Name} module exports Invoke-{Name}Template" {
    Get-Command "Invoke-{Name}Template" -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
}
```

---

## 7c — Custom Folder Logic (conditional)

Only needed when `Get-{Name}TemplateFolder` is exported. Add inside:
`Context "Modules with custom folder logic export Get-*TemplateFolder"`.

```powershell
It "{Name} module exports Get-{Name}TemplateFolder" {
    Get-Command "Get-{Name}TemplateFolder" -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
}

It "Get-{Name}TemplateFolder derives the folder from the runtime param" {
    # Replace SomeParam and expected folder values to match the actual implementation.
    Get-{Name}TemplateFolder -BoundParams @{ SomeParam = "value-a" } | Should -Be "new-expected-folder-a"
    Get-{Name}TemplateFolder -BoundParams @{ SomeParam = "value-b" } | Should -Be "new-expected-folder-b"
}

It "Get-{Name}TemplateFolder throws when the required param is missing" {
    { Get-{Name}TemplateFolder -BoundParams @{} } | Should -Throw -ExpectedMessage "*SomeParam is required*"
}
```

---

## 7d — CLI Parameter Validation

Add a new `Context` block inside `Describe "deploy.ps1 - CLI Parameter Validation"`.

The block below covers all **standard cases** that every environment-based template must have. Remove or adjust cases that don't apply (e.g. if the template has no `-ActivateStaging`).

```powershell
Context "{Product name} ({key}) parameter validation" {
    It "Should fail without -Env parameter" {
        $r = Invoke-Deploy @("{key}")
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match "Environment parameter required"
    }

    It "Should fail without an action parameter" {
        $r = Invoke-Deploy @("{key}", "-Env", "dev")
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match "Please specify at least one parameter"
    }

    It "Should fail when -Save and -ActivateStaging are combined" {
        $r = Invoke-Deploy @("{key}", "-Env", "dev", "-Save", "-ActivateStaging")
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match "One or more parameters issued cannot be used together"
    }

    It "Should fail when -Save and -ActivateProduction are combined" {
        $r = Invoke-Deploy @("{key}", "-Env", "dev", "-Save", "-ActivateProduction")
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match "One or more parameters issued cannot be used together"
    }

    It "Should fail when -Destroy is combined with other action parameters" {
        $r = Invoke-Deploy @("{key}", "-Env", "dev", "-Destroy", "-ActivateProduction")
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match "One or more parameters issued cannot be used together"
    }

    # Cross-template: parameters from other templates must be rejected.
    It "Should fail when CPS parameters are passed" {
        $r = Invoke-Deploy @("{key}", "-Env", "dev", "-Save", "-CpsType", "dv-san-cert")
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match "Parameter '-CpsType' is not applicable for the '{key}' template"
    }

    It "Should fail when EDNS parameters are passed" {
        $r = Invoke-Deploy @("{key}", "-Env", "dev", "-Save", "-ZoneType", "primary")
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match "Parameter '-ZoneType' is not applicable for the '{key}' template"
    }

    It "Should fail when BMP-specific parameters are passed" {
        # -SaveApi is in its own parameter set so it doesn't conflict with -Save
        $r = Invoke-Deploy @("{key}", "-Env", "dev", "-SaveApi")
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match "Parameter '-SaveApi' is not applicable for the '{key}' template"
    }
}
```

### Adjustments for non-standard templates

| Situation | Adjustment |
|---|---|
| Template doesn't use `-Environment` | Remove the first two `It` blocks and don't assert `"Environment parameter required"` |
| Template has its own unique required param (like `-CpsType`) | Add an `It` asserting failure when that param is absent |
| Template has custom action switches (not `Save/ActivateStaging/ActivateProduction/Destroy`) | Replace the conflicting-params tests with the actual mutually-exclusive pairs from your `Param(...)` sets |
| Template has its own non-standard params | Verify those params are accepted (no error) AND verify that the template's params are rejected by other templates |

### Running the full suite

```powershell
# From the repository root
Invoke-Pester -Path ./tests/deploy.Tests.ps1 -Output Detailed

# Using the config file (from the tests/ directory)
cd tests && Invoke-Pester -Configuration (./pester.config.ps1)
```
