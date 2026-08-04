# GitHub Actions Workflow Registration Reference

Three workflow files require additions for each new template. Replace `{Display Name}` with a
human-readable label (e.g. `Cloud Wrapper`) and `{terraform-folder}` with the Terraform
directory name (e.g. `new-cloudwrapper`).

---

## File 1 — `.github/workflows/pr-validation.yml`

Two separate groups in the same file.

### Group A — Terraform Validate

**Location:** after the last `Terraform Validate -` step, **before** the `Setup TFLint` step.

```yaml
      - name: Terraform Validate - {Display Name}
        working-directory: ./{terraform-folder}
        run: |
          terraform init -backend=false
          terraform validate
```

### Group B — TFLint

**Location:** after the last `Run TFLint -` step, **before** the `Run Trivy Security Scan` step.

```yaml
      - name: Run TFLint - {Display Name}
        working-directory: ./{terraform-folder}
        run: tflint --recursive
```

---

## File 2 — `.github/workflows/tf-docs.yml`

**Location:** after the last `Generate terraform-docs for` step.

```yaml
      - name: Generate terraform-docs for {Display Name}
        uses: terraform-docs/gh-actions@v1.4.1
        with:
          working-dir: ./{terraform-folder}
          config-file: ../.terraform-docs.yaml
          output-file: README.md
          output-method: inject
          git-push: true
```

---

## Multiple Terraform Directories (CPS pattern)

If the template maps to more than one Terraform directory (like CPS, which has `new-dv-san-cert/`
and `new-third-party-cert/`), add one block per directory in **each** of the three groups above.

Example for a hypothetical two-directory template:

```yaml
      # pr-validation.yml — Validate group
      - name: Terraform Validate - {Display Name} - Type A
        working-directory: ./new-{name}-type-a
        run: |
          terraform init -backend=false
          terraform validate

      - name: Terraform Validate - {Display Name} - Type B
        working-directory: ./new-{name}-type-b
        run: |
          terraform init -backend=false
          terraform validate
```

Repeat the same split for the TFLint group and the tf-docs step.

---

## Insertion Order Rules

| File | Group | Insert after | Insert before |
|---|---|---|---|
| `pr-validation.yml` | Validate | Last `Terraform Validate -` step | `Setup TFLint` step |
| `pr-validation.yml` | TFLint | Last `Run TFLint -` step | `Run Trivy Security Scan` step |
| `tf-docs.yml` | terraform-docs | Last `Generate terraform-docs for` step | (end of steps) |

Do **not** append steps at the end of the file — the Trivy scan and upload steps in
`pr-validation.yml` must always be last in the `terraform-checks` job.
