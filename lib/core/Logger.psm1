<#
.SYNOPSIS
Logging and output formatting functions

.DESCRIPTION
Provides consistent logging and output across all templates
#>

# Retains the most recently enabled Terraform debug log path so the API rate
# summary can still be produced after Disable-TerraformDebugLogging clears
# the environment variables.
$script:LastDebugLogPath = $null

function Invoke-DebugLogRotation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$LogPath
    )

    if (-not (Test-Path -LiteralPath $LogPath)) { return }

    $item = Get-Item -LiteralPath $LogPath -ErrorAction SilentlyContinue
    if (-not $item -or $item.PSIsContainer) { return }

    # Skip empty files — no prior content to preserve.
    if ($item.Length -eq 0) {
        Remove-Item -LiteralPath $LogPath -Force -ErrorAction SilentlyContinue
        return
    }

    $stamp    = $item.LastWriteTime.ToString('yyyyMMdd-HHmmss')
    $dir      = $item.DirectoryName
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($item.Name)
    $ext      = $item.Extension

    $archive = Join-Path $dir ("{0}.{1}{2}" -f $baseName, $stamp, $ext)
    # Guarantee uniqueness if a same-second archive already exists.
    $suffix = 1
    while (Test-Path -LiteralPath $archive) {
        $archive = Join-Path $dir ("{0}.{1}-{2}{3}" -f $baseName, $stamp, $suffix, $ext)
        $suffix++
    }

    try {
        Move-Item -LiteralPath $LogPath -Destination $archive -Force -ErrorAction Stop
        Write-Host "Rotated previous debug log to: $archive" -ForegroundColor DarkGray
    }
    catch {
        Write-Warning "Failed to rotate previous debug log '$LogPath': $_"
    }
}

function Enable-TerraformDebugLogging {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$LogPath
    )

    Invoke-DebugLogRotation -LogPath $LogPath

    Write-Host "Debug mode enabled - Logging to: $LogPath" -ForegroundColor Yellow
    $env:TF_LOG = "DEBUG"
    $env:TF_LOG_PATH = $LogPath
    $env:AKAMAI_HTTP_TRACE_ENABLED = "true"
    $script:LastDebugLogPath = $LogPath
}

function Disable-TerraformDebugLogging {
    [CmdletBinding()]
    param()
    
    $env:TF_LOG = $null
    $env:TF_LOG_PATH = $null
    $env:AKAMAI_HTTP_TRACE_ENABLED = $null
}

function Write-ExecutionSummary {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [datetime]$StartTime
    )
    
    $endTime = Get-Date
    $duration = $endTime - $StartTime
    
    Write-Host ""
    Write-Host "================================" -ForegroundColor Green
    Write-Host "Script Execution Summary" -ForegroundColor Green
    Write-Host "================================" -ForegroundColor Green
    Write-Host "Started:  $($StartTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Cyan
    Write-Host "Finished: $($endTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Cyan
    Write-Host "Total Duration: $($duration.ToString('hh\:mm\:ss'))" -ForegroundColor Yellow
    Write-Host "================================" -ForegroundColor Green
}

function Get-Username {
    [CmdletBinding()]
    param()
    
    $platform = $PSVersionTable.Platform
    if (-not $platform -or $platform -eq 'Win32NT') {
        return $env:USERNAME
    }
    else {
        return $env:USER
    }
}

<#
.SYNOPSIS
Parse a Terraform DEBUG log and report Akamai API call counts per endpoint prefix.

.DESCRIPTION
PowerShell port of api_rate_summary.sh. Reads the debug log produced when
-Debug is used, aggregates Akamai (*.luna.akamaiapis.net) API calls by minute
(default) or second, grouped by endpoint path prefix, and prints a table.
Optionally lists HTTP 4xx/5xx responses with their JSON detail.

