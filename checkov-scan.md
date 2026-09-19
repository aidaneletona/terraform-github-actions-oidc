# Checkov IaC Security Scanning & Remediation

## 1. Run and Review Initial Checkov Scan

- [x] Ran Checkov against the Terraform DEV configuration with `checkov -d .`
- [x] Recorded the initial scan results:
  - 23 passed checks
  - 10 failed checks
  - 0 skipped checks
- [x] Reviewed each failed Checkov policy individually
- [x] Identified findings involving:
  - Public subnet IP assignment
  - Security group rule descriptions
  - S3 event notifications
  - S3 lifecycle configuration
  - Unattached security groups
  - S3 server access logging
  - S3 cross-region replication
  - S3 KMS encryption
  - VPC Flow Logs
  - Default security group rules


## 2. Triage Initial Checkov Findings

- [x] Evaluated each Checkov finding based on the actual architecture instead of automatically fixing every failed check
- [x] Separated findings into security remediations and intentional exceptions

### Intentional Exceptions

- [x] Kept `CKV2_AWS_62` (S3 event notifications) as an intentional exception
  - The S3 bucket does not require Lambda, SNS, or SQS event-driven processing for this project's purpose

- [x] Kept `CKV_AWS_144` (S3 cross-region replication) as an intentional exception
  - Cross-region disaster-recovery infrastructure is outside the scope of the DEV environment

- [x] Kept `CKV2_AWS_5` (unattached security group) as an intentional exception
  - Did not create an unnecessary EC2 instance or ENI solely to attach the security group and satisfy Checkov


## 3. Remediate Initial Security Findings

### Public Subnet IP Assignment

- [x] Disabled automatic public IPv4 assignment on the public subnet
- [x] Changed `map_public_ip_on_launch` from `true` to `false`
- [x] Prevented resources placed in the public subnet from automatically receiving public IPv4 addresses


### Security Group Rule Documentation

- [x] Updated security group rules with explicit `description` values
- [x] Documented the purpose of allowed inbound/outbound traffic directly in the Terraform configuration

### Default Security Group Hardening

- [x] Managed the VPC's default security group through Terraform
- [x] Removed the default inbound rule
- [x] Removed the default outbound rule
- [x] Left the default security group with no implicit network access

### S3 Lifecycle Management

- [x] Created an `aws_s3_bucket_lifecycle_configuration` resource
- [x] Added a lifecycle rule for objects stored in the bucket
- [x] Added lifecycle handling instead of leaving objects unmanaged indefinitely

### S3 Server Access Logging

- [x] Created a separate S3 bucket specifically for server access logs
- [x] Created S3 logging configuration connecting the primary bucket to the logging bucket
- [x] Configured the primary bucket to deliver its S3 access logs to the dedicated logging bucket
- [x] Kept application/state data and access-log data separated

### Customer-Managed S3 KMS Encryption

- [x] Created a dedicated customer-managed KMS key for S3 with `aws_kms_key`
- [x] Enabled automatic KMS key rotation
- [x] Created a KMS alias for the S3 key
- [x] Configured S3 server-side encryption using the KMS key
- [x] Configured `aws_s3_bucket_server_side_encryption_configuration`
- [x] Set the encryption algorithm to `aws:kms`
- [x] Enabled S3 Bucket Keys
- [x] Associated the S3 buckets with the customer-managed KMS key instead of relying only on S3-managed encryption

### VPC Flow Logs

- [x] Created an `aws_flow_log` resource for the VPC
- [x] Configured the VPC to generate network traffic metadata
- [x] Created a CloudWatch Log Group to receive the VPC Flow Log records
- [x] Created an IAM role that VPC Flow Logs can assume
- [x] Added an IAM trust relationship allowing the VPC Flow Logs service to assume the role
- [x] Added IAM permissions allowing Flow Logs to create/write CloudWatch log streams and events
- [x] Connected the VPC Flow Log to the CloudWatch Log Group
- [x] Connected the VPC Flow Log to the IAM role required for CloudWatch delivery


## 4. Re-run Checkov and Analyze New Findings

- [x] Re-ran `checkov -d .` after implementing the initial security remediations
- [x] Confirmed Checkov was now evaluating the additional security resources created during remediation
- [x] Reviewed new findings against:
- **CloudWatch Log Group**
    - Checkov detected that the log group was not encrypted with a KMS key
    - Checkov detected that log retention was configured for only 30 days instead of 365 days

  - **Customer-Managed KMS Key**
    - Checkov detected that the KMS key did not have an explicit key policy

  - **Primary S3 Bucket Lifecycle Configuration**
    - Checkov detected that the lifecycle configuration did not abort incomplete multipart uploads

  - **S3 Access-Logging Bucket**
    - Checkov detected that the logging bucket did not have its own lifecycle configuration
    - Checkov detected that versioning was not enabled on the logging bucket
    - Checkov detected that the logging bucket was not encrypted with the customer-managed KMS key
    - Checkov detected that S3 event notifications were not configured
    - Checkov detected that cross-region replication was not configured

  - **VPC Flow Logs**
    - Checkov continued reporting that VPC Flow Logs were not enabled for the VPC
    - Verified that an `aws_flow_log` resource had already been created and associated with the VPC
    - Treated this as a Checkov/Terraform configuration-detection issue to investigate rather than creating a duplicate Flow Log

  - **Security Group**
    - Checkov continued detecting that the security group was not attached to another resource

  - **Primary S3 Bucket**
    - Checkov continued detecting that S3 event notifications were not configured
    - Checkov continued detecting that cross-region replication was not configured
