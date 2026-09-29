# [2.3.0](https://github.com/akamai/terraform-templates/compare/v2.2.0...v2.3.0) (2026-09-29)


### Features

* Adding tests for AAP ([d48ff2d](https://github.com/akamai/terraform-templates/commit/d48ff2d4429e2bb7f01e8e88b92bc90c80c7db1a))
* Adding tests for AAPASM ([28d39b9](https://github.com/akamai/terraform-templates/commit/28d39b94e0c39edce26d2d4e7806333b7de136b2))
* auto-approve tf destroy for AAP AAPAS PM ([cc61acb](https://github.com/akamai/terraform-templates/commit/cc61acb166c779c8a319093f9c2bfd1d1cbf3d2a))
* Automated tests. Initial test for EDNS ([412e507](https://github.com/akamai/terraform-templates/commit/412e5071072c2fd6f36a2bc9c6c8b79e034e0b43))
* delete AAP remote tfstate because destroy is not possible ([ca538d0](https://github.com/akamai/terraform-templates/commit/ca538d02cb14b789f4c665c120e8e50bcc948f61))
* fix for tfvars name for edns template ([8753bcd](https://github.com/akamai/terraform-templates/commit/8753bcd83e7178dbcf34b459cb0eb5333d160654))
* force Powershell modules installation ([d0da8d7](https://github.com/akamai/terraform-templates/commit/d0da8d77e91b8160bc6d4dfd345e704310f5f1dc))
* install Powershell Akamai.Contracts ([2918d7f](https://github.com/akamai/terraform-templates/commit/2918d7fa501c5105493eb3306ab60f3d01eb6b92))
* remove -Dry from deploy/destroy ([71e29b3](https://github.com/akamai/terraform-templates/commit/71e29b3afaa7c906f40a27587867e7e188a8813e))
* rename of remote tf state file ([994eefe](https://github.com/akamai/terraform-templates/commit/994eefe863800fa6bc1fcea43cc34b75fb2a42a2))
* rename of remote tf state file -- fix ([3df1b4a](https://github.com/akamai/terraform-templates/commit/3df1b4a6725769379c1cfbad6cb68908f36f15f3))
* support test for PM template ([1eee687](https://github.com/akamai/terraform-templates/commit/1eee687a33d116bc3ced16785715aca010dab948))
* support test for PM template again ([fa328fc](https://github.com/akamai/terraform-templates/commit/fa328fc4f6051eee47fb7af07048413efaa8dab7))
* testing for bmp phase 1 template ([0f19025](https://github.com/akamai/terraform-templates/commit/0f190254ea0066845f78574110baffac492e7a57))
* testing for bmp phase 1 template - uploading api defs ([7db34a8](https://github.com/akamai/terraform-templates/commit/7db34a836f33ce84478d1a19b8bc7aa4d89d2dc9))
* testing for ds2 template ([6bf163c](https://github.com/akamai/terraform-templates/commit/6bf163c3dd42d0906cf9678fa785a7115b1512d9))
* Use of -Environment instead of alias -Env ([f209005](https://github.com/akamai/terraform-templates/commit/f209005935338696cd534a330791c80f6d06a803))
* Use of -Environment instead of alias -Env again ([2751237](https://github.com/akamai/terraform-templates/commit/2751237d094fad507cec4540543fd92821ae7aa1))
* use of powershell hashtables for CLI arguments ([4a91a89](https://github.com/akamai/terraform-templates/commit/4a91a895f72e360e290a05d34cd25c7d8be97a40))



# [2.2.0](https://github.com/akamai/terraform-templates/compare/v2.1.0...v2.2.0) (2026-09-17)


### Features

* API Call Rate Summary ([734c40f](https://github.com/akamai/terraform-templates/commit/734c40fef765dd1a104db76ea32c8d499e2a53de))
* Updated with API call summary and log rotation ([c9a9795](https://github.com/akamai/terraform-templates/commit/c9a97954a287221d1b1a3d760c30e8ab3235f12f))



# [2.1.0](https://github.com/akamai/terraform-templates/compare/v2.0.0...v2.1.0) (2026-09-09)


### Features

* **dom:** fixing wildcard to accept any levels and also made * prefix optional for wildcard ([b87c41f](https://github.com/akamai/terraform-templates/commit/b87c41fc55c39a4f63fd8f52d2f78bac7c3d6548))
* **dom:** formatting main.tf ([5462d7e](https://github.com/akamai/terraform-templates/commit/5462d7ee62bb32af35d6c51dcc920a766a6914ba))
* **dom:** updating dom template with new changes ([82366fd](https://github.com/akamai/terraform-templates/commit/82366fd2a5674ea6cb3663f05f1a7963de165330))



# [2.0.0](https://github.com/akamai/terraform-templates/compare/v1.5.0...v2.0.0) (2026-09-02)


### Features

* **aapasm:** add multi-policy support with policy_defaults and policies map ([0860522](https://github.com/akamai/terraform-templates/commit/0860522ec29d1964bdca179544d1dd492237cdc3))


### BREAKING CHANGES

* **aapasm:** the aapasm template is incompatible with v1.x on every
surface. To upgrade, users must:
1. Rewrite tfvars: the ~80 flat policy variables are replaced by
   policy_defaults (baseline) plus a policies map; each policy requires
   policy_name, policy_prefix (4 uppercase alphanumerics, unique) and
   hostnames. Follow the new *.tfvars.dist examples.
2. Update output references: security_policy_id is now security_policy_ids,
   a map keyed by policy name.
3. Migrate existing Terraform state: resource addresses moved from
   module.security / module.client-reputation / module.bot-manager to
   module.security-config and module.security-policy["<key>"]. Without
   state migration, terraform will plan a destroy and recreate of the
   security configuration.
The old aap-asm/security, client-reputation and bot-manager modules were
removed from terraform-templates-modules in v2.0.0.



# [1.5.0](https://github.com/akamai/terraform-templates/compare/v1.4.0...v1.5.0) (2026-07-15)


### Bug Fixes

* change module source ref to pass test ([c443275](https://github.com/akamai/terraform-templates/commit/c443275f5f5d1afda6822069e9afa4c234cf08cd))
* set proper module source ref ([d9c8226](https://github.com/akamai/terraform-templates/commit/d9c82267538139f8962a4492179440e3a9ed87d0))
* several changes as follows ([64da101](https://github.com/akamai/terraform-templates/commit/64da1013c746927d0a02c553fe7b712f12ff992a))


### Features

* DOHRMY-148, DOHRMY-131 ([ede6b6f](https://github.com/akamai/terraform-templates/commit/ede6b6f595f9c69cc33abd7d69055c069a6e8644))



# [1.4.0](https://github.com/akamai/terraform-templates/compare/v1.3.2...v1.4.0) (2026-05-08)


### Bug Fixes

* **edns:** Disabled drift detection due to provider inconsistencies ([6fce93b](https://github.com/akamai/terraform-templates/commit/6fce93b44c3c55f5a527af9897421adf49d55ad3))


### Features

* Added drift detection support to AAP and AAPASM templates ([f44bea5](https://github.com/akamai/terraform-templates/commit/f44bea57b2518ca78fc9ad7cb13f57a5997c2ddf))
* Debug support for EDNS template to support drift detection ([4e482e3](https://github.com/akamai/terraform-templates/commit/4e482e3d4e3e3c2beeeae38e18a12dcd75e38308))
* Drift detection feature ([7cf12ae](https://github.com/akamai/terraform-templates/commit/7cf12aefc1bfba7a4ae7d5ce6b78f87bdf309d09))
* Drift support for CPS 3rd Party Certificates ([23e49f1](https://github.com/akamai/terraform-templates/commit/23e49f1e026e6454a851279734eceaaafbfba256))



## [1.3.2](https://github.com/akamai/terraform-templates/compare/v1.3.1...v1.3.2) (2026-03-12)


### Bug Fixes

* **edns:** EDNS module renamed ([3002355](https://github.com/akamai/terraform-templates/commit/3002355d88de9a4d763505a00b57667f288d0f62))



## [1.3.1](https://github.com/akamai/terraform-templates/compare/v1.3.0...v1.3.1) (2026-03-12)


### Bug Fixes

* **ci:** optimize GH workflows for hotfixes ([18083f8](https://github.com/akamai/terraform-templates/commit/18083f8891464721d19d383ad97faacae5b7d99b))



# [1.3.0](https://github.com/akamai/terraform-templates/compare/v1.2.0...v1.3.0) (2026-03-11)


### Bug Fixes

* **bmp:** Added terraform-docs.yml, updated documentation for BMP(main.tf, deploy.ps1, Readme.md), updated docs for operations ([10244c3](https://github.com/akamai/terraform-templates/commit/10244c3a938c5b17e80bd80fe349915ceee0748b))
* **bmp:** Added the AI prompt and updated documentation to reference the prompt ([594c61d](https://github.com/akamai/terraform-templates/commit/594c61dbeb011960b281ec5273d9c422b4a6802f))
* **bmp:** Adding the newly created readme file ([f22999b](https://github.com/akamai/terraform-templates/commit/f22999b75c928638a2b1e512a622b67e3901ac53))
* **bmp:** updated schema and operations docs ([924fb2b](https://github.com/akamai/terraform-templates/commit/924fb2b31cb9c1ad6e2e734f5855e2315ce03337))
* **EDNS:** setting up github workflow for new templates EDNS ([d9435f4](https://github.com/akamai/terraform-templates/commit/d9435f4ea45693c38cdd8f515eb3f56b7016048b))


### Features

* **bmp:** Added new template for BMP Integration ([5141ad6](https://github.com/akamai/terraform-templates/commit/5141ad6c19f67df1c90a811a24f87f30679b285a))
* **EDNS:** new templates EDNS ([9a87883](https://github.com/akamai/terraform-templates/commit/9a87883d0709b879b09148344d2e39a85e37f0dc))



# [1.2.0](https://github.com/akamai/terraform-templates/compare/v1.1.0...v1.2.0) (2026-02-17)


### Bug Fixes

* **test:** adjust test suite to the new modular deployment tool ([c0bba97](https://github.com/akamai/terraform-templates/commit/c0bba97d18c9e1dccf265834d80e8c41c90e1853))


### Features

* modularize deploy.ps1 for better collaboration. Improvements to certs templates ([29b55a9](https://github.com/akamai/terraform-templates/commit/29b55a9381daaff74a24815c36eac48c2762e88c))



# [1.1.0](https://github.com/akamai/terraform-templates/compare/v1.0.0...v1.1.0) (2026-02-10)


### Bug Fixes

* **cps:** updated module reference to v1.0.0 ([0edf6ab](https://github.com/akamai/terraform-templates/commit/0edf6abd667f68b2285581af4d8b7de12fd3b154))


### Features

* **cps:** new templates for dv-san and third-party certs ([2600ce4](https://github.com/akamai/terraform-templates/commit/2600ce4f653bd831c0ae480418d1a511cdee41f0))



# [1.0.0](https://github.com/akamai/terraform-templates/compare/v0.1.0...v1.0.0) (2026-01-29)


### Features

* bump to initial release version ([a0d80f7](https://github.com/akamai/terraform-templates/commit/a0d80f70ea97718af75331df4679329d8355153a))


### BREAKING CHANGES

* bump release version



# [0.1.0](https://github.com/akamai/terraform-templates/compare/ef8f7939f224021f92ff53420880d87c5b58aeb6...v0.1.0) (2026-01-29)


### Features

* sync with prod/internal version ([ef8f793](https://github.com/akamai/terraform-templates/commit/ef8f7939f224021f92ff53420880d87c5b58aeb6))
* update modules repository reference ([00ebe2d](https://github.com/akamai/terraform-templates/commit/00ebe2da7cf3a05339636ef61bc0adeda362c5a4))


### BREAKING CHANGES

* initial fully synchronized version with internal version



