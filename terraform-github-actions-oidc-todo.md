# Terraform + GitHub Actions + OIDC — Project Checklist

## Project Goal

Build a secure Infrastructure as Code deployment pipeline that:

- Uses **Terraform** to define AWS infrastructure
- Stores the project in **GitHub**
- Uses **GitHub Actions** to validate, plan, and deploy Terraform
- Uses **GitHub OIDC** to authenticate to AWS
- Avoids storing permanent AWS access keys in GitHub
- Uses **IAM least privilege** for the deployment role
- Produces a portfolio-ready example of secure cloud infrastructure automation

---

# Phase 1 — Project and AWS Setup

- [x] Create a new project folder in VS Code
- [x] Initialize a Git repository
- [x] Create a GitHub repository
- [x] Create a `.gitignore`
- [x] Create a `README.md`
- [x] Confirm AWS CLI is installed
- [x] Confirm Terraform is installed
- [x] Verify Terraform:

```bash
terraform version
```

- [x] Verify AWS CLI:

```bash
aws sts get-caller-identity
```

- [x] Choose the AWS region for the project
- [x] Decide on a naming convention for project resources

Example project structure:

```text
terraform-github-actions-oidc/
│
├── .github/
│   └── workflows/
│       └── terraform.yml
│
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── providers.tf
│   └── versions.tf
│
├── docs/
│   └── architecture.md
│
├── .gitignore
└── README.md
```

---

# Phase 2 — Terraform Fundamentals

Before automating anything, get Terraform working locally.

- [x] Create `versions.tf`
- [x] Define the required Terraform version
- [x] Define the AWS provider version
- [x] Create `providers.tf`
- [x] Configure the AWS provider
- [x] Create `main.tf`
- [x] Create `variables.tf`
- [x] Create `outputs.tf`
- [x] Run:

```bash
terraform init
```

- [x] Run:

```bash
terraform fmt
```

- [x] Run:

```bash
terraform validate
```

- [x] Understand what `.terraform/` contains
- [x] Understand what `.terraform.lock.hcl` does
- [x] Make sure `.terraform/` is ignored by Git
- [x] Do not commit sensitive Terraform state files

---

# Phase 3 — Build Simple AWS Infrastructure

Start with a small infrastructure deployment.

A good starting point is:

- An S3 bucket
- Bucket encryption
- Public Access Block
- Versioning
- Resource tags

- [x] Define an S3 bucket with Terraform
- [x] Enable S3 versioning
- [x] Enable default encryption
- [x] Configure all S3 Public Access Block settings
- [x] Add tags
- [x] Run:

```bash
terraform plan
```

- [x] Read the Terraform plan
- [x] Confirm Terraform shows only the resources you expect
- [x] Run:

```bash
terraform apply
```

- [x] Verify the resources in AWS
- [x] Run another `terraform plan`
- [x] Confirm Terraform reports no unexpected changes
- [x] Test:

```bash
terraform destroy
```

- [x] Confirm Terraform removes the test infrastructure

---

# Phase 4 — Terraform Variables and Outputs

- [x] Move configurable values into `variables.tf`
- [x] Create variables for region
- [x] Create variables for project/environment names
- [x] Use variables in resource names and tags
- [x] Create useful outputs
- [x] Output resource IDs or ARNs where appropriate
- [x] Avoid putting secrets in Terraform variables
- [x] Create `terraform.tfvars.example` if useful
- [x] Do not commit a real `.tfvars` file if it contains sensitive information

---

# Phase 5 — Terraform State

Learn how Terraform remembers deployed infrastructure.

- [x] Understand what `terraform.tfstate` is
- [x] Understand why state can contain sensitive information
- [x] Confirm local state is ignored by Git
- [x] Create a dedicated S3 bucket for remote Terraform state
- [x] Enable versioning on the state bucket
- [x] Enable encryption on the state bucket
- [x] Block public access to the state bucket
- [x] Configure Terraform to use the remote backend
- [x] Run `terraform init` after changing the backend
- [x] Confirm state is stored remotely
- [x] Confirm `terraform.tfstate` is not committed to GitHub

