<#
.SYNOPSIS
AI-powered plan interpretation and error diagnosis

.DESCRIPTION
Provides AI-assisted summaries of Terraform plan output and plain-English diagnosis
of Terraform/Akamai API errors.

Provider selection (first match wins):
  TF_AI_ENDPOINT     - URL of a shared Fermyon/Akamai-Functions proxy (preferred).
                       Optional bearer token via TF_AI_TOKEN.
  ANTHROPIC_API_KEY  - Uses Claude directly (default model: claude-3-5-haiku-latest)
  OPENAI_API_KEY     - Uses OpenAI directly (default model: gpt-4o-mini)

Model overrides:
  ANTHROPIC_MODEL    - Override the Anthropic model (e.g. "claude-opus-4-5")
  OPENAI_MODEL       - Override the OpenAI model   (e.g. "gpt-4o")
#>

# Maximum characters of the human-readable `terraform show <plan>` output sent to AI.
# Property Manager rule trees can be large; 60k chars ≈ ~15k input tokens, comfortably
# within gpt-4o-mini / claude-haiku context windows and a few tenths of a cent per call.
$script:MaxPlanTextChars = 60000

# Maximum characters of error text sent for diagnosis.
$script:MaxErrorChars = 4000

function Get-AIProvider {
    <#
    .SYNOPSIS
    Returns the active AI provider name, or $null if no provider is configured.
    Order of preference: proxy → anthropic → openai.
    #>
    [CmdletBinding()]
    param()

    if ($env:TF_AI_ENDPOINT)    { return "proxy" }
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
        Write-Host "[AI] No provider configured. Set TF_AI_ENDPOINT, ANTHROPIC_API_KEY, or OPENAI_API_KEY." -ForegroundColor DarkGray
        return $null
    }

    try {
        if ($provider -eq "proxy") {
            $endpoint = $env:TF_AI_ENDPOINT.TrimEnd('/')
            $uri      = "$endpoint/v1/ai/chat"

            $headers = @{ "Content-Type" = "application/json" }
            if ($env:TF_AI_TOKEN) {
                $headers["Authorization"] = "Bearer $env:TF_AI_TOKEN"
            }

            $body = @{
                system     = $SystemPrompt
                user       = $UserPrompt
                max_tokens = 1024
            } | ConvertTo-Json -Depth 10

            $response = Invoke-RestMethod `
                -Uri     $uri `
                -Method  Post `
                -Headers $headers `
                -Body    $body `
                -ErrorAction Stop

            return $response.text
        }
        elseif ($provider -eq "anthropic") {
            $model = if ($env:ANTHROPIC_MODEL) { $env:ANTHROPIC_MODEL } else { "claude-sonnet-4-6" }

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

    if (-not (Get-AIProvider)) {
        Write-Host "[AI] No provider configured. Set TF_AI_ENDPOINT, ANTHROPIC_API_KEY, or OPENAI_API_KEY to enable AI features." -ForegroundColor DarkYellow
        return
    }

    Write-Host "`nGenerating AI plan summary..." -ForegroundColor Magenta

    # Resolve PlanFile to an absolute path so terraform -chdir interprets it correctly.
    # (Without this, terraform looks for the path *relative to the chdir target*, not cwd.)
    $resolvedPlan = $PlanFile
    if (Test-Path $PlanFile) {
        $resolvedPlan = (Resolve-Path $PlanFile).Path
    }

    # Step 1: parse JSON once — only to decide whether there are any actionable changes
    # at all. Avoids spending tokens on a no-op plan.
    $planJson = terraform -chdir="./$TemplateFolder" show -json $resolvedPlan 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $planJson) {
        Write-Warning "[AI] Could not read plan file as JSON — skipping summary. (Tried: $resolvedPlan)"
        return
    }

    try {
        $plan = $planJson | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        Write-Warning "[AI] Failed to parse plan JSON — skipping summary."
        return
    }

    $actionableChanges = @("create", "update", "delete", "replace")
    $changes = $plan.resource_changes | Where-Object {
        $_.change -and $_.change.actions -and
        ($_.change.actions | Where-Object { $actionableChanges -contains $_ })
    }

    if (-not $changes -or @($changes).Count -eq 0) {
        Write-Host "`n[AI] Plan contains no resource changes." -ForegroundColor Green
        return
    }

    # Step 2: capture the human-readable plan text. Terraform's text view uses +/-/~
    # markers that LLMs interpret natively and stays compact even for nested rule trees
    # — unlike compact JSON which obscures nested additions when truncated.
    $planTextLines = terraform -chdir="./$TemplateFolder" show $resolvedPlan 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $planTextLines) {
        Write-Warning "[AI] Could not read plan file as text — skipping summary."
        return
    }

    $planText = $planTextLines -join "`n"
    if ($planText.Length -gt $script:MaxPlanTextChars) {
        # Keep the tail — it contains the resource diffs and the final "Plan: N to add..." line.
        $planText = "... [plan truncated; showing last $($script:MaxPlanTextChars) chars] ...`n" +
                    $planText.Substring($planText.Length - $script:MaxPlanTextChars)
    }

    $systemPrompt = @"
You are an expert on Akamai's Terraform provider (akamai/akamai). You are given the human-readable output of `terraform show <planfile>` for an Akamai security (AAP / AAP+ASM) or delivery (Property Manager) configuration.

Diff markers in the input:
  +  resource or field being ADDED
  -  resource or field being REMOVED
  ~  field being CHANGED in place

Produce a concise, accurate bullet-point summary. One bullet per meaningful change. Examine ADDED blocks carefully — they often contain new origin rules, new behaviors, new hostnames, or new policies nested deep inside Property Manager rule trees. Do not dismiss them as "metadata" if they introduce real configuration.

For each bullet, include:
  • the resource type and name
  • what specifically is changing (rule name, behavior name, hostname, threshold, etc.)
  • old → new values when both are present

Akamai resource types to know:
- akamai_appsec_rate_policy          → rate-limiting rule (threshold in req/s or req/10s)
- akamai_appsec_waf_mode             → WAF protection mode (KRS = rule-set, ASE = adaptive)
- akamai_appsec_slow_post_protection → slow POST attack mitigation
- akamai_appsec_reputation_profile   → IP reputation-based blocking
- akamai_appsec_activations          → security config activation to staging/production
- akamai_property                    → delivery configuration (rules JSON contains nested children with behaviors like `origin`, `caching`, `cpCode`)
- akamai_property_activation         → property activation to staging/production
- akamai_dns_record                  → Edge DNS record

For `akamai_property` updates, the `rules` attribute is a jsonencode() blob — inspect nested `+ {` blocks inside `children = [...]` arrays for newly added rules or origins, and report each one (rule name, hostname behavior target, criteria).
"@

    $userPrompt = "Summarize this Terraform plan output:`n`n$planText"

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

    if (-not (Get-AIProvider)) {
        Write-Host "[AI] No provider configured. Set TF_AI_ENDPOINT, ANTHROPIC_API_KEY, or OPENAI_API_KEY to enable AI features." -ForegroundColor DarkYellow
        return
    }
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
