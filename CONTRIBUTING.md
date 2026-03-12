# Contributing

When contributing to this repository, please first discuss the change you wish to make via issue preferably a GitHub Issue, email, or any other method with the owners of this repository before making a change.

## Table of Contents

- [Prerequisites](#prerequisites)
  - [Setup Pre-Commit Hooks](#setup-pre-commit-hooks)
- [Repository Architecture](#repository-architecture)
  - [Modular Design](#modular-design)
  - [Directory Structure](#directory-structure)
- [Development Workflow](#development-workflow)
  - [1. Create Feature Branch](#1-create-feature-branch)
  - [2. Make Changes](#2-make-changes)
  - [3. Commit with Conventional Commits](#3-commit-with-conventional-commits)
  - [4. Push and Create Pull Request](#4-push-and-create-pull-request)
  - [5. Integration Testing](#5-integration-testing)
  - [6. Promote to Production](#6-promote-to-production)
  - [Hotfix Workflow](#hotfix-workflow)
- [GitHub Workflows](#github-workflows)
  - [1. PR Validation](#1-pr-validation-githubworkflowspr-validationyml)
  - [2. Terraform Docs Automation](#2-terraform-docs-automation-githubworkflowstf-docsyml)
  - [3. Release Automation](#3-release-automation-githubworkflowsreleaseyml)
  - [Setting Up Required Secrets](#setting-up-required-secrets)
- [Branching Strategy](#branching-strategy)
  - [Branch Purposes](#branch-purposes)
  - [Branch Protection Rules](#branch-protection-rules)
  - [Branch Naming Convention](#branch-naming-convention)
- [Commit Conventions](#commit-conventions)
  - [Format](#format)
  - [Types](#types)
  - [Breaking Changes](#breaking-changes)
  - [Scopes (Optional)](#scopes-optional)
  - [Examples](#examples)
- [Pull Request Process](#pull-request-process)
  - [Creating a Pull Request](#creating-a-pull-request)
  - [PR Checklist](#pr-checklist)
- [Module Versioning](#module-versioning)
  - [Using Modules in Templates](#using-modules-in-templates)
  - [Updating Module Versions](#updating-module-versions)
- [Testing](#testing)
  - [Local Testing](#local-testing)
  - [Debug Mode](#debug-mode)
  - [Terraform Commands](#terraform-commands)
- [Versioning and Changelog](#versioning-and-changelog)
  - [Automated Process](#automated-process)
  - [Manual Override (Emergency Only)](#manual-override-emergency-only)

## Prerequisites

**Required:**
* [Terraform >= 1.9.0](https://developer.hashicorp.com/terraform/downloads?product_intent=terraform)
* [PowerShell 7+](https://github.com/PowerShell/PowerShell) (not Windows PowerShell 5.1)
* [Akamai PowerShell v2+](https://techdocs.akamai.com/powershell/docs/overview) - For testing with `deploy.ps1`
* [`pre-commit`](https://pre-commit.com/) - Pre-commit hook framework
* [`terraform-docs`](https://terraform-docs.io/) - Auto-generates module documentation
* [`tflint`](https://github.com/terraform-linters/tflint) - Terraform linting
* [`trivy`](https://github.com/aquasecurity/trivy) - Security scanning

### Setup Pre-Commit Hooks

**You must install pre-commit hooks** to ensure code quality before committing:

```bash
pre-commit install
```

This installs hooks for both `pre-commit` and `commit-msg` stages:
- **Pre-commit stage**: Formats code, generates docs, runs linting
- **Commit-msg stage**: Validates conventional commit message format

To manually run all checks:

```bash
pre-commit run --all-files   
```

**Why required?** The hooks enforce:
- Code formatting (`terraform fmt`)
- Up-to-date documentation (`terraform-docs`)
- Linting best practices (`tflint`)
- Security scanning (`trivy`)
- **Conventional commit message format** - Validates at commit time before you push
- The PR validation workflow will **fail** if any of the above checks are caught

Pre-commit hooks catch these issues locally before the PR validation workflow runs. 

## Repository Architecture

### Modular Design

This repository uses a **modular PowerShell architecture** to manage Terraform deployments. The `deploy.ps1` script orchestrates template-specific handlers through a clean separation of concerns:

**Core Components:**
- **`lib/core/`** - Shared functionality used across all templates
  - `TerraformRunner.psm1` - Terraform execution wrapper (init, plan, apply, destroy)
  - `Validation.psm1` - Product ID validation and tfvars parsing
  - `Logger.psm1` - Logging and output formatting

- **`lib/templates/`** - Template-specific handlers (one per template type)
  - `AAP.psm1` - App & API Protector configuration handler
  - `AAPASM.psm1` - AAP + Advanced Security Management handler  
  - `PropertyManager.psm1` - Property Manager configuration handler
  - `CPS.psm1` - Certificate Provisioning System handler

- **`deploy.ps1`** - Main orchestration script
  - Maps template types to handlers via hashtables
  - Loads appropriate template module dynamically
  - Delegates all template-specific logic to modules

**Design Principles:**
- **Separation of Concerns** - Template-specific quirks isolated in template modules
- **DRY (Don't Repeat Yourself)** - Common Terraform operations in core modules
- **Extensibility** - Add new templates by creating a new template module
- **Testability** - Each module can be tested independently

### Directory Structure

```
terraform-templates/
├── deploy.ps1                    # Main orchestration script
├── lib/                          # PowerShell module library
│   ├── core/                     # Shared functionality
│   │   ├── TerraformRunner.psm1  # Terraform execution wrapper
│   │   ├── Validation.psm1       # Product/tfvars validation
│   │   └── Logger.psm1           # Logging utilities
│   └── templates/                # Template-specific handlers
│       ├── AAP.psm1              # AAP template handler
│       ├── AAPASM.psm1           # AAP+ASM template handler
│       ├── PropertyManager.psm1  # Property Manager handler
│       └── CPS.psm1              # CPS handler
├── tests/
│   ├── deploy.Tests.ps1          # Deploy script tests
│   └── lib-modules.Tests.ps1     # Module unit tests
├── new-aap-configuration/        # AAP template files
├── new-aapasm-configuration/     # AAP+ASM template files
├── new-property/                 # Property Manager template files
└── new-*-cert/                   # CPS certificate templates
```

## Development Workflow

### 1. Create Feature Branch

Always branch from `integration`, not `main`. See [Branch Naming Convention](#branch-naming-convention) for required format.

```bash
git checkout integration
git pull origin integration
git checkout -b feat/add-custom-rate-policies
```

### 2. Make Changes

- Follow Terraform best practices
- Update the tests suites accordingly (new templates, deployment script)
- Include new templates in the Github Workflows if needed:
   - terraform validate
   - tflint
   - terraform-docs
- Update documentation:
   - `main.tf` comments 
   - `.tfvars.dist` examples
   - Include new templates in the `.pre-commit-config.yaml`
- Test locally using `deploy.ps1`
- Pre-commit hooks will auto-run on `git commit` (formats code, updates `README.md`)
   - Or run manually: `pre-commit run --all-files`

#### Adding New Templates

To add a new template type (e.g., EdgeWorkers, ImageManager):

1. **Create template module** in `lib/templates/`:
   ```powershell
   # lib/templates/EdgeWorkers.psm1
   using module ../core/TerraformRunner.psm1
   using module ../core/Validation.psm1
   using module ../core/Logger.psm1

   class EdgeWorkersTemplate {
       [string]$TemplateName
       [string]$Environment
       [string]$TemplateFolder
       
       EdgeWorkersTemplate([string]$env, [string]$folder) {
           $this.TemplateName = "EdgeWorkers"
           $this.Environment = $env
           $this.TemplateFolder = $folder
       }
       
       [void]ValidatePrerequisites([hashtable]$params) {
           # Validation logic
       }
       
       [hashtable]BuildTerraformVars([hashtable]$params) {
           # Build runtime variables
           return @{}
       }
       
       [void]Deploy([hashtable]$params) {
           # Deploy logic using core modules
       }
       
       [void]Destroy([hashtable]$params) {
           # Destroy logic
       }
   }
   
   Export-ModuleMember -Variable EdgeWorkersTemplate
   ```

2. **Update deploy.ps1**:
   - Add to `ValidateSet` in `TemplateType` parameter
   - Add to `$templateModuleMap` hashtable
   - Add to `$templateFolderMap` hashtable
   - Add switch case in template routing section

3. **Create tests** in `tests/lib-modules.Tests.ps1`:
   ```powershell
   Describe "Template Module - EdgeWorkers" {
       It "Should load EdgeWorkers template module" {
           { Import-Module "$RepoRoot/lib/templates/EdgeWorkers.psm1" -Force } | Should -Not -Throw
       }
   }
   ```

4. **Update documentation**:
   - Update this file (CONTRIBUTING.md) if needed
   - Add template-specific guidance to README.md
   - Create migration examples

### 3. Commit with Conventional Commits

See [Commit Conventions](#commit-conventions) for required format.

```bash
git add .
git commit -m "feat(aap): add support for custom rate policies"
```

### 4. Push and Create Pull Request

```bash
git push origin feat/add-custom-rate-policies
```

Open PR against **`integration`** branch (not `main`). This triggers the **PR Validation workflow**. See [Pull Request Process](#pull-request-process) below.

### 5. Integration Testing

After PR is merged to `integration`:
- **Terraform Docs workflow auto-runs** - Updates template `README.md` files automatically
- Test the integrated changes thoroughly
- Verify multiple templates work together
- Confirm module version compatibility
- Template `README.md` files should now reflect latest changes (auto-committed by workflow)

### 6. Promote to Production

When ready for release, create PR from `integration` to `main`. Once merged, this triggers the **Release Automation workflow** which:
- Analyzes commits and determines version bump
- Updates `VERSION` file and `CHANGELOG.md`
- Creates Git tag and GitHub release

### Hotfix Workflow

Use this workflow when a **critical bug in production** needs to be fixed immediately, without waiting for changes currently in `integration` to be ready.

```
hotfix/* branch → main (release automation) → integration (backmerge, no CI)
```

**Steps:**

1. **Cut the hotfix branch from `main`** (not `integration`):
   ```bash
   git checkout main
   git pull origin main
   git checkout -b hotfix/fix-critical-issue
   ```

2. **Apply the fix and commit** using a `fix:` conventional commit:
   ```bash
   git commit -am "fix: resolve critical issue in rate policy"
   git push origin hotfix/fix-critical-issue
   ```

3. **Open a PR from `hotfix/*` → `main`**:
   - The `main-branch-protection` workflow validates the source is `hotfix/*` ✓
   - PR validation and tf-docs do **not** run (they only trigger on PRs/pushes to `integration`)
   - Once approved, merge the PR
   - This triggers the **Release Automation workflow** (patch version bump) ✓

4. **Backmerge `main` into `integration`** to keep branches in sync:
   ```bash
   git checkout integration
   git pull origin integration
   git merge main           # or: git merge origin/main
   # resolve any conflicts if needed
   git push origin integration
   ```

   > Both `git merge main` (local ref) and `git merge origin/main` (remote-tracking ref) are supported. The tf-docs workflow is configured to skip on both resulting commit message formats.

5. **Verify `integration` is up to date** — no CI workflows will re-run for this backmerge:
   - `pr-validation` is skipped (no PR opened against `integration`)
   - `tf-docs` is skipped (commit message matches the `main` → `integration` backmerge pattern)

## GitHub Workflows

This repository uses **three automated workflows** that execute in sequence:

### 1. PR Validation (`.github/workflows/pr-validation.yml`)

**Trigger:** Pull requests to `integration` branch

**Purpose:** Validate code quality and security before merging

**Note:** This workflow is **automatically skipped** when the source branch is `main` (i.e., during a hotfix backmerge PR). The code already passed production standards via the hotfix PR to `main`.

**Runs:**
1. **Terraform Format Check** - Ensures consistent formatting
2. **Terraform Validate** - Tests all templates (AAP, AAP+ASM, Property, etc)
3. **TFLint** - Static analysis for best practices
4. **Trivy Security Scan** - Identifies vulnerabilities (uploads to GitHub Security tab)
5. **Deployment Tests** - Tests for the `deploy.ps1` script

**Required Secrets:**
- `DEPLOY_KEY` - SSH private key for accessing private module repository

**Note:** This workflow does NOT modify code. All checks are read-only validation.

### 2. Terraform Docs Automation (`.github/workflows/tf-docs.yml`)

**Trigger:** Pushes to `integration` branch (i.e., when PRs are merged)

**Purpose:** Auto-generate and commit updated `README.md` files for all templates

**Runs (example):**
1. **Generate terraform-docs for AAP Configuration** - Updates `new-aap-configuration/README.md`
2. **Generate terraform-docs for AAP/ASM Configuration** - Updates `new-aapasm-configuration/README.md`
3. **Generate terraform-docs for Property** - Updates `new-property/README.md`
4. **Auto-commit** - Pushes updated `README.md` files back to `integration` branch

**Note:** This workflow runs AFTER merge to `integration`, ensuring documentation stays in sync with code changes. It is **automatically skipped** when the push is a backmerge from `main`, covering both standard merge message formats (`Merge branch 'main'` from `git merge main` and `Merge remote-tracking branch 'origin/main'` from `git merge origin/main`), preventing unnecessary doc regeneration during hotfix backmerges.

### 3. Release Automation (`.github/workflows/release.yml`)

**Trigger:** Merges to `main` or `master` branch

**Purpose:** Create versioned releases with changelog and tags

**Runs:**
1. Analyzes conventional commits since last tag
2. Determines version bump (major/minor/patch)
3. Updates `VERSION` file
4. Generates/updates `CHANGELOG.md`
5. Commits changes with `[skip ci]` to prevent loops
6. Creates Git tag (e.g. `v1.2.3`)
7. Publishes GitHub release with extracted release notes

**Version Bump Logic:**
- Commits with `BREAKING CHANGE:` footer → **Major** (1.0.0 → 2.0.0)
- `feat:` or `feature:` → **Minor** (1.0.0 → 1.1.0)
- `fix:` or `bugfix:` → **Patch** (1.0.0 → 1.0.1)

### Setting Up Required Secrets

#### DEPLOY_KEY for Private Modules

For Terraform to access the `terraform-templates-modules` repository SSH access is required. See for example the module reference in the `new-aap-configuration/main.tf`:
```
source = "git::ssh://git@github.com/akamai/terraform-templates-modules.git//aap/security?ref=v1.2.3"
```

Setup SSH for GitHub module access:

1. Generate SSH key pair (no passphrase):
   ```bash
   ssh-keygen -t rsa -b 4096 -C "github-actions" -f deploy_key
   ```

2. Add **public key** (`deploy_key.pub`) to module repository:
   - Go to module repo → Settings → Deploy keys
   - Add key with read-only access

3. Add **private key** (`deploy_key`) to this repository:
   - Settings → Secrets and variables → Actions
   - New repository secret: `DEPLOY_KEY`

## Branching Strategy

This repository uses a **three-stage branching model** with automated CI/CD:

```
feature branch → integration (PR validation + auto-docs) → main (release automation)
                                                               ↑
                             hotfix/* branch ─────────────────┘
                             (then backmerged to integration with no CI)
```

### Branch Purposes

| Branch | Purpose | Triggers |
|--------|---------|----------|
| **Feature branches** | Active development work | Nothing |
| **`integration`** | Pre-release testing and validation | **PR validation workflow** (on PR) + **Terraform Docs workflow** (on merge) |
| **`hotfix/*`** | Critical production fixes bypassing `integration` | **Main branch protection** (PR to `main`) + **Release automation** (on merge to `main`) |
| **`main`/`master`** | Production-ready code | **Release automation workflow** |

### Branch Protection Rules

**Required for `integration` branch:**
- Require pull request reviews before merging
- Require status checks to pass (PR validation workflow)
- Require branches to be up to date before merging

**Required for `main` branch:**
- All of the above, plus:
- Restrict push access (only allow merges from `integration`)
- Require linear history (squash or rebase merges)

### Branch Naming Convention

Use descriptive branch names that match [commit types](#commit-conventions) for consistency:

**Format:** `<type>/<short-description>` or `<type>/<issue>-<short-description>`

**Examples:**
```bash
# New features
feat/custom-rate-policies
feat/DOHRMY-126-botman-integration

# Bug fixes
fix/rate-policy-import
fix/DOHRMY-456-state-file-conflict

# Hotfixes (critical production fixes - branched from main)
hotfix/fix-rate-policy-conflict
hotfix/DOHRMY-789-critical-security-patch

# Documentation
docs/update-readme-examples

# Refactoring
refactor/module-structure

# Chores
chore/new-release-version
```

**Guidelines:**
- Use lowercase with hyphens (kebab-case)
- Be descriptive but concise (3-5 words max)
- Include issue/ticket number when applicable
- Match the commit type you'll use later
- Avoid special characters except hyphens and forward slashes

## Commit Conventions

This repository follows [Conventional Commits](https://www.conventionalcommits.org/) for automated changelog generation.

### Format

```
<type>(<scope>): <subject>
```

### Types

| Type | Purpose | Version Bump | Example |
|------|---------|--------------|---------|
| `feat:` | New features | Minor (1.0.0→1.1.0) | `feat(aap): add custom rate policies` |
| `fix:` | Bug fixes | Patch (1.0.0→1.0.1) | `fix(asm): correct match target config` |
| `docs:` | Documentation | None | `docs: update README examples` |
| `refactor:` | Code restructuring | None | `refactor: simplify module calls` |
| `chore:` | Maintenance | None (skipped) | `chore: update dependencies` |
| `test:` | Add or Update Tests | None | `test: deployment script` |

### Breaking Changes

To trigger a **major version bump**, include `BREAKING CHANGE:` in the commit body:

```bash
# Breaking change with body footer (triggers major bump)
git commit -m "feat: upgrade Akamai provider

BREAKING CHANGE: Provider v9.0 requires Terraform >= 1.9.0"

# Alternative multi-line format
git commit -m "feat: require PowerShell 7+" -m "BREAKING CHANGE: PowerShell 5.1 no longer supported"
```

**Note:** The `feat!:` syntax is NOT supported by the changelog action. Always use the `BREAKING CHANGE:` footer.

### Scopes (Optional)

Use scopes to indicate which template is affected:
- `(aap)` - App & API Protector template
- `(aapasm)` - AAP+ASM template  
- `(pm)` - Property Manager template
- `(deploy)` - deploy.ps1 script
- `(ci)` - CI/CD workflows
- `(docs)`: Documentation

### Examples

```bash
# Feature (minor bump)
git commit -m "feat(aap): add support for custom rate policies"

# Bug fix (patch bump)
git commit -m "fix(asm): correct match target configuration"

# Breaking change (major bump) - requires BREAKING CHANGE footer
git commit -m "feat: upgrade to Terraform 1.9" -m "BREAKING CHANGE: Terraform 1.8 no longer supported"

# Documentation (no version bump)
git commit -m "docs: update README with new examples"

# Chore (no version bump, excluded from changelog)
git commit -m "chore: update dependencies"
```

## Pull Request Process

### Creating a Pull Request

1. **Fork the project** (for external contributors) or create branch (for team members)

2. **Create feature branch from `integration`**:
   ```bash
   git checkout -b feat/your-feature-name integration
   ```

3. **Make your changes**:
   - Update code/templates
   - Update documentation (`main.tf`, `.tfvars.dist`)
   - Test with: `pwsh deploy.ps1 <template> -Env dev -Save -Dry`
   - Pre-commit hooks will run on commit (or manually: `pre-commit run --all-files`)

4. **Commit with conventional format**:
   ```bash
   git commit -m "feat(aap): add new feature"
   ```

5. **Push to remote**:
   ```bash
   git push origin feat/your-feature-name
   ```

6. **Create PR against `integration`**:
   ```bash
   # Option 1: Open repo in browser - GitHub will show "Compare & pull request" banner
   open https://github.com/jaescalo/terraform-templates/pulls
   
   # Option 2: Use GitHub CLI (requires 'gh' installed)
   gh pr create --base integration --title "feat(aap): add new feature" --body "Description of changes"
   ```

7. **Wait for PR validation to pass** - All checks must be green

8. **Address review feedback** if requested

8. **Merge to integration** - Test thoroughly

9. **Create PR from `integration` to `main`** when ready for release

### PR Checklist

Before submitting, ensure:

- [ ] Pre-commit hooks installed and run successfully
- [ ] Conventional commit format used (at least one semantic commit)
- [ ] Documentation updated (`main.tf`, inline comments, `.tfvars.dist`)
- [ ] Tested with `deploy.ps1` for affected templates
- [ ] Test suite/scenarios updated or created for the affected templates
- [ ] Module version references are pinned (never use `ref=main`)
- [ ] PR validation workflow passes (all checks green)

**Note:** Template `README.md` files are auto-generated by the Terraform Docs workflow after merge to `integration`, so you don't need to update them manually.

**Note:** If PR validation fails on formatting/docs, run `pre-commit run --all-files` locally and push the fixes.

## Module Versioning

### Using Modules in Templates

Always pin modules to specific versions using Git tags:

```hcl
module "security" {
  source = "git::ssh://git@github.com/akamai/terraform-templates-modules.git//aap/security?ref=v1.1.1"
  # ...
}
```

**Never use:** `ref=main` or `ref=master` in production templates.

### Updating Module Versions

When module repository changes (it follows the same release process):

1. **Update template references** in this repository:
   ```bash
   # Update all module source refs in affected templates
   # Example: new-aap-configuration/main.tf
   source = "git::ssh://...//aap/security?ref=v1.2.0"
   ```

3. **Test changes**:
   ```bash
   pwsh deploy.ps1 aap -Env dev -Save -Dry
   ```

3. **Commit with semantic message**:
   ```bash
   git commit -m "feat: upgrade security module to v1.2.0"
   ```

## Testing

### Module Testing

Run Pester tests for the modular architecture:

```bash
# Install Pester if not already installed
Install-Module -Name Pester -Force -SkipPublisherCheck

# Run all tests
pwsh -Command "Invoke-Pester -Path ./tests/"

# Run specific test file
pwsh -Command "Invoke-Pester -Path ./tests/lib-modules.Tests.ps1"

# Run with detailed output
pwsh -Command "Invoke-Pester -Path ./tests/lib-modules.Tests.ps1 -Output Detailed"
```

**Test Coverage:**
- Core module loading (`TerraformRunner.psm1`, `Validation.psm1`, `Logger.psm1`)
- Template module loading (AAP, AAPASM, PropertyManager, CPS)
- Function exports and imports
- Integration with `deploy.ps1`

### Local Testing

Before submitting PR, test your changes:

```bash
pwsh deploy.ps1 <template> -Env dev -Save

# or

# Dry-run (plan only, no changes)
pwsh deploy.ps1 <template> -Env dev -Save -Dry

# Examples:
pwsh deploy.ps1 aap -Env dev -Save -Dry
pwsh deploy.ps1 aapasm -Env qa -Save -Dry
pwsh deploy.ps1 pm -Env dev -Save -Dry
```

### Debug Mode

Enable detailed logging for troubleshooting:

```bash
pwsh deploy.ps1 aap -Env dev -Save -Debug
# Logs saved to: ./new-aap-configuration/environments/dev/dev-akamai_tf.log
```

### Terraform Commands

While `deploy.ps1` is the primary interface, you can run Terraform directly for debugging:

```bash
cd new-aap-configuration
terraform init -backend-config="./environments/dev/config.backend"
terraform plan -var-file="./environments/dev/dev.tfvars"
```

**Note:** Direct Terraform usage bypasses state isolation and retry logic.

## Versioning and Changelog

### Automated Process

With the release workflow, versioning is **fully automated**:
- ✅ Commits analyzed for semantic prefixes
- ✅ `VERSION` file auto-updated on `main` branch
- ✅ `CHANGELOG.md` auto-generated with categorized entries
- ✅ Git tags created automatically
- ✅ GitHub releases published

**No manual changelog or version updates needed!**

**Note:** `VERSION` and `CHANGELOG.md` files in the `integration` branch may be outdated. The `main` branch is the single source of truth for releases. Always check the latest tag or `main` branch to see the current version.

### Manual Override (Emergency Only)

If automation fails, manually update:

1. **VERSION file** - Single line with semantic version
2. **CHANGELOG.md** - Add entry following existing format
3. **Git tag** - Create and push tag matching VERSION

## Questions or Issues?

- Open an issue: [GitHub Issues](https://github.com/akamai/terraform-templates/issues)

---

Thank you for contributing to the Terraform Templates!