---

# Phase 6 — GitHub Actions Basics

Create:

```text
.github/workflows/terraform.yml
```

Start with validation only.

- [x] Trigger the workflow on pull requests
- [x] Trigger the workflow on pushes to the main branch
- [x] Add a manual `workflow_dispatch` trigger if useful
- [x] Check out the repository
- [x] Install/setup Terraform
- [x] Run `terraform fmt -check`
- [x] Run `terraform init`
- [x] Run `terraform validate`
- [x] Confirm the workflow succeeds
- [x] Deliberately introduce a formatting or Terraform error
- [x] Confirm the workflow fails
- [x] Fix the error
- [x] Confirm the workflow succeeds again

---

# Phase 7 — Understand the Authentication Problem

Before OIDC, understand what you are fixing.

Traditional approach:

```text
GitHub Actions
      |
      v
Stored AWS Access Key + Secret Key
      |
      v
AWS
```

Problem:

- Long-lived AWS credentials have to be stored in GitHub secrets
- Credentials can be leaked
- Credentials have to be rotated
- Stolen credentials may remain useful until revoked

OIDC approach:

```text
GitHub Actions
      |
      v
GitHub OIDC Token
      |
      v
AWS STS
      |
      v
Temporary AWS Credentials
```

- [x] Understand what OIDC is at a basic level
- [x] Understand what AWS STS does
- [x] Understand the difference between an IAM user and IAM role
- [x] Understand why temporary credentials are preferable to permanent access keys

---

# Phase 8 — Configure GitHub OIDC in AWS

- [x] Configure GitHub as an OIDC identity provider in AWS IAM if required
- [x] Use GitHub's OIDC provider URL
- [x] Create an IAM role for GitHub Actions
- [x] Give the role a clear name

Example:

```text
GitHubActionsTerraformRole
```

- [x] Configure the role trust policy
- [x] Verify the actual GitHub OIDC `sub` claim generated by the workflow
  - Do not assume the older `repo:owner/repo:...` format
  - GitHub may include immutable owner and repository IDs in the `sub`
  - Use the actual `sub` value when restricting the trust policy
- [x] Allow the GitHub OIDC provider to assume the role
- [x] Restrict the trust policy to your GitHub organization/user
- [x] Restrict it to your repository
- [x] Restrict branches/environments where appropriate
- [x] Avoid allowing every GitHub repository to assume the role
- [x] Record the role ARN for GitHub Actions

---

# Phase 9 — Understand the OIDC Trust Policy

Be able to explain the trust relationship.

- [x] Identify the `Principal`
- [x] Identify `sts:AssumeRoleWithWebIdentity`
- [x] Understand the GitHub token `aud` condition
- [x] Understand the GitHub token `sub` condition
- [x] Understand how the `sub` condition limits which repository can assume the role
- [x] Understand how branch or environment restrictions can further limit access

Be able to explain:

> AWS trusts GitHub's OIDC provider, but only tokens matching the conditions in the IAM role trust policy are allowed to assume the deployment role.

---

# Phase 10 — IAM Permissions for Terraform

Do not automatically give the GitHub Actions role `AdministratorAccess`.

- [x] Determine which AWS APIs your Terraform configuration actually requires
- [x] Create an IAM permissions policy for the deployment role
- [x] Allow access only to required AWS services/actions
- [x] Restrict resources where practical
- [x] Attach the policy to the GitHub Actions role
- [x] Test the permissions
- [x] Remove unnecessary permissions

The project should demonstrate two different IAM concepts:

1. **Trust policy** — who can assume the role
2. **Permissions policy** — what the role can do after it is assumed

---

