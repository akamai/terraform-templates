# Conventional Commits Guide

This repository uses [Conventional Commits](https://www.conventionalcommits.org/) for automated changelog generation and versioning.

## Commit Message Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

## Types

- **feat**: A new feature (triggers MINOR version bump)
- **fix**: A bug fix (triggers PATCH version bump)
- **docs**: Documentation only changes
- **style**: Changes that don't affect code meaning (formatting, etc.)
- **refactor**: Code change that neither fixes a bug nor adds a feature
- **perf**: Performance improvements
- **test**: Adding or updating tests
- **chore**: Maintenance tasks, dependency updates

## Breaking Changes

Add `!` after the type or include `BREAKING CHANGE:` in the footer to trigger a MAJOR version bump:

```
feat!: remove support for Akamai provider v8

BREAKING CHANGE: Akamai provider v8 is no longer supported
```

## Examples

```bash
# Feature (minor bump)
git commit -m "feat(aap): add support for custom rate policies"

# Bug fix (patch bump)
git commit -m "fix(asm): correct match target configuration"

# Breaking change (major bump)
git commit -m "feat!: upgrade to Terraform 1.6"

# Documentation
git commit -m "docs: update README with new examples"

# Chore
git commit -m "chore: update dependencies"
```

## Scopes (Optional)

Use scopes to indicate which part of the codebase is affected:
- `aap`: AAP configuration
- `asm`: ASM configuration  
- `property`: Property Manager configuration
- `modules`: Terraform modules
- `ci`: CI/CD changes
- `docs`: Documentation

## Automated Workflows

When commits are pushed to the main branch:
1. Changelog is automatically generated based on commit types
2. Version is bumped according to commit types
3. Git tag is created
4. GitHub release is published

When a PR is opened:
1. Terraform formatting is checked
2. Terraform validation runs
3. TFLint analyzes code
4. Trivy scans for security issues
