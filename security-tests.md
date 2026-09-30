Individual tests document controls tested separately. Grouped workflow results document multiple failures and fixes encountered across attempts of the same workflow run.



# Grouped Tests

## Tests from `Manual prod` #163

### Checkov rejection test
- Change: Logs bucket uses SSE-S3.
- Result: Checkov rejected it with CKV_AWS_145, causing pr-check to fail.
- Resolution: Added a documented exception for the access-logs bucket.
- Retest: `Checkov Security Scan DEV` step passed. 
- Evidence: [Failed Workflow run](https://github.com/aidaneletona/terraform-github-actions-oidc/actions/runs/36618563832/job/109577782287)[Succesful Workflow Run](https://github.com/aidaneletona/terraform-github-actions-oidc/actions/runs/36704886274)


### Terraform format rejection test

- Change: Incorrect formatting in module files s3/main.tf and network/main.tf
- Result: Terraform Format Check MODULES rejected it and caused workflow to fail.
- Resolution: Recursively terraform formatted terraform/modules
- Retest: `Terraform Format Check MODULES` passed and PR passed.
- Evidence: [Failed Workflow run](https://github.com/aidaneletona/terraform-github-actions-oidc/actions/runs/36621338518/job/109587208810?pr=22) [Succesful Workflow Run](https://github.com/aidaneletona/terraform-github-actions-oidc/actions/runs/36704886274)

## Tests from `Merge pull request #22 from aidaneletona/manual-prod` #164

### Incorrect repository in apply role Trust Policy

- Change: Incorrect repository name under `sub` in IAM apply role. 
- Result: Received `Error: Could not assume role with OIDC: Not authorized to perform sts:AssumeRoleWithWebIdentity`. Configure Apply ROle step failed and caused workflow to fail.
- Resolution: Restore the correct repository credentials back in trust policy. 
- Retest:  Configure Apply Role step passed. 
- Evidence: [Failed workflow run](https://github.com/aidaneletona/terraform-github-actions-oidc/actions/runs/36705069571/attempts/1) [Succesful Workflow Run](https://github.com/aidaneletona/terraform-github-actions-oidc/actions/runs/36705069571)


## Missing S3 Write Permission 
- Change: Did not specify a S3 object's ARN for `Put:Object`.
- Result: `Record module version verified in Dev` step failed and worflow failed.
- Resolution: Added `arn:aws:s3:::terraform-oidc-state-aidan/dev/last-applied-modules` to the specified resources for the `Put:Object` action. 
- Retest: `Record module version verified in Dev` step passed. Dev deployment succeeded. 
- Evidence: [Failed Workflow run](https://github.com/aidaneletona/terraform-github-actions-oidc/actions/runs/36705069571/job/109861421761) [Succesful Workflow Run](https://github.com/aidaneletona/terraform-github-actions-oidc/actions/runs/36705069571)


## Mising S3 Read Permission 
- Change: Did not specify a S3 object's ARN for `Get:Object`. 
- Result: `Verify current modules succeeded in Dev` step failed and workflow failed. 
- Resolution: Added `arn:aws:s3:::terraform-oidc-state-aidan/dev/last-applied-modules` to the specified resources for the `Get:Object` action.
- Retest: `Verify current modules succeeded in Dev` step passed. Prod deployment successful. 
- Evidence: [Failed workflow run](https://github.com/aidaneletona/terraform-github-actions-oidc/actions/runs/36705069571/job/109870288480) [Succesful Workflow Run](https://github.com/aidaneletona/terraform-github-actions-oidc/actions/runs/36705069571)

# Individual Tests

### Incorrect repository in apply role Trust Policy



