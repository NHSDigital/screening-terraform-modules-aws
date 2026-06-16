# Guide: Test GitHub Actions locally

- [Guide: Test GitHub Actions locally](#guide-test-github-actions-locally)
  - [Overview](#overview)
  - [Key files](#key-files)
  - [Prerequisites](#prerequisites)
  - [Testing](#testing)
  - [FAQ](#faq)

## Overview

A GitHub workflow job can be run locally for the purpose of testing. The [nektos/act](https://github.com/nektos/act) project is an open-source tool that allows you to do so. The project aims to make it easier for developers to test and debug their GitHub Actions workflows before pushing changes to their repositories. By using act, you can avoid the potential delays and resource limitations associated with running workflows directly on GitHub. The tool provides a command-line interface and uses Docker containers to emulate the GitHub Actions runner environment. This enables you to execute the entire workflow or individual jobs and steps just as they would run on GitHub.

## Key files

- [init.mk](../../scripts/init.mk): Provides the `runner-act` make target
- [.tool-versions](../../.tool-versions): Defines the version of the `actions/actions-runner` Docker image

## Prerequisites

The following command-line tools are expected to be installed:

- [act](https://github.com/nektos/act#installation)
- [docker](https://docs.docker.com/engine/install/)

## Testing

Here is an example on how to run a GitHub workflow job:

```shell
make runner-act workflow="stage-1-coding-standards" job="pre-commit-checks"
```

`stage-1-pre-commit.yml` is reusable-only (`workflow_call`) and is normally executed through stage-1 reusable workflows and `cicd-1-pull-request.yaml`.

To run a specific stage-1 report job from the legacy reusable workflow:

```shell
make runner-act workflow="stage-1-commit" job="count-lines-of-code"

[Commit stage/Count lines of code] 🚀  Start image=ghcr.io/nhs-england-tools/github-runner-image:20230101-abcdef0-rt
[Commit stage/Count lines of code]   🐳  docker pull image=ghcr.io/nhs-england-tools/github-runner-image:20230101-abcdef0-rt platform=linux/amd64 username= forcePull=false
[Commit stage/Count lines of code]   🐳  docker create image=ghcr.io/nhs-england-tools/github-runner-image:20230101-abcdef0-rt platform=linux/amd64 entrypoint=["tail" "-f" "/dev/null"] cmd=[]
[Commit stage/Count lines of code]   🐳  docker run image=ghcr.io/nhs-england-tools/github-runner-image:20230101-abcdef0-rt platform=linux/amd64 entrypoint=["tail" "-f" "/dev/null"] cmd=[]
[Commit stage/Count lines of code] ⭐ Run Main Checkout code
[Commit stage/Count lines of code]   ✅  Success - Main Checkout code
[Commit stage/Count lines of code] ⭐ Run Main Count lines of code
[Commit stage/Count lines of code] ⭐ Run Main Create CLOC report
[Commit stage/Count lines of code]   🐳  docker exec cmd=[bash --noprofile --norc -e -o pipefail /var/run/act/workflow/1-composite-0.sh] user= workdir=
[Commit stage/Count lines of code]   ✅  Success - Main Create CLOC report
[Commit stage/Count lines of code] ⭐ Run Main Compress CLOC report
[Commit stage/Count lines of code]   🐳  docker exec cmd=[bash --noprofile --norc -e -o pipefail /var/run/act/workflow/1-composite-1.sh] user= workdir=
| updating: lines-of-code-report.json (deflated 68%)
[Commit stage/Count lines of code]   ✅  Success - Main Compress CLOC report
[Commit stage/Count lines of code]   ☁  git clone 'https://github.com/actions/upload-artifact' # ref=v4
[Commit stage/Count lines of code] ⭐ Run Main Check prerequisites for sending the report
[Commit stage/Count lines of code]   🐳  docker exec cmd=[bash --noprofile --norc -e -o pipefail /var/run/act/workflow/1-composite-check.sh] user= workdir=
[Commit stage/Count lines of code]   ✅  Success - Main Check prerequisites for sending the report
[Commit stage/Count lines of code]   ⚙  ::set-output:: secrets_exist=false
[Commit stage/Count lines of code]   ☁  git clone 'https://github.com/aws-actions/configure-aws-credentials' # ref=v2
[Commit stage/Count lines of code]   ✅  Success - Main Count lines of code
[Commit stage/Count lines of code]   ⚙  ::set-output:: secrets_exist=false
[Commit stage/Count lines of code] ⭐ Run Post Count lines of code
[Commit stage/Count lines of code]   ✅  Success - Post Count lines of code
[Commit stage/Count lines of code] 🏁  Job succeeded
```

## FAQ

1. _Can `act` be used to run Git hooks?_

   The `act` project is a powerful tool that can run a 3rd-party GitHub Actions. You might think about using it to perform the same tasks you have set up in your CI/CD pipeline. However, it is not designed to run or replace Git hooks, like the ones managed by the `pre-commit` framework. What `act` does is mimic the actions that happen on GitHub after you push a commit or make some other change that kicks off a GitHub Actions workflow. This usually involves more rigorous tasks like building your software, running a set of tests or even deploying your code. Utilising it for any other purpose could introduce unnecessary complexity and reduce the reliability of both the development process and the software itself. It is best used only for testing locally jobs and workflows.
