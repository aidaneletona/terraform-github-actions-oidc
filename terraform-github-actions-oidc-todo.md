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

---

# Phase 18 — Test the Security Controls

Do not only test the successful path.

- [x] Change the OIDC trust policy to an incorrect repository and confirm authentication fails
- [x] Restore the correct repository condition
- [x] Remove a required IAM permission and confirm Terraform fails
- [x] Restore the required permission
- [x] Introduce invalid Terraform syntax and confirm validation fails
- [x] Introduce bad formatting and confirm the formatting check fails
- [x] Attempt deployment from an unauthorized branch if practical
- [x] Confirm deployment restrictions work

These tests demonstrate that the security controls actually enforce something.

---

# Phase 19 — Add Additional features

- [ ] Add separate development and production environments
- [ ] Use separate IAM roles for plan and apply
- [ ] Add GitHub Environment approvals
- [ ] Add Terraform state locking using the current supported AWS backend approach
- [ ] Add Checkov
- [ ] Drift Detection + scheduled `terraform plan`

# Phase 20 — Logging and Audit Evidence

- [x] Use CloudTrail to verify `AssumeRoleWithWebIdentity` activity
- [x] Identify the GitHub Actions role in AWS activity
- [x] Capture evidence of successful role assumption
- [x] Capture GitHub Actions workflow logs
- [x] Capture a successful Terraform plan
- [x] Capture a successful deployment
- [x] Capture at least one intentionally failed security test
- [x] Do not expose credentials or sensitive values in screenshots

---

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
- [x] Explain each step in plain language
- [x] Clearly show that no permanent AWS access key is used

---

# Phase 22 — README Documentation

Your final README should include:

- [x] Project title
- [x] Project overview
- [x] Security problem being solved
- [x] Architecture diagram
- [x] Technologies used
- [x] Terraform explanation
- [x] GitHub Actions explanation
- [x] OIDC explanation
- [x] AWS STS explanation
- [x] IAM trust policy explanation
- [x] IAM permissions policy explanation
- [x] Document why each major permission is required
- [x] Remote state design
- [x] Pipeline workflow
- [x] Security controls
- [x] How to run the project
- [ ] Example Terraform plan
- [ ] Example successful deployment
- [ ] Document test deployment failures (From phase 18)
- [ ] Example failed security test
- [ ] Screenshots
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
- [ ] IAM role trust policy
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