# Phase 11 — Authenticate GitHub Actions with OIDC

In the GitHub Actions workflow:

- [x] Add the required GitHub token permission:

```yaml
permissions:
  id-token: write
  contents: read
```

- [x] Configure AWS credentials using OIDC
- [x] Reference the IAM role ARN
- [x] Configure the AWS region
- [x] Do not add permanent AWS access keys
- [x] Run the workflow
- [x] Confirm GitHub successfully assumes the AWS role
- [x] Confirm AWS issues temporary credentials
- [x] Confirm Terraform can access AWS

At this point:

```text
GitHub Actions
      |
      | OIDC token
      v
AWS STS
      |
      | temporary credentials
      v
Terraform deployment role
      |
      v
AWS resources
```

---

# Phase 12 — Terraform Plan in GitHub Actions

- [x] Run `terraform plan`in GitHub Actions
- [x] Confirm the plan works using OIDC credentials
- [x] Make a small infrastructure change
- [x] Push the change
- [x] Confirm the Terraform plan detects it
- [x] Review the plan before applying

---

# Phase 13 — Secure Terraform Apply

Separate validation/planning from deployment.

A good workflow:

```text
Pull Request
     |
     v
fmt + validate + plan
     |
     v
Code Review / Merge
     |
     v
Main Branch
     |
     v
terraform apply
```
- [x] Prevent automatic apply from untrusted pull requests
- [x] Configure apply only from the main branch
- [x] Require pull request checks to pass before merging
- [x] Consider using a GitHub Environment for deployment (costs money)
- [x] Add manual approval for production deployment if available
- [x] Confirm a pull request cannot directly deploy infrastructure
- [x] Confirm an approved/merged change can deploy successfully

---

# Phase 14 — Protect the Terraform State

The GitHub Actions role needs access to remote state.

- [x] Verify the role has only the permissions required to access Terraform remote state
- [x] Verify remote-state permissions are restricted to the specific Terraform state bucket/state object
- [x] Ensure the bucket is private
- [x] Ensure encryption is enabled
- [x] Ensure versioning is enabled
- [x] Ensure Public Access Block is enabled
- [x] Confirm GitHub Actions can read state
- [x] Confirm GitHub Actions can update state
- [x] Confirm an IAM identity without state permissions cannot access the Terraform state

---

# Phase 15 — Add a More Realistic Infrastructure Deployment

Once the pipeline works, make the Terraform deployment substantial enough for a portfolio.

Possible resources:

- VPC
- Public/private subnets
- Security groups
- S3 bucket
- IAM role
- CloudWatch logging

You do not need to build a huge environment.

- [x] Add a VPC
- [x] Add subnets
- [x] Add route configuration as needed
- [x] Add a security group
- [x] Avoid unrestricted SSH/RDP
- [x] Add useful resource tags
- [x] Keep resources modular and understandable
- [x] Run the full deployment through GitHub Actions

---

# Phase 16 — Terraform Modules

Once the basic deployment works:

- [x] Move related resources into a Terraform module
- [x] Create module inputs
- [x] Create module outputs
- [x] Call the module from the root configuration
- [x] Run `terraform validate`
- [x] Run `terraform plan`
- [x] Confirm behavior is unchanged

Do not modularize everything just for the sake of having modules. Use them where they make the configuration easier to organize or reuse.

---

# Phase 17 — Pipeline Hardening

- [x] Pin important GitHub Action versions
- [x] Keep workflow permissions minimal
- [x] Use `contents: read` unless write access is required
- [x] Give `id-token: write` only to jobs that require OIDC
- [x] Restrict the AWS trust policy to the correct repository
- [x] Restrict deployment to the correct branch/environment
- [x] Review third-party GitHub Actions in yml file before using them
- [x] Avoid printing credentials or sensitive Terraform values
- [x] Mark sensitive Terraform outputs appropriately
- [x] Verify no AWS access keys exist in GitHub secrets
- [x] Verify no AWS credentials are committed to Git



