# Changelog

All notable changes to this project will be documented in this file.

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
