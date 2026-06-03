<#
.SYNOPSIS
AI-powered plan interpretation and error diagnosis

.DESCRIPTION
Provides AI-assisted summaries of Terraform plan output and plain-English diagnosis
of Terraform/Akamai API errors.

Requires one of the following environment variables to be set:
  ANTHROPIC_API_KEY  - Uses Claude (default model: claude-3-5-haiku-latest)
  OPENAI_API_KEY     - Uses OpenAI (default model: gpt-4o-mini)

Model overrides:
  ANTHROPIC_MODEL    - Override the Anthropic model (e.g. "claude-opus-4-5")
  OPENAI_MODEL       - Override the OpenAI model   (e.g. "gpt-4o")
#>

# Maximum characters of before/after JSON per resource sent to AI.
# Keeps token usage low while retaining the most meaningful changed fields.
$script:MaxResourceJsonChars = 2000

# Maximum characters of error text sent for diagnosis.
$script:MaxErrorChars = 4000

function Get-AIProvider {
    <#
    .SYNOPSIS
    Returns the active AI provider name, or $null if no API key is configured.
    #>
    [CmdletBinding()]
    param()

    if ($env:ANTHROPIC_API_KEY) { return "anthropic" }
    if ($env:OPENAI_API_KEY)    { return "openai" }
    return $null
}

function Invoke-AIRequest {
    <#
    .SYNOPSIS
    Sends a prompt to the configured AI provider and returns the response text.
    Returns $null on any error (network failure, invalid key, etc.) without throwing.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SystemPrompt,

        [Parameter(Mandatory = $true)]
        [string]$UserPrompt
    )

    $provider = Get-AIProvider
    if (-not $provider) {
        Write-Host "[AI] No API key found. Set ANTHROPIC_API_KEY or OPENAI_API_KEY to use AI features." -ForegroundColor DarkGray
        return $null
    }

    try {
        if ($provider -eq "anthropic") {
            $model = if ($env:ANTHROPIC_MODEL) { $env:ANTHROPIC_MODEL } else { "claude-3-5-haiku-latest" }

            $headers = @{
                "x-api-key"         = $env:ANTHROPIC_API_KEY
                "anthropic-version" = "2023-06-01"
                "Content-Type"      = "application/json"
            }
            $body = @{
                model      = $model
                max_tokens = 1024
                system     = $SystemPrompt
                messages   = @(
                    @{ role = "user"; content = $UserPrompt }
                )
            } | ConvertTo-Json -Depth 10

            $response = Invoke-RestMethod `
                -Uri     "https://api.anthropic.com/v1/messages" `
                -Method  Post `
                -Headers $headers `
                -Body    $body `
                -ErrorAction Stop

            return $response.content[0].text
        }
        elseif ($provider -eq "openai") {
            $model = if ($env:OPENAI_MODEL) { $env:OPENAI_MODEL } else { "gpt-4o-mini" }

            $headers = @{
                "Authorization" = "Bearer $env:OPENAI_API_KEY"
                "Content-Type"  = "application/json"
            }
            $body = @{
                model      = $model
                max_tokens = 1024
                messages   = @(
                    @{ role = "system"; content = $SystemPrompt }
                    @{ role = "user";   content = $UserPrompt   }
                )
            } | ConvertTo-Json -Depth 10

            $response = Invoke-RestMethod `
                -Uri     "https://api.openai.com/v1/chat/completions" `
                -Method  Post `
                -Headers $headers `
                -Body    $body `
                -ErrorAction Stop

            return $response.choices[0].message.content
        }
    }
    catch {
        Write-Warning "[AI] Request failed: $($_.Exception.Message)"
        return $null
    }
}

function Invoke-AIPlanSummary {
    <#
    .SYNOPSIS
    Parses a saved Terraform plan file and prints an AI-generated plain-English
    summary of what will change.

    .PARAMETER TemplateFolder
    The template folder passed to terraform -chdir (e.g. "new-aap-configuration").

    .PARAMETER PlanFile
    Path to the .tfplan file, relative to the TemplateFolder (e.g. "./environments/dev/dev-save.tfplan").
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TemplateFolder,

        [Parameter(Mandatory = $true)]
        [string]$PlanFile
    )

    if (-not (Get-AIProvider)) { return }

    Write-Host "`nGenerating AI plan summary..." -ForegroundColor Magenta

    # Convert the binary plan to structured JSON
    $planJson = terraform -chdir="./$TemplateFolder" show -json $PlanFile 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $planJson) {
        Write-Warning "[AI] Could not read plan file as JSON — skipping summary."
        return
    }

    try {
        $plan = $planJson | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        Write-Warning "[AI] Failed to parse plan JSON — skipping summary."
        return
    }

    # Filter to resources that will actually change
    $actionableChanges = @("create", "update", "delete", "replace")
    $changes = $plan.resource_changes | Where-Object {
        $_.change -and $_.change.actions -and
        ($_.change.actions | Where-Object { $actionableChanges -contains $_ })
    }

    if (-not $changes -or @($changes).Count -eq 0) {
        Write-Host "`n[AI] Plan contains no resource changes." -ForegroundColor Green
        return
    }

    # Build a compact, token-efficient representation for the AI
    $changeSummaryLines = foreach ($c in $changes) {
        $action = $c.change.actions -join "/"

        $before = if ($c.change.before) {
            $raw = $c.change.before | ConvertTo-Json -Depth 4 -Compress
            if ($raw.Length -gt $script:MaxResourceJsonChars) {
                $raw.Substring(0, $script:MaxResourceJsonChars) + "... [truncated]"
            } else { $raw }
        } else { "null" }

        $after = if ($c.change.after) {
            $raw = $c.change.after | ConvertTo-Json -Depth 4 -Compress
            if ($raw.Length -gt $script:MaxResourceJsonChars) {
                $raw.Substring(0, $script:MaxResourceJsonChars) + "... [truncated]"
            } else { $raw }
        } else { "null" }

        "Resource : $($c.address)`nAction   : $action`nBefore   : $before`nAfter    : $after`n"
    }

    $changeSummary = $changeSummaryLines -join "`n"

    $systemPrompt = @"