# Phase 18 — Add Additional features

- [x] Add separate development and production environments
- [x] Use separate IAM roles for plan and apply
- [x] Add GitHub Environment approvals
- [x] Add Terraform state locking using the current supported AWS backend approach
- [x] Add Checkov
- [x] Drift Detection + scheduled `terraform plan`

# Phase 19 — Test the Security Controls

## GitHub repository rules

- [x] Attempt a direct push to `main` and confirm GitHub rejects it because a pull request and `pr-check` are required.
- [ ] Confirm a pull request cannot merge while `pr-check` is failing.
- [ ] Confirm a passing `pr-check` allows the pull request to merge under the repository rules.
- [ ] Attempt deployment from an unauthorized branch and confirm the deployment job is blocked or its OIDC role assumption is denied. Record which control blocked it.

## OIDC role trust

- [ ] Set the Plan role's trusted repository `sub` to an incorrect value; confirm its credential step fails with `sts:AssumeRoleWithWebIdentity`.
- [ ] Restore the Plan role's correct trust policy and confirm role assumption succeeds.
- [ ] Set the Apply role's trusted repository `sub` to an incorrect value; run a job that reaches its credential step and confirm role assumption fails.
- [ ] Restore the Apply role's correct trust policy and confirm role assumption succeeds.
- [ ] Confirm the Apply role cannot be assumed from a job context outside its allowed `dev` or `prod` environment.
- [ ] Confirm the repository or environment restrictions that limit deployment to `main` work as intended.

## Separate Plan and Apply permissions

- [x] Remove a required IAM permission and confirm Terraform fails; then restore the permission.
- [ ] Confirm the Plan role can complete a plan for both dev and prod.
- [ ] Confirm the Plan role cannot perform a representative infrastructure write action. Use an IAM policy simulation or a controlled test; do not apply a plan with the Plan role to production.
- [ ] Confirm the Apply role can apply an approved, expected change.
- [ ] Confirm dev and prod use their intended state files and do not modify each other's resources.
- [ ] Confirm the Apply role can write `dev/last-applied-modules` in the state bucket.
- [ ] Confirm the Plan role can read `dev/last-applied-modules` for the PROD verification step but cannot overwrite it.

## Code and IaC checks

- [x] Introduce invalid Terraform syntax and confirm validation fails.
- [x] Introduce bad Terraform formatting and confirm the formatting check fails.
- [ ] Introduce a temporary Terraform configuration that Checkov rejects; confirm `pr-check` fails, then remove it.
- [ ] Confirm the restored, valid configuration passes formatting, validation, and Checkov.

## File-change routing

- [ ] Change only `terraform/environments/dev/`. Confirm the push runs the dev job and skips prod. Save the job graph and changed-file routing output.
- [ ] Change only `terraform/environments/prod/`, with the current modules already verified in DEV. Confirm the push skips dev and runs prod. Save the job graph and routing output.
- [ ] Change a shared file under `terraform/modules/`. Confirm the pull request checks both environments and the push runs DEV before PROD. Save the routing output and job graph.
- [ ] For a shared module change, cause DEV to fail in a controlled run. Confirm PROD is skipped in that same run. Save the job graph showing DEV failed and PROD skipped, then restore the change.

## Manual DEV runs

- [ ] Run `workflow_dispatch` with `plan-dev` when DEV has a proposed change. Confirm Plan runs, Configure Apply Role and Apply are skipped, and the verified module record is not updated. Save the run steps.
- [ ] Run `workflow_dispatch` with `apply-dev` for an intended DEV change. Confirm Plan, Configure Apply Role, Apply, and Record module version verified in DEV succeed. Save the plan and successful steps.

## Manual PROD runs

