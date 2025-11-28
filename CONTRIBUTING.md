# Contributing

When contributing to this repository, please first discuss the change you wish to make via issue preferably ([GS Terraform Templates Request](https://gsinput.akamai.com/GS_TERRAFORM_REQUEST_FORM)), email, or any other method with the owners of this repository before making a change.

## Prerequisites

Please ensure you have the following installed before you start, to ensure that your contribution follows the same quality standards.

* [Akamai PowerShell v2](https://techdocs.akamai.com/powershell/docs/overview)
* [`terraform`](https://developer.hashicorp.com/terraform/downloads?product_intent=terraform)
* [`terraform-docs`](https://terraform-docs.io/)
* [`tflint`](https://github.com/terraform-linters/tflint)
* [`trivy`](https://github.com/aquasecurity/trivy)
* [`pre-commit`](https://pre-commit.com/)

Finally, install `pre-commit` into your working copy:

```
pre-commit install
```

This will ensure that hooks run before you commit. However, to manually run all the pre-commit configured steps/checks you can run the following at the repository root level:

```
pre-commit run --all-files   
```

## Versioning and Changelog
For now the changelog is managed manually. Before creating a Pull Request to `main` make sure to update the `CHANGELOG.md` accordingly. 

Bitbucket tags are used for versioning the releases by following the [Semantic Versioning specification](https://semver.org/). For now the tagging process is also manual, however an automated pipeline is more suitable.

For any version changes you may need to update any references to this repository.

## Pull Request Process

1. Fork the project.
2. A feature branch should be created for your based on the requested issue ([GS Terraform Templates Request](https://gsinput.akamai.com/GS_TERRAFORM_REQUEST_FORM)). Otherwise, start a feature branch following the [semantics prefix](#semantic-pull-requests) spec based on the `main` branch (`git checkout -b <feature-name> main`).
3. Update the documentation (main.tf, README.md) with details of changes including example HCL blocks and example files `*.tfvars.dist` if appropriate.
4. Commit and push your changes.
5. Issue a pull request and wait for your code to be reviewed.

## Checklists for contributions

- [ ] Ensure [semantics prefix](#semantic-pull-requests) is added to your PR or Commits (at least one of your commit groups)
- [ ] README.md has been updated.
- [ ] CHANGELOG.md has been updated.

## Semantic Pull Requests

To generate changelog, Pull Requests or Commits must have semantic and must follow conventional specs below:

- `feat:` for new features
- `fix:` for bug fixes
- `improvement:` for enhancements
- `docs:` for documentation and examples
- `refactor:` for code refactoring
- `test:` for tests
- `ci:` for CI purpose
- `chore:` for chores stuff

The `chore` prefix skipped during changelog generation. It can be used for `chore: update changelog` commit message by example.
