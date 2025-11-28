# Terraform Integration

[Terraform](https://developer.hashicorp.com/terraform) allows you to manage Akamai Edge infrastructure using the Akamai Terraform Provider. This guide will help you in integrating various products using terraform.

## Predefined Templates Repository
The [ps-terraform-templates repository](https://git.source.akamai.com/projects/GSS-DEVOPS/repos/ps-terraform-templates/browse) assists in deploying delivery and security configurations efficiently using predefined Terraform templates.

# Requirements

### MacOS Setup - [Link](https://git.source.akamai.com/users/joanders/repos/goldload-gs-macos/browse)

### Windows Setup - [Link](https://ac-aloha.akamai.com/home/ls/community/apj-services-community/post/4240930785053181)

## Getting Started with the Structuring of Terraform Configurations

Putting all code in `main.tf` is a good idea when you are getting started or writing example code. In all other cases, you will be better off having several files split logically like this:

## Project Structure

- `modules` — Reusable modules.
- `main.tf` — Calls modules, locals, and data sources to create all resources.
- `variables.tf` — Contains declarations of variables used in `main.tf`.
- `outputs.tf` — Contains outputs from the resources created in `main.tf`.
- `providers.tf` — Contains version requirements for Terraform and providers.
- `deploy.ps1` — PowerShell script that automates the deployment of Akamai property configurations using Terraform.
- `terraform.tfvars` — Default variable values. Should not be used anywhere except for composition.
- `rules.tf` or `property snippets` — Contains property rules.
- `README.md` — Project documentation.
- `.gitignore` — Lists files and folders to ignore while committing to Git.

## Providers

```hcl
terraform {
  required_providers {
    akamai = {
      source  = "akamai/akamai"
      version = "~> 9.0"
    }
  }
  required_version = ">= 1.9.0"
}
```
## PowerShell Command to Get Switch Key

To retrieve the switch key for an account, use the following PowerShell command:
`Get-AccountSwitchKey <Account Name>`

Ensure the Akamai module version is 2.2.0 or above.

## Prerequisites

### 1. Install Terraform
- Download and install Terraform from the official [Terraform Downloads](https://developer.hashicorp.com/terraform/downloads) page.
- Verify installation:
 
  `terraform version`

### 2.Akamai Account
Ensure you have an Akamai Control Center Account with API access to Akamai products.

### 3.Create Akamai API Credentials
 - Go to Akamai Control Center → Identity & Access Management

 - Create an API client with the required permissions for:
        Property Manager API (for Edge Configurations), 
        Cloudlet API (for Cloudlet configurations) and etc.,

### 4.	Generate API credentials 
(client_secret, access_token, and client_token)

### 5.Save API Credentials Locally 
Create a `.edgerc` file in your home directory (`~/.edgerc`) with the following format:
```
[default]
client_secret = your_client_secret
access_token = your_access_token
client_token = your_client_token
host = your_api_host
account_key = account_switch_key_from_above_step
```

## Integration Templates

* **new-aap-configuration** : This modules contains the template to create an AAP security configuration based on the best practices

* **new-aapasm-configuraion** : This modules contains the template to create an AAP+ASM security configuration based on the best practices

* **new-property** : This modules contains the template to create ION/ION-Premier/DSA delivery property based on the best practices

## how to clone this repository

* Create a clone of this repository on your local machine using the below URL
```
> git clone ssh://git@git.source.akamai.com:7999/gss-devops/ps-terraform-templates.git
```
* Once the clone is created, change your working directory to the template of the product you are integrating
```
>cd ps-terraform-templates/new-aapasm-configuration/
>cd ps-terraform-templates/new-aap-configuration/
>cd ps-terraform-templates/new-property/
```
## Tips for Structuring TF Templates
1. Use meaningful variable names.
2. Follow a modular structure for reusability.
3. Add comments for clarity.
4. Use `.gitignore` to exclude `.terraform/` and `*.tfstate` files. You can reuse the `.gitignore` from this repository.

* Each template is accompanied by a `README.md` file containing detailed implementation instructions. Refer to this documentation to correctly configure and integrate the selected product.

# Resources

[Akamai Terraform Provider](https://techdocs.akamai.com/terraform/docs/overview)

[EMEA Professional Services: DevOps Trainings](https://ac-aloha.akamai.com/home/ls/content/5535721256386560/emea-ps-devops-2023)

[Webex Space: Terraform Templates Support](webexteams://im?space=52d5bcf0-42d2-11f0-9dd9-91df9cb369f0)

# Contacts