- [ ] Confirm the manual-run menu offers `plan-dev`, `apply-dev`, `plan-prod`, and `apply-prod`.
- [ ] Run `plan-prod` from `main` with a proposed PROD change. Confirm Plan runs while the DEV module-verification step, Configure Apply Role, and Apply are skipped. Save the run steps.
- [ ] Run `apply-prod` from `main` with modules already verified in DEV and an intended PROD change. Confirm module verification, Plan, Configure Apply Role, and Apply succeed. Save the verification result, plan, and Apply steps.
- [ ] Run `plan-prod` or `apply-prod` from a branch other than `main`. Confirm the PROD job is skipped. Save the job graph.

## DEV module verification before PROD

- [ ] Confirm a successful DEV apply records the Git tree hash of `terraform/modules/` in `dev/last-applied-modules`.
- [ ] Confirm a failed DEV apply does not update the verified module record.
- [ ] Merge a module change without successfully applying or verifying it in DEV. Run `apply-prod` and confirm the module-verification step fails before PROD can apply. Save the failure.
- [ ] Successfully run `apply-dev` for that module version, then run `apply-prod`. Confirm the module comparison passes and PROD can apply its pending changes.
- [ ] After DEV succeeds but PROD is not applied, start a new manual `apply-prod` run without another file change. Confirm PROD can plan and apply the pending changes.
- [ ] Confirm a missing or unreadable `dev/last-applied-modules` record causes the PROD verification step to fail and prevents Apply.

## No-change plans and failed plans

- [ ] Run a push that produces a no-change DEV plan. Confirm Configure Apply Role runs, Terraform Apply is skipped, and the verified module version is recorded. Save the plan result and steps.
- [ ] Run a push that produces a no-change PROD plan. Confirm Configure Apply Role and Terraform Apply are skipped. Save the plan result and skipped steps.
- [ ] Run `apply-dev` with no DEV changes. Confirm Apply is skipped and the current module version is still recorded as verified.
- [ ] Run `apply-prod` with no PROD changes and verified modules. Confirm Apply is skipped.
- [ ] Cause Terraform Plan to fail in a controlled run. Confirm the job fails and no Apply or DEV module-record update occurs. Restore the working configuration.

## PROD environment approval

- [ ] If required reviewers are configured for `prod`, confirm the PROD job waits for approval before its steps run.
- [ ] Reject a controlled PROD deployment and confirm no PROD Apply runs.
- [ ] Approve an intended PROD deployment and confirm it proceeds through verification, checks, Plan, and Apply as appropriate.

## Scheduled drift checks

- [ ] Confirm a scheduled run checks the latest default-branch configuration.
- [ ] Confirm the scheduled run plans against both dev and prod state.
- [ ] Confirm the scheduled run does not automatically apply changes.
- [ ] Make a controlled resource change, confirm drift is reported, and restore the resource through the normal deployment path.
- [ ] Confirm `dev-drift` and `prod-drift` use the Plan role, produce separate summaries, and run no Apply job. Save the job graph and summaries.

For each test, document:
- Change: Logs bucket uses SSE-S3.
- Result: Checkov rejected it with CKV_AWS_145, causing pr-check to fail.
- Resolution: Added a documented exception for the access-logs bucket.
- Retest: pr-check passed.
- Evidence: [Workflow run](PASTE_RUN_URL_HERE)

# Phase 20 — Logging and Audit Evidence

One screenshot can support multiple tests. For other completed tests,
record the workflow-run link, expected result, observed result, and restoration.

## Existing evidence

- [x] Capture the earlier combined role's incorrect repository trust policy and matching failed OIDC credential step.
- [x] Use CloudTrail to identify a GitHub Actions assumed role making AWS API calls.
- [x] Capture GitHub Actions workflow logs and a successful Terraform plan.
- [x] Capture evidence of a successful Terraform deployment.
- [x] Capture GitHub rejecting a direct push to `main`.

## Current security controls

