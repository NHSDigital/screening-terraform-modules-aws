# Changelog

All notable changes to this project will be documented in this file.

## [2.4.1](https://github.com/NHSDigital/screening-terraform-modules-aws/compare/v2.4.0...v2.4.1) (2026-05-27)

### Bug Fixes

* **release:** align module reference updates and include Terraform assets ([#38](https://github.com/NHSDigital/screening-terraform-modules-aws/issues/38)) ([d58ff00](https://github.com/NHSDigital/screening-terraform-modules-aws/commit/d58ff0097f71080c5b3db4ade0c6ed5dbe6c7197))

## [2.4.0](https://github.com/NHSDigital/screening-terraform-modules-aws/compare/v2.3.0...v2.4.0) (2026-05-27)

### Features

* **license-manager:** add new License Manager module with README and context configuration ([#27](https://github.com/NHSDigital/screening-terraform-modules-aws/issues/27)) ([35d6ae1](https://github.com/NHSDigital/screening-terraform-modules-aws/commit/35d6ae1d8174c6ece950875c190751e2ca48ffd4))

## [2.3.0](https://github.com/NHSDigital/screening-terraform-modules-aws/compare/v2.2.0...v2.3.0) (2026-05-27)

### Features

* **guardduty:** add new GuardDuty module with updated context and README ([#24](https://github.com/NHSDigital/screening-terraform-modules-aws/issues/24)) ([deda21a](https://github.com/NHSDigital/screening-terraform-modules-aws/commit/deda21a792762f1278afb7f00f25c4a895bd7535))

## [2.2.0](https://github.com/NHSDigital/screening-terraform-modules-aws/compare/v2.1.1...v2.2.0) (2026-05-27)

### Features

* **s3_bucket:** add new S3 module with detailed README and context configuration ([#28](https://github.com/NHSDigital/screening-terraform-modules-aws/issues/28)) ([cd7e85a](https://github.com/NHSDigital/screening-terraform-modules-aws/commit/cd7e85ab15a56a9d50ddf3e26a0ef629271cc94e))

## [2.1.1](https://github.com/NHSDigital/screening-terraform-modules-aws/compare/v2.1.0...v2.1.1) (2026-05-27)

### Bug Fixes

* **release:** correct module reference version updates and add safety tests ([#37](https://github.com/NHSDigital/screening-terraform-modules-aws/issues/37)) ([8079edd](https://github.com/NHSDigital/screening-terraform-modules-aws/commit/8079edd65acb9b872e84fc2678b6ffba24f2c7bb))

## [2.1.0](https://github.com/NHSDigital/screening-terraform-modules-aws/compare/v2.0.0...v2.1.0) (2026-05-27)

### Features

* **inspector:** add inspector module and context integration ([#29](https://github.com/NHSDigital/screening-terraform-modules-aws/issues/29)) ([4fed195](https://github.com/NHSDigital/screening-terraform-modules-aws/commit/4fed1951a7b41ba85cd1043a5c215f2a1b3d213d))

## [2.0.0](https://github.com/NHSDigital/screening-terraform-modules-aws/compare/v1.1.0...v2.0.0) (2026-05-27)

### ⚠ BREAKING CHANGES

* **tags,kms:** This changes the tag and naming output format to be able to be utilised by other modules. This will change resource naming and may result in resource re-creation.

* docs(infrastructure/modules): correct formatting and refresh tf-docs sections in readme files

* fix(infrastructure/modules/tags/variables.tf): set default value for var.owner

* test(infrastructure/modules/tags/region.tf): add tflint exclusions for not yet used locals

* style(infrastructure/modules/tags): lint fix and formatting

* fix(infrastructure/modules/tags/exports/context.tf): add context.tf file for use with other modules

* feat(infrastructure/modules/kms): add new kms module

* docs(infrastructure/modules/tags): correct description for var.label_order

Update described defaults to reflect main.tf - Defaults to ["service", "project", "environment", "stack", "name", "attributes"]

* fix(infrastructure/modules/tags/main.tf): update deprecated data source for input{ region }

data.aws_region.current.name => data.aws_region.current.region

https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region

* fix(infrastructure/modules/tags/main.tf): covert incompatible generated tag 'public_facing' to string

Generated tags uses length() which expects all tags_context to be a string, a collection type, or a structural type. var.public_facing is a bool, so have wrapped this in a tostring().

* fix(infrastructure/modules/kms/outputs.tf): add outputs to kms module

* docs(terraform-modules): regenerate module READMEs and align provider metadata

add markdownlint disable/restore directives around TF_DOCS blocks
refresh documented provider versions across infrastructure modules

* feat(tags): add terraform_source input

* feat(kms): enhance module with new variables and outputs for better context management

* style: terraform fmt

* docs(tags): update module source references and enhance descriptor formats in README

### Features

* **tags,kms:** add new modules, enhance tagging, and update documentation ([#23](https://github.com/NHSDigital/screening-terraform-modules-aws/issues/23)) ([7b49758](https://github.com/NHSDigital/screening-terraform-modules-aws/commit/7b49758d98757e8f404cb2c540c1f146afd6e395))
