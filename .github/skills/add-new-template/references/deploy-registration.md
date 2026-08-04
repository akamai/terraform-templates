# deploy.ps1 Registration Reference

Three surgical edits are required. All are in `deploy.ps1` at the repository root.
Search for the anchor comments below to locate each block.

---

## Edit 1 — Add to `[ValidateSet]` on `$TemplateType`

**Locate** the `Param(...)` block. The first parameter looks like:

```powershell
[Parameter(Position = 0, Mandatory = $true)]
[ValidateSet("aap", "aapasm", "pm", "cps", "bmp", "edns", "ds2")]
[string]$TemplateType,
```

**Change** the `ValidateSet` to include your new key (keep alphabetical or logical order):

```powershell
[ValidateSet("aap", "aapasm", "pm", "cps", "bmp", "edns", "ds2", "mykey")]
```

Also add a `.PARAMETER TemplateType` line in the doc block at the top of the file that lists the new key.

---

## Edit 2 — Add to `$templateModuleMap`

**Locate** this block (search for `$templateModuleMap`):

```powershell
$templateModuleMap = @{
    "aap"    = "AAP"
    "aapasm" = "AAPASM"
    "pm"     = "PropertyManager"
    "cps"    = "CPS"
    "bmp"    = "BMP"
    "edns"   = "EDNS"
    "ds2"    = "DS2"
}
```

**Add** your entry:

```powershell
$templateModuleMap = @{
    "aap"    = "AAP"
    "aapasm" = "AAPASM"
    "pm"     = "PropertyManager"
    "cps"    = "CPS"
    "bmp"    = "BMP"
    "edns"   = "EDNS"
    "ds2"    = "DS2"
    "mykey"  = "MyName"          # ← add this line
}
```

The value (`"MyName"`) becomes the stem for all derived function names:
- `New-MyNameTemplate`
- `Get-MyNameParamPolicy`
- `Invoke-MyNameTemplate`

---

## Edit 3a — Static folder (most templates)

**Locate** this block (search for `$templateFolderMap`):

```powershell
$templateFolderMap = @{
    "aap"    = "new-aap-configuration"
    "aapasm" = "new-aapasm-configuration"
    "pm"     = "new-property"
    "bmp"    = "new-bmp-endpoints"
    "edns"   = "new-edns"
    "ds2"    = "new-ds2"
}
```

**Add** your folder:

```powershell
"mykey"  = "new-myname-configuration"   # ← add this line
```

---

## Edit 3b — Dynamic folder (like CPS)

If the Terraform folder cannot be determined from a static string — e.g. it depends on a runtime parameter — **skip Edit 3a** and instead export `Get-{Name}TemplateFolder` from the module:

```powershell
function Get-MyNameTemplateFolder {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$BoundParams
    )
    # Derive folder from a runtime param
    if (-not $BoundParams['SomeParam']) {
        throw "SomeParam is required for MyName template."
    }
    return "new-$($BoundParams['SomeParam'])"
}
# Add to Export-ModuleMember in the module file
```

`deploy.ps1` checks for this function first (via `Get-Command`) and uses it in preference to `$templateFolderMap`.

---

## Verification

After all edits, run:

```powershell
# Should print plan output without errors
pwsh deploy.ps1 mykey -Env dev -Save -Dry

# Should list the new key in the parameter description
Get-Help ./deploy.ps1 -Parameter TemplateType
```

Expected failure if module name is wrong:
```
Template dispatch function not found: Invoke-MyNameTemplate.
Ensure the module exports this function.
```

Expected failure if `Export-ModuleMember` is missing:
```
Template dispatch function not found: Invoke-MyNameTemplate.
```

Both point to a mismatch between the value in `$templateModuleMap` and either the function names or the export statement in the `.psm1` file.