- [ ] Capture the current Plan and Apply roles' incorrect repository trust policies and matching authentication failures. Link the successful runs after restoring them.
- [x] Capture a failing and passing `pr-check`. Include the Checkov rejection test in the evidence.
- [ ] Capture the Plan role being denied a representative infrastructure write action.
- [ ] Capture an unauthorized-branch deployment being blocked and identify which control blocked it.

## Deployment gates

- [ ] Capture a shared-module run showing DEV failed and PROD was skipped.
- [ ] Capture PROD being blocked because the current modules were not verified in DEV, then capture verification passing after DEV succeeds.
- [ ] Capture a manual plan showing Apply skipped and a manual apply showing successful deployment. Link the corresponding DEV and PROD runs.
- [ ] Capture the PROD approval gate, if configured. Link the rejected deployment showing no Apply ran.

## Drift and environment separation

- [ ] Capture a scheduled run showing separate DEV and PROD drift summaries and no Apply job.
- [ ] Document the DEV and PROD state locations without exposing state contents or secrets.

## Supporting test records

- [ ] Link the remaining Phase 19 test runs, including file routing, no-change plans, failed plans, module-record updates, and applying pending PROD changes without a new file change.
- [ ] Record each test's expected result, observed result, and how the working configuration was restored.

## Screenshot hygiene

- [x] Keep credentials and sensitive values out of screenshots.



# Phase 21 — Architecture Diagram

Create an architecture diagram showing:

```text
Developer
    |
    v
GitHub Repository
    |
    v
Pull Request
    |
    v
GitHub Actions
    |
    | OIDC token
    v
AWS STS
    |
    | Temporary credentials
    v
IAM Terraform Deployment Role
    |
    v
Terraform
    |
    +---------> Remote State (S3)
    |
    v
AWS Infrastructure
```

- [x] Add the diagram to the README
- [x] Clearly show that no permanent AWS access key is used

---

# Phase 22 — README Documentation

Your final README should include:

## Project Introduction

- [x] Project title
- [x] Project overview
- [x] Security problem being solved
- [x] Architecture diagram
- [x] Pipeline workflow


### Core Infrastructure / CI/CD
- [x] Technologies Used
- [x] Terraform explanation
- [x] GitHub Actions explanation
- [x] GitHub OIDC explanation
- [x] AWS IAM OIDC Identity Provider explanation
- [x] AWS STS explanation
- [x] IAM Trust Policy explanation
- [x] IAM Permissions Policy explanation — UPDATE for separate Plan and Apply roles
- [x] Plan Role vs Apply Role explanation
- [x] Checkov explanation

### AWS Infrastructure
- [x] Amazon VPC explanation
- [x] Amazon S3 explanation
- [x] AWS KMS explanation
- [x] Amazon CloudWatch explanation
- [x] AWS CloudTrail explanation — IF you've already written this section

## IAM

- [x] Document least-privilege design decisions
- [x] Document why each major permission is required

## Terraform State Design

- [x] Remote state design
- [x] Explain why the S3 backend requires `s3:ListBucket`
- [x] Document Terraform state locking

## Security Controls

- [x] Security controls
- [x] Document GitHub `main` branch protection / repository rules
- [x] Explain separate Terraform DEV and PROD environments
- [x] Explain DEV and PROD GitHub Environments and deployment approvals
- [x] Document DEV-first → PROD promotion protection
- [x] Document Checkov security scanning and intentional suppressions
- [x] Document scheduled Terraform drift detection



## Testing and Evidence

- [ ] Example successful deployment
- [ ] Document test deployment failures (From phase 18)
- [ ] Example failed security test
- [ ] Screenshots

## Usage and Project Scope
- [x] How to run the project
- [x] Limitations
- [x] Future improvements

---

# Phase 23 — Portfolio Evidence

Collect screenshots or sanitized output showing:

