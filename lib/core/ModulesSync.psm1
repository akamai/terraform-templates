<#
.SYNOPSIS
Core modules-sync capability

.DESCRIPTION
Downloads (clones, or updates if already present) the terraform-templates-modules
repository and repoints the `source` argument of every new-*/main.tf module block
at the local copy. The original git:: source line is preserved as a comment directly
above the new local-path line so it can be restored or used as a reference.

This is a standalone CLI capability (-Download / -Restore), not tied to any TemplateType.
#>

$script:ModulesRepoUrl = "https://github.com/akamai/terraform-templates-modules.git"
$script:LocalModuleMarker = "# local-modules (deploy.ps1 -Download)"
$script:ModuleSourcePattern = '^(?<indent>\s*)(?<hash>#\s*)?source(?<pad>\s*)=\s*"git::https://github\.com/akamai/terraform-templates-modules\.git//(?<subpath>[^"?]+)(?:\?ref=(?<ref>[^"]+))?"\s*$'

function Get-ModulesSourcePrefix {
    <#
    .SYNOPSIS
    Converts a clone destination (relative to terraform-templates/) into the
    path to use inside a new-*/main.tf source argument (one directory deeper).
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModulesPath
    )

    $normalized = $ModulesPath.TrimEnd('/', '\').Replace('\', '/')
    if ([System.IO.Path]::IsPathRooted($ModulesPath)) {
        return $normalized
    }
    return "../$normalized"
}

function Read-MainTfLines {
    <#
    .SYNOPSIS
    Reads a file's lines while recording its line-ending style and whether it
    ends with a trailing newline, so Write-MainTfLines can reproduce it exactly.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $raw = Get-Content -Path $Path -Raw
    $eol = if ($raw -match "`r`n") { "`r`n" } else { "`n" }
    $hadTrailingNewline = $raw.EndsWith($eol)
    $lines = [System.Collections.Generic.List[string]]::new()
    foreach ($part in ($raw -split [regex]::Escape($eol))) { $lines.Add($part) }
    if ($hadTrailingNewline -and $lines.Count -gt 0) { $lines.RemoveAt($lines.Count - 1) }

    return @{ Lines = $lines; Eol = $eol; HadTrailingNewline = $hadTrailingNewline }
}

function Write-MainTfLines {
    <#
    .SYNOPSIS
    Joins lines back into text and writes it. Takes pre-joined content (rather
    than a collection parameter) since PowerShell's Mandatory-parameter binder
    rejects a bound collection argument as "empty" under some conditions.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Content
    )

    [System.IO.File]::WriteAllText($Path, $Content)
}

function Sync-ModulesRepository {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoPath,

        [Parameter(Mandatory = $true)]
        [string]$Ref,

        [Parameter(Mandatory = $false)]
        [switch]$Dry
    )

    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        throw "git is required to download the modules repository but was not found in PATH."
    }

    $gitDir = Join-Path $RepoPath ".git"

    if (Test-Path $gitDir) {
        if ($Dry) {
            Write-Host "[DRY] Would update existing modules repository at '$RepoPath' (fetch + checkout '$Ref')" -ForegroundColor Yellow
            return
        }

        Write-Host "Updating modules repository at '$RepoPath'..." -ForegroundColor Cyan
        # --force lets moved/re-cut tags overwrite stale local ones instead of being rejected.
        git -C $RepoPath fetch origin --tags --force --quiet
        if ($LASTEXITCODE -ne 0) { throw "git fetch failed for '$RepoPath' (exit code $LASTEXITCODE)" }

        git -C $RepoPath checkout $Ref --quiet
        if ($LASTEXITCODE -ne 0) { throw "git checkout '$Ref' failed for '$RepoPath' (exit code $LASTEXITCODE)" }

        # Only branches track a remote; tags resolve to a detached HEAD and can't be pulled.
        git -C $RepoPath symbolic-ref -q HEAD *> $null
        if ($LASTEXITCODE -eq 0) {
            git -C $RepoPath pull origin $Ref --quiet
            if ($LASTEXITCODE -ne 0) { throw "git pull failed for '$RepoPath' (exit code $LASTEXITCODE)" }
        }
    }
    else {
        if ($Dry) {
            Write-Host "[DRY] Would clone '$script:ModulesRepoUrl' (ref '$Ref') into '$RepoPath'" -ForegroundColor Yellow
            return
        }

        Write-Host "Cloning modules repository (ref '$Ref') into '$RepoPath'..." -ForegroundColor Cyan
        git clone --branch $Ref $script:ModulesRepoUrl $RepoPath --quiet
        if ($LASTEXITCODE -ne 0) { throw "git clone failed for '$script:ModulesRepoUrl' (exit code $LASTEXITCODE)" }
    }

    Write-Host "✓ Modules repository ready at '$RepoPath'" -ForegroundColor Green
}

