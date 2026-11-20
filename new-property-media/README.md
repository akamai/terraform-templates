# AMD Property Template

This root module deploys an Akamai Adaptive Media Delivery (AMD) property through the `delivery-media` module from [terraform-templates-modules](https://github.com/akamai/terraform-templates-modules), pinned to release `v2.1.0`.

Requires Terraform >= 1.14.0 and Akamai provider ~> 11.1.

## Deployment via `deploy.ps1`

This template is registered under the `pm-media` template key. The wrapper script `../deploy.ps1` reuses the Property Manager handler and points it at this folder (`new-property-media`).

A common flow is as follows (with `prod` as the environment):

1. Save the changes only (no activations):
```bash
PS> ../deploy.ps1 pm-media -Env prod -Save -Notes "Some user notes"
```

2. Activate to staging:
```bash
PS> ../deploy.ps1 pm-media -Env prod -ActivateStaging
```

3. Activate to production:
```bash
PS> ../deploy.ps1 pm-media -Env prod -ActivateProduction
```

Options:
* Add `-Debug` to log all Terraform actions to a file under the environment directory.
* Add `-Dry` for a plan-only run (nothing is applied).
* Add `-Force` to skip the drift-detection prompt.
* Tear down the property with:
```bash
PS> ../deploy.ps1 pm-media -Env dev -Destroy
```

> **Note:** `pm-media` reuses the same PowerShell handler as `pm` (`lib/templates/PropertyManager.psm1`). Web-only product-ID checks (`secure_by_default`, `enable_mPulse`) are skipped automatically for the `pm-media` template.

> **Note:** Before any activation, the script verifies Domain Ownership (DOM) validation for every hostname. This check is skipped when `edge_hostname_type = "AKAMAIZED_HOSTNAME"`, because those hostnames are on Akamai's shared `akamaized.net` domain.

## Workflow

1. Copy or edit an environment tfvars file.
2. Set the EdgeGrid section, contract/group IDs, property name, hostnames, origin, and activation contacts.
3. Run Terraform from this directory:

```text
terraform init
terraform plan -var-file=environments/abm-test/abm-test.tfvars -out=.plan
terraform apply .plan
```

Keep `activate_to_staging` and `activate_to_production` false while building or reviewing a property. Set them only when an activation is intended.

For production activation, run:

```powershell
../deploy.ps1 pm-media -Env prod -ActivateProduction -Notes "AMD production activation"
```

The deployment script supplies the activation flags and applies the Terraform activation resources. The module retains activation state through `activation_to_staging_exists` and `activation_to_production_exists`; do not change those flags manually.

## Edge hostname modes

- `SBD`: Secure By Default. With `etls = true`, Akamai provisions the `edgekey.net` hostname automatically. With `etls = false`, Terraform creates an `edgesuite.net` hostname.
- `EDGESUITE`: Creates a Standard TLS `edgesuite.net` edge hostname.
- `EDGEKEY`: Creates an Enhanced TLS `edgekey.net` edge hostname and requires `certificate_id`.
- `AKAMAIZED_HOSTNAME`: Creates an `akamaized.net` Shared Cert edge hostname. Supply only the label in `hostnames`; do not include the suffix.

`etls` controls the AMD default rule's secure-delivery setting. The edge-hostname network is selected by `edge_hostname_type` and, for SBD, by `etls`.

## Additional origins

Set `additional_origins` to a map when requests need to route to origins other than `default_origin`. Each entry requires `origin_name`, `forward_host_header`, `hostname_match`, and `path_match`. Either match list may be `null`; at least one must be non-empty to identify the requests for that origin.

```hcl
additional_origins = {
	api = {
		origin_name         = "api-origin.example.com"
		forward_host_header = "REQUEST_HOST_HEADER"
		hostname_match      = ["api.example.com"]
		path_match          = ["/api/*"]
	}
}
```

The rule tree creates an `Additional Origins` parent rule and one child origin rule per map entry. An empty map keeps all requests on `default_origin`.

## Debugging

Enhanced debug is disabled by default. Set `enable_debug = true` in the environment tfvars to enable it. Leave `debug_key = null` for a stable auto-generated key, or supply a 64-character hexadecimal value to pin one.

The module always declares the enhanced-debug behavior. When disabled, its options contain only `enableDebug: false`.

## Outputs

- `property_id`: Created Property Manager property ID.
- `cpcode_id`: Created CP code ID.
- `cert_status`: Hostname-to-edge-hostname and certificate provisioning details.
- `rule_errors`: Property Manager rule validation errors, if any.

## Activation state

The `activation_to_staging_exists` and `activation_to_production_exists` flags preserve existing activation resources during refreshes. They are state-management flags and should not normally be changed manually.
