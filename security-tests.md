### Checkov rejection test
- Change: Logs bucket uses SSE-S3.
- Result: Checkov rejected it with CKV_AWS_145, causing pr-check to fail.
- Resolution: Added a documented exception for the access-logs bucket.
- Retest: pr-check passed.
- Evidence: [Failed Workflow run](https://github.com/aidaneletona/terraform-github-actions-oidc/actions/runs/36618563832/job/109577782287)


### Terraform format rejection test

- Change: Incorrect formatting in module files s3/main.tf and network/main.tf
- Result: Terraform Format Check MODULES rejected it and caused workflow to run.
- Resolution: Recursively terraform formatted terraform/modules
- Restest: pr-check passed
- Evidence: [Failed Workflow run](https://github.com/aidaneletona/terraform-github-actions-oidc/actions/runs/36621338518/job/109587208810?pr=22) [Succesful Workflow Run]