- [ ] `terraform validate` success
- [ ] Terraform plan
- [ ] GitHub pull request workflow
- [ ] GitHub Actions successful deployment
- [ ] AWS OIDC identity provider
- [x] IAM role trust policy
- [ ] IAM role permissions
- [ ] CloudTrail role-assumption event
- [ ] Remote Terraform state bucket
- [ ] Deployed AWS infrastructure
- [ ] Failed authentication or permission test
- [x] Architecture diagram

Never publish:

- AWS access keys
- Session tokens
- GitHub tokens
- Sensitive Terraform state
- Private credentials

---

# Phase 24 — Repository Cleanup

- [ ] Remove unused files
- [ ] Remove temporary test configurations
- [ ] Check Git history for accidentally committed secrets
- [ ] Confirm `.gitignore` is correct
- [ ] Run `terraform fmt`
- [ ] Run `terraform validate`
- [ ] Confirm workflow YAML is readable
- [ ] Make resource names understandable
- [ ] Make comments useful
- [ ] Make sure README commands work
- [ ] Confirm screenshots contain no secrets
- [ ] Make repository public only after checking it carefully
- [ ] Pin the repository on GitHub

---

# Phase 25 — Resume / Portfolio Description

Possible resume bullet:

> Built a secure AWS Infrastructure as Code deployment pipeline using Terraform and GitHub Actions, implementing GitHub OIDC and AWS STS for temporary credentials, least-privilege IAM, remote state protection, and automated validation and deployment.

Be prepared to explain:

- Why OIDC is safer than storing AWS access keys
- How AWS STS creates temporary credentials
- How the IAM trust policy restricts GitHub
- Difference between a trust policy and permissions policy
- How Terraform state is protected
- What happens on a pull request
- What happens after merge
- How the pipeline prevents unauthorized deployment

---

# Optional Advanced Features (largely redundant)

These are not required for the core project.


- [ ] Add Trivy configuration scanning
- [ ] Add TruffleHog or another secret scanner
- [ ] Add cost estimation
- [ ] Add Terraform modules for multiple environments
- [ ] Add automated policy checks
- [ ] Add AWS Config
- [ ] Add deployment notifications
- [ ] Add rollback/recovery documentation

Note: **Checkov-heavy IaC security scanning belongs primarily in your separate IaC Security Scanning project.** You can add it here later, but it is not necessary for this project's core goal.

---

# Recommended Build Order

Do not try to configure Terraform, GitHub Actions, and OIDC simultaneously.

Use this order:

1. Install/verify Terraform
2. Build a small AWS resource locally
3. Learn Terraform plan/apply/destroy
4. Configure remote state
5. Create a GitHub Actions validation workflow
6. Learn the OIDC authentication flow
7. Configure GitHub as an AWS OIDC identity provider
8. Create the GitHub Actions IAM role
9. Restrict the trust policy
10. Create least-privilege deployment permissions
11. Authenticate GitHub Actions to AWS through OIDC
12. Run Terraform plan in GitHub Actions
13. Securely automate Terraform apply
14. Expand the infrastructure
15. Test security failures
16. Document and polish the project

---

# Definition of Done

The core project is complete when you can demonstrate:

- [x] AWS infrastructure is defined with Terraform
- [x] Terraform state is stored securely and is not committed to Git
- [x] GitHub Actions automatically validates Terraform
- [x] Pull requests produce a Terraform plan
- [x] Deployment occurs only through the intended branch/environment
- [x] GitHub Actions authenticates to AWS using OIDC
- [x] AWS STS provides temporary credentials
- [x] No permanent AWS access keys are required in GitHub
- [x] The OIDC trust policy is restricted to your repository
- [x] The deployment role follows least privilege
- [x] Terraform can successfully deploy the infrastructure
- [x] Failed authentication/permission tests prove the controls work
- [x] CloudTrail provides evidence of role assumption
- [ ] The architecture and security decisions are documented
- [ ] The repository is polished enough to show an employer