You are an expert on Akamai's Terraform provider (akamai/akamai). You receive a list of planned Terraform resource changes for Akamai security (AAP / AAP+ASM) or delivery (Property Manager) configurations.

Summarize every changed resource in plain English — one bullet point per resource. Be specific: include policy names, old values, and new values where present. Omit resources with only metadata changes (tags, notes). Highlight any activation or destruction.

Akamai resource types to know:
- akamai_appsec_rate_policy          → rate-limiting rule (threshold in req/s or req/10s)
- akamai_appsec_waf_mode             → WAF protection mode (KRS = rule-set, ASE = adaptive)
- akamai_appsec_slow_post_protection → slow POST attack mitigation
- akamai_appsec_reputation_profile   → IP reputation-based blocking
- akamai_appsec_activations          → security config activation to staging/production
- akamai_property                    → delivery configuration (hostnames, caching rules)
- akamai_property_activation         → property activation to staging/production
- akamai_dns_record                  → Edge DNS record

Format each bullet as:
• <plain resource description>: <what changes> (<old> → <new> when values differ)
"@

    $userPrompt = "Summarize these Terraform plan changes:`n`n$changeSummary"

    $summary = Invoke-AIRequest -SystemPrompt $systemPrompt -UserPrompt $userPrompt
    if ($summary) {
        $border = "─" * 56
        Write-Host ""
        Write-Host "┌─ AI Plan Summary $border" -ForegroundColor Magenta
        $summary -split "`n" | ForEach-Object { Write-Host "│  $_" -ForegroundColor White }
        Write-Host "└$border──────────────────`n" -ForegroundColor Magenta
    }
}

function Invoke-AIErrorDiagnosis {
    <#
    .SYNOPSIS
    Sends Terraform/Akamai error output to AI and prints a plain-English
    diagnosis with a recommended fix.

    .PARAMETER ErrorText
    Raw error text captured from a failed terraform plan or apply.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ErrorText
    )

    if (-not (Get-AIProvider)) { return }
    if ([string]::IsNullOrWhiteSpace($ErrorText)) { return }

    Write-Host "`nRunning AI error diagnosis..." -ForegroundColor Red

    # Focus on the error-bearing lines to stay within token budget
    $errorLines = ($ErrorText -split "`n" | Where-Object { $_ -match "Error|╷|│|╵|Warning" }) -join "`n"
    $diagText   = if ($errorLines.Length -gt 0) { $errorLines } else { $ErrorText }

    # Use the tail of the error if it is very long (most relevant content is at the end)
    if ($diagText.Length -gt $script:MaxErrorChars) {
        $diagText = $diagText.Substring($diagText.Length - $script:MaxErrorChars)
    }

    $systemPrompt = @"
You are an expert on Akamai's Terraform provider (akamai/akamai) and Akamai APIs.

Given a Terraform or Akamai API error, respond with exactly three short sections:

1. **What happened** (1-2 sentences — plain English, no jargon)
2. **Root cause** (1-2 sentences — why it happened)
3. **Fix** (specific action(s) to resolve the issue — be concrete)

Reference exact values from the error (policy names, IDs, field names) when relevant.
"@

    $userPrompt = "Diagnose this error and tell me how to fix it:`n`n$diagText"

    $diagnosis = Invoke-AIRequest -SystemPrompt $systemPrompt -UserPrompt $userPrompt
    if ($diagnosis) {
        $border = "─" * 54
        Write-Host ""
        Write-Host "┌─ AI Error Diagnosis $border" -ForegroundColor Red
        $diagnosis -split "`n" | ForEach-Object { Write-Host "│  $_" -ForegroundColor White }
        Write-Host "└$border────────────────────`n" -ForegroundColor Red
    }
}

Export-ModuleMember -Function Get-AIProvider, Invoke-AIPlanSummary, Invoke-AIErrorDiagnosis