- [x] Recognized that adding security resources can introduce additional Checkov policies that must also be evaluated
- [x] Triaged the new findings instead of modifying the architecture simply to reduce the Checkov failure count


## 5. Remediate Findings on the New Security Infrastructure

### CloudWatch Log Encryption

- [x] Created a dedicated customer-managed KMS key for CloudWatch Logs
- [x] Enabled automatic KMS key rotation
- [x] Added an explicit KMS key policy permitting the regional CloudWatch Logs service to use the key
- [x] Associated the VPC Flow Logs CloudWatch Log Group with the dedicated KMS key
- [x] Protected stored VPC Flow Log data with customer-managed encryption

### CloudWatch Log Retention

- [x] Reviewed the original 30-day CloudWatch retention configuration
- [x] Increased the CloudWatch Log Group retention period from 30 days to 365 days
- [x] Ensured VPC Flow Log records are retained for a longer security/auditing window

### S3 Incomplete Multipart Upload Cleanup

- [x] Updated the S3 lifecycle configuration
- [x] Added `abort_incomplete_multipart_upload`
- [x] Configured S3 to automatically clean up abandoned multipart uploads instead of retaining incomplete upload data indefinitely

### Explicit KMS Key Policy

- [x] Added an explicit policy to the customer-managed KMS key
- [x] Defined who is permitted to administer/use the key
- [x] Avoided relying solely on implicit/default KMS key permissions
- [x] Ensured the AWS services that require the key can use it through the appropriate permissions

### Logging Bucket Lifecycle Management

- [x] Created lifecycle configuration for the dedicated S3 access-logging bucket
- [x] Added lifecycle handling for access-log objects
- [x] Added incomplete multipart-upload cleanup to the logging bucket lifecycle configuration

### Logging Bucket Versioning

- [x] Created/configured S3 bucket versioning for the logging bucket
- [x] Set the logging bucket versioning status to `Enabled`
- [x] Protected log objects against simple overwrite/deletion scenarios by retaining object versions

### Logging Bucket KMS Encryption

- [x] Created server-side encryption configuration for the logging bucket
- [x] Configured the logging bucket to use `aws:kms`
- [x] Associated the logging bucket with the customer-managed KMS key
- [x] Ensured both the primary bucket and its access-log bucket use KMS-backed encryption

### Re-evaluate Intentional Exceptions

- [x] Reviewed Checkov's S3 event-notification finding for the primary bucket
- [x] Kept the finding as an intentional exception because no event-driven S3 workflow is required

- [x] Reviewed Checkov's S3 event-notification finding for the logging bucket
- [x] Kept the finding as an intentional exception because the access-log bucket does not require Lambda/SNS/SQS processing

- [x] Reviewed cross-region replication findings for both S3 buckets
- [x] Kept replication as an intentional exception because a second-region DR architecture is outside the DEV environment's scope

- [x] Reviewed the unattached security group finding again
- [x] Kept it as an intentional exception instead of provisioning an unnecessary EC2 instance or ENI

## 6. Final Checkov Validation

- [x] Re-ran Checkov after completing the security changes
- [x] Verified that the Terraform configuration contained the intended security controls
- [x] Distinguished remaining intentional exceptions from genuine security misconfigurations
- [x] Confirmed that unnecessary infrastructure was not added merely to obtain a zero-failure Checkov result
- [x] Recorded the final Checkov results:
  - 70 passed checks
  - 0 failed checks
  - 5 intentionally skipped checks
  ### Final Intentional Checkov Skips

- [x] `CKV2_AWS_62` — S3 event notifications (demo bucket)
- [x] `CKV2_AWS_62` — S3 event notifications (logging bucket)
- [x] `CKV_AWS_144` — S3 cross-region replication (demo bucket)
- [x] `CKV_AWS_144` — S3 cross-region replication (logging bucket)
- [x] `CKV2_AWS_5` — intentionally unattached security group
- [x] Completed the Checkov IaC security-scanning and remediation phase

## 7. Validate Checkov CI/CD Security Gate

- [x] Integrated Checkov into the GitHub Actions Terraform pipeline
- [x] Deliberately reintroduced an insecure Terraform configuration by enabling automatic public IPv4 assignment
- [x] Pushed the insecure configuration through the CI/CD workflow
- [x] Confirmed Checkov detected `CKV_AWS_130`
- [x] Confirmed the Checkov step failed and prevented the insecure configuration from proceeding through the pipeline
- [x] Restored `map_public_ip_on_launch = false`
- [x] Re-ran the pipeline successfully