Called automatically by deploy.ps1 at the end of a run when -Debug is used.
#>
function Write-ApiRateSummary {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$LogPath,

        [Parameter()]
        [ValidateSet('minute', 'second')]
        [string]$Granularity = 'minute',

        [Parameter()]
        [ValidateRange(1, 20)]
        [int]$Depth = 1,

        [Parameter()]
        [switch]$IncludeErrors,

        [Parameter()]
        [string]$EnvironmentName = 'unknown'
    )

    if (-not $LogPath) { $LogPath = $script:LastDebugLogPath }
    if (-not $LogPath) { return }

    if (-not (Test-Path -LiteralPath $LogPath)) {
        Write-Host "No debug log found at $LogPath - skipping API rate summary." -ForegroundColor DarkGray
        return
    }

    $debugRequestRe = [regex]'(?:(\d{4}/\d{2}/\d{2} \d{2}:\d{2}:\d{2})\s+)?\[DEBUG\]\s+(GET|POST|PUT|DELETE|PATCH)\s+(.+)$'
    $responseRe     = [regex]'(?:(\d{4}/\d{2}/\d{2} \d{2}:\d{2}:\d{2})\s+)?\[DEBUG\]\s+HTTP/\d\.\d\s+(\d{3})\b'
    $innerTsRe      = [regex]'(\d{4}/\d{2}/\d{2} \d{2}:\d{2}:\d{2})'
    $isoTsRe        = [regex]'^(\d{4})-(\d{2})-(\d{2})T(\d{2}:\d{2}:\d{2})'
    $urlRe          = [regex]::new('https?://[^\s"\\]+', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    $detailRe       = [regex]'"detail"\s*:\s*"((?:[^"\\]|\\.)*)"'
    $methodJsonRe   = [regex]'"method"\s*:\s*"([^"]*)"'
    $instanceRe     = [regex]'"instance"\s*:\s*"([^"]*)"'
    $titleRe        = [regex]'"title"\s*:\s*"((?:[^"\\]|\\.)*)"'
    $statusFieldRe  = [regex]'"status(?:Code)?"\s*:\s*(\d{3})'

    $stderrMarker     = 'registry.opentofu.org/akamai/akamai:stderr='
    $unexpectedMarker = 'unexpected data:'
    $maxBuffer        = 16384
    $maxCandidate     = 4096

    function CleanPiece([string]$raw) {
        $s = $raw.TrimEnd("`n", "`r")
        $idx = $s.IndexOf($unexpectedMarker)
        if ($idx -ge 0) { $s = $s.Substring($idx + $unexpectedMarker.Length) }
        $idx = $s.IndexOf($stderrMarker)
        if ($idx -ge 0) { $s = $s.Substring($idx + $stderrMarker.Length) }
        $s = $s.Trim()
        if ($s.StartsWith('|')) { $s = $s.Substring(1).TrimStart() }
        if ($s.Length -ge 2 -and $s[0] -eq '"' -and $s[$s.Length - 1] -eq '"') {
            $s = $s.Substring(1, $s.Length - 2)
        }
        return $s.Replace('\r', '').Trim()
    }

    function ExtractEndpoint([string]$url) {
        try {
            $path = ([System.Uri]$url).AbsolutePath
        }
        catch {
            return ''
        }
        $parts = $path.Split('/', [System.StringSplitOptions]::RemoveEmptyEntries)
        if ($parts.Count -eq 0) { return '' }
        $take = [Math]::Min($Depth, $parts.Count)
        return '/' + ($parts[0..($take - 1)] -join '/')
    }

    function BucketFor([string]$ts) {
        if ($Granularity -eq 'second') { return $ts }
        if ($ts.Length -ge 16) { return $ts.Substring(0, 16) }
        return $ts
    }

    function IsoToDebugTs([string]$iso) {
        $m = $isoTsRe.Match($iso)
        if (-not $m.Success) { return $iso }
        return "$($m.Groups[1].Value)/$($m.Groups[2].Value)/$($m.Groups[3].Value) $($m.Groups[4].Value)"
    }

    function TryFinalizeError($entry) {
        $text = $entry.buffer
        $detailM = $detailRe.Match($text)
        if (-not $detailM.Success) { return $null }

        $methodM   = $methodJsonRe.Match($text)
        $instanceM = $instanceRe.Match($text)
        $titleM    = $titleRe.Match($text)
        $statusM   = $statusFieldRe.Match($text)

        $endpoint = ''
        $instanceUrl = ''
        if ($instanceM.Success) {
            $instanceUrl = $instanceM.Groups[1].Value
            if ($instanceUrl.ToLower().Contains('.luna.akamaiapis.net')) {
                $endpoint = ExtractEndpoint $instanceUrl
            }
        }

        $status = $entry.status
        if ($null -eq $status -and $statusM.Success) {
            $status = [int]$statusM.Groups[1].Value
        }

        return [pscustomobject]@{
            timestamp = $entry.timestamp
            status    = if ($null -ne $status) { $status } else { '' }
            method    = if ($methodM.Success) { $methodM.Groups[1].Value } else { '' }
            detail    = $detailM.Groups[1].Value
            title     = if ($titleM.Success) { $titleM.Groups[1].Value } else { '' }
            endpoint  = $endpoint
            instance  = $instanceUrl
        }
    }

    $counts       = @{}
    $pending      = $null
    $lastTs       = $null
    $lastIsoTs    = $null
    $errors       = [System.Collections.Generic.List[object]]::new()
    $errorPending = $null

    try {
        $resolved = (Resolve-Path -LiteralPath $LogPath).ProviderPath
        $reader   = [System.IO.File]::OpenText($resolved)
    }
    catch {
        Write-Host "Failed to open debug log '$LogPath': $_" -ForegroundColor DarkGray
        return
    }

    try {
        while ($null -ne ($rawLine = $reader.ReadLine())) {
            $isoM = $isoTsRe.Match($rawLine)
            if ($isoM.Success) {
                $lastIsoTs = "$($isoM.Groups[1].Value)-$($isoM.Groups[2].Value)-$($isoM.Groups[3].Value)T$($isoM.Groups[4].Value)"
            }

            $piece = CleanPiece $rawLine
            if (-not $piece) { continue }

            $tsMatch = $innerTsRe.Match($piece)
            if ($tsMatch.Success) { $lastTs = $tsMatch.Groups[1].Value }

            $respM = $responseRe.Match($piece)
            $m     = $debugRequestRe.Match($piece)

            if ($null -ne $errorPending -and ($respM.Success -or $m.Success)) {
                $finalized = TryFinalizeError $errorPending
                if ($finalized) { [void]$errors.Add($finalized) }
                $errorPending = $null
            }

            if ($IncludeErrors -and $respM.Success) {
                $statusCode = [int]$respM.Groups[2].Value
                if ($statusCode -ge 400 -and $statusCode -lt 600) {
                    $ts = $respM.Groups[1].Value
                    if (-not $ts) { $ts = $lastTs }
                    if (-not $ts -and $lastIsoTs) { $ts = IsoToDebugTs $lastIsoTs }
                    $errorPending = @{ timestamp = $ts; status = $statusCode; buffer = $piece }
                }
                continue
            }

            if ($null -ne $errorPending -and -not $m.Success) {
                $errorPending.buffer = "$($errorPending.buffer)`n$piece"
                if ($errorPending.buffer.Length -gt $maxBuffer) {
                    $finalized = TryFinalizeError $errorPending
                    if ($finalized) { [void]$errors.Add($finalized) }
                    $errorPending = $null
                }
                continue
            }

            if ($null -ne $pending -and -not $m.Success) {
                $pending.candidate = "$($pending.candidate)$piece"
                $urlMatch = $urlRe.Match($pending.candidate)
                if ($urlMatch.Success) {
                    $url = $urlMatch.Value.TrimEnd('"', ':', ',')
                    if ($url.ToLower().Contains('.luna.akamaiapis.net/')) {
                        $endpoint = ExtractEndpoint $url
                        if ($endpoint -and $pending.timestamp) {
                            $key = "$(BucketFor $pending.timestamp)|$endpoint"
                            if ($counts.ContainsKey($key)) { $counts[$key]++ } else { $counts[$key] = 1 }
                            $pending = $null
                            continue
                        }
                    }
                }
                if ($pending.candidate.Length -gt $maxCandidate) { $pending = $null }
                continue
            }

            if (-not $m.Success) { continue }

            $timestamp = $m.Groups[1].Value
            if (-not $timestamp) { $timestamp = $lastTs }
            $target = $m.Groups[3].Value.Trim()
            $targetLower = $target.ToLower()
            if (-not $targetLower.StartsWith('http://') -and -not $targetLower.StartsWith('https://')) {
                continue
            }

            $urlMatch = $urlRe.Match($target)
            if ($urlMatch.Success) {
                $url = $urlMatch.Value.TrimEnd('"', ':', ',')
                if ($url.ToLower().Contains('.luna.akamaiapis.net/')) {
                    $endpoint = ExtractEndpoint $url
                    if ($endpoint -and $timestamp) {
                        $key = "$(BucketFor $timestamp)|$endpoint"
                        if ($counts.ContainsKey($key)) { $counts[$key]++ } else { $counts[$key] = 1 }
                        $pending = $null
                        continue
                    }
                }
            }

            $pending = @{ timestamp = $timestamp; candidate = $target }
        }
    }
    finally {
        $reader.Dispose()
    }

    if ($null -ne $errorPending) {
        $finalized = TryFinalizeError $errorPending
        if ($finalized) { [void]$errors.Add($finalized) }
    }

    $timeWidth     = if ($Granularity -eq 'second') { 19 } else { 16 }
    $timeLabel     = if ($Granularity -eq 'second') { 'Second' } else { 'Minute' }
    $endpointWidth = 30
    $rowFmt        = "{0,-$timeWidth}  {1,-$endpointWidth}  {2}"

    Write-Host ''
    Write-Host '================================' -ForegroundColor Green
    Write-Host "API Call Rate Summary - $EnvironmentName" -ForegroundColor Green
    Write-Host '================================' -ForegroundColor Green

    if ($counts.Count -eq 0) {
        Write-Host 'No Akamai API calls were recorded in the debug log.' -ForegroundColor DarkGray
    }
    else {
        Write-Host ($rowFmt -f $timeLabel, 'Endpoint prefix', 'Calls') -ForegroundColor Cyan
        Write-Host ($rowFmt -f ('-' * $timeWidth), ('-' * $endpointWidth), '-----') -ForegroundColor Cyan

        foreach ($key in ($counts.Keys | Sort-Object)) {
            $parts = $key -split '\|', 2
            Write-Host ($rowFmt -f $parts[0], $parts[1], $counts[$key])
        }
    }

    if ($IncludeErrors -and $errors.Count -gt 0) {
        $sortedErrors   = $errors | Sort-Object -Property @{Expression = { $_.timestamp }}, @{Expression = { [string]$_.status }}
        $detailWidth    = [Math]::Max(30, ($sortedErrors | ForEach-Object { $_.detail.Length }   | Measure-Object -Maximum).Maximum)
        $endpointWidth2 = [Math]::Max(20, ($sortedErrors | ForEach-Object { $_.endpoint.Length } | Measure-Object -Maximum).Maximum)
        $errFmt         = "{0,-19}  {1,-6}  {2,-6}  {3,-$endpointWidth2}  {4,-$detailWidth}"

        Write-Host ''
        Write-Host 'Errors (HTTP 4xx/5xx):' -ForegroundColor Yellow
        Write-Host ''
        Write-Host ($errFmt -f 'Time (UTC)', 'Status', 'Method', 'Endpoint', 'Detail') -ForegroundColor Cyan
        Write-Host ($errFmt -f ('-' * 19), ('-' * 6), ('-' * 6), ('-' * $endpointWidth2), ('-' * $detailWidth)) -ForegroundColor Cyan
        foreach ($e in $sortedErrors) {
            $tsVal = if ($e.timestamp) { $e.timestamp } else { '' }
            Write-Host ($errFmt -f $tsVal, [string]$e.status, $e.method, $e.endpoint, $e.detail)
        }
    }
}

Export-ModuleMember -Function Enable-TerraformDebugLogging, Disable-TerraformDebugLogging, Write-ExecutionSummary, Write-ApiRateSummary, Get-Username