function Update-ModuleSourceReferences {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModulesPath,

        [Parameter(Mandatory = $false)]
        [switch]$Dry
    )

    $sourcePrefix = Get-ModulesSourcePrefix -ModulesPath $ModulesPath
    $templateDirs = Get-ChildItem -Path "." -Directory -Filter "new-*" -ErrorAction SilentlyContinue | Sort-Object Name
    $filesChanged = 0
    $refsChanged = 0

    foreach ($dir in $templateDirs) {
        $mainTfPath = Join-Path $dir.FullName "main.tf"
        if (-not (Test-Path $mainTfPath)) { continue }

        $file = Read-MainTfLines -Path $mainTfPath
        $lines = $file.Lines
        $output = [System.Collections.Generic.List[string]]::new()
        $fileChanged = $false

        for ($i = 0; $i -lt $lines.Count; $i++) {
            $line = $lines[$i]

            if ($line -notmatch $script:ModuleSourcePattern) {
                $output.Add($line)
                continue
            }

            $indent = $Matches['indent']
            $subpath = $Matches['subpath']
            $isCommented = [bool]$Matches['hash']
            $localLine = "${indent}source = `"$sourcePrefix/$subpath`"  $script:LocalModuleMarker"
            $nextLine = if ($i + 1 -lt $lines.Count) { $lines[$i + 1] } else { $null }
            $nextIsMarker = $nextLine -and $nextLine.Contains($script:LocalModuleMarker)

            if (-not $isCommented) {
                $output.Add("${indent}# $($line.TrimStart())")
                $output.Add($localLine)
                $fileChanged = $true
                $refsChanged++
                if ($nextIsMarker) { $i++ }
                continue
            }

            # Already commented out from a previous run — only refresh a stale local path.
            $output.Add($line)
            if ($nextIsMarker) {
                if ($nextLine -ne $localLine) {
                    $output.Add($localLine)
                    $fileChanged = $true
                    $refsChanged++
                }
                else {
                    $output.Add($nextLine)
                }
                $i++
            }
        }

        if ($fileChanged) {
            $filesChanged++
            if ($Dry) {
                Write-Host "[DRY] Would update $mainTfPath" -ForegroundColor Yellow
            }
            else {
                $content = [string]::Join($file.Eol, $output)
                if ($file.HadTrailingNewline) { $content += $file.Eol }
                Write-MainTfLines -Path $mainTfPath -Content $content
                Write-Host "✓ Updated $mainTfPath" -ForegroundColor Green
            }
        }
    }

    $verb = if ($Dry) { "would be" } else { "were" }
    Write-Host "`nModule reference sync: $filesChanged file(s), $refsChanged reference(s) $verb updated." -ForegroundColor Cyan
}

function Restore-ModuleSourceReferences {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$Dry
    )

    $templateDirs = Get-ChildItem -Path "." -Directory -Filter "new-*" -ErrorAction SilentlyContinue | Sort-Object Name
    $filesChanged = 0
    $refsChanged = 0

    foreach ($dir in $templateDirs) {
        $mainTfPath = Join-Path $dir.FullName "main.tf"
        if (-not (Test-Path $mainTfPath)) { continue }

        $file = Read-MainTfLines -Path $mainTfPath
        $output = [System.Collections.Generic.List[string]]::new()
        $fileChanged = $false

        foreach ($line in $file.Lines) {
            if ($line.Contains($script:LocalModuleMarker)) {
                # Drop the injected local line and uncomment the original above it, if present.
                if ($output.Count -gt 0 -and $output[$output.Count - 1] -match $script:ModuleSourcePattern -and $Matches['hash']) {
                    $output[$output.Count - 1] = $output[$output.Count - 1] -replace '^(\s*)#\s*', '$1'
                }
                $fileChanged = $true
                $refsChanged++
                continue
            }
            $output.Add($line)
        }

        if ($fileChanged) {
            $filesChanged++
            if ($Dry) {
                Write-Host "[DRY] Would restore $mainTfPath" -ForegroundColor Yellow
            }
            else {
                $content = [string]::Join($file.Eol, $output)
                if ($file.HadTrailingNewline) { $content += $file.Eol }
                Write-MainTfLines -Path $mainTfPath -Content $content
                Write-Host "✓ Restored $mainTfPath" -ForegroundColor Green
            }
        }
    }

    $verb = if ($Dry) { "would be" } else { "were" }
    Write-Host "`nModule reference restore: $filesChanged file(s), $refsChanged reference(s) $verb restored." -ForegroundColor Cyan
}

function Invoke-ModulesDownload {
    <#
    .SYNOPSIS
    Core entry point for deploy.ps1 -Download.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$ModulesPath,

        [Parameter(Mandatory = $false)]
        [string]$ModulesRef,

        [Parameter(Mandatory = $false)]
        [switch]$Dry
    )

    $resolvedPath = if ($ModulesPath) { $ModulesPath } else { "../terraform-templates-modules" }
    $resolvedRef = if ($ModulesRef) { $ModulesRef } else { "main" }

    Sync-ModulesRepository -RepoPath $resolvedPath -Ref $resolvedRef -Dry:$Dry
    Update-ModuleSourceReferences -ModulesPath $resolvedPath -Dry:$Dry
}

function Invoke-ModulesRestore {
    <#
    .SYNOPSIS
    Core entry point for deploy.ps1 -Restore.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$Dry
    )

    Restore-ModuleSourceReferences -Dry:$Dry
}

Export-ModuleMember -Function Invoke-ModulesDownload, Invoke-ModulesRestore
