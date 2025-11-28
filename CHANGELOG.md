# RELEASE NOTES

## 1.2.0 (Nov 18, 2025)

#### FEATURES/ENHANCEMENTS:

* General
  * Upgraded all templates and modules to use Akamai provider v9.x

## 1.1.0 (Nov 17, 2025)

#### FEATURES/ENHANCEMENTS:

* General
  * Consolidated `deploy.ps1` script for all the templates.

## 1.0.6 (Oct 23, 2025)

#### FEATURES/ENHANCEMENTS:

* General
  * Upgrade to use modules `v1.0.6`.

## 1.0.5 (Aug 20, 2025)

#### FEATURES/ENHANCEMENTS:

* Delivery
  * Rename variable `is_secure` as `etls`.
  * Adjust the deploy.ps script to request for the `activation_notes`.
  * Clean the file terraform.tfvars for simplicity.

## 1.0.4 (Aug 7, 2025)

#### FEATURES/ENHANCEMENTS:

* Appsec
  * Added support for the `akamai_appsec_version_notes` resource for configuration version notes.
  * Use of `version_notes` and `activation_notes` names across templates for consistency.

## 1.0.3 (Jul 9, 2025)

#### FEATURES/ENHANCEMENTS:

* General
  * PowerShell deployment script optimized for the use of built-in functions and cross platform compatibility.

## 1.0.2 (Jun 23, 2025)

#### FEATURES/ENHANCEMENTS:

* General
  * Added Webex Support Space reference to the documentation.

* Appsec
  * Removed "Automated Shopping Cart and Sniper Bots" as this is no longer available to the product. 

#### BUG FIXES:

* Appsec
  * Fixed typos form bmv to bvm.

## 1.0.1 (Jun 10, 2025)

#### BUG FIXES:

* General
  * Updated module references from HTTP to SSH which prevented some users to pull the required modules.

## 1.0.0 (May 28, 2025)

#### FEATURES/ENHANCEMENTS:

* General
  * First official version of the PS Terraform Templates ([view](https://git.source.akamai.com/projects/GSS-DEVOPS/repos/ps-terraform-templates/commits/3a7fd9e381e0edbd031aa0b571f6c1d33e5c9d97#new-aap-configuration%2Fenvironments%2Fdev%2Fdev.tfvars.dist))

* Appsec
  * AAP Terraform template
  * AAP/ASM Terraform template

* PAPI
  * Property manager Terraform template
