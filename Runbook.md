# 🚀 Operational Runbook: Multi-Domain Hosting Platform

This runbook serves as the primary operational guide for the DevOps team managing the AWS Multi-Domain Hosting and Email Infrastructure. It is designed to ensure seamless onboarding, consistent maintenance, and rapid incident response.

---

## 📊 1. Centralized Monitoring & Observability
Before investigating any technical issue, consult the centralized dashboard to understand the system-wide health.
* **Dashboard Name**: `Cloud-Email-Infrastructure-V2`
* **Direct Access**: [CloudWatch Dashboard](https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=Cloud-Email-Infrastructure-V2)
* **Critical Metrics to Monitor**:
    * **SES Statistics**: Real-time tracking of `Sends`, `Bounces`, and `Rejections` to maintain account reputation.
    * **Lambda Forwarder Performance**: Monitoring `Invocations` vs. `Errors` to ensure the integrity of the email forwarding logic.
    * **Client Tracking Logs**: A filtered log view showing "SUCCESS" entries for forwarded emails, used to verify delivery for specific client domains.

---

## 🏗️ 2. Client Onboarding Procedures

### 2.1. Full Service Hosting (ECS Fargate)
**Use Case**: For dynamic applications (Node.js, Python, etc.) requiring automated scaling and management.
1.  **Variable Configuration**: Add the new domain to the `client_domains` list in the `variables.tf` file.
2.  **Infrastructure Initialization**: Execute `terraform apply`. This provisions the Route 53 Hosted Zone and triggers the ACM Certificate request.
3.  **DNS Delegation**: Provide the generated **Name Server (NS) records** to the client for update at their domain registrar.
4.  **Validation**: Once the ACM Certificate status reaches **`Issued`**, re-run `terraform apply` to deploy the ECS Service, Task Definitions, and ALB Host-Based routing rules.

### 2.2. Static Hosting (S3 + CloudFront)
**Use Case**: For high-performance static websites (React, HTML) delivered via a Global CDN.
1.  **Variable Configuration**: Add the domain to the `static_client_domains` list in `variables.tf`.
2.  **CDN Provisioning**: Follow the DNS delegation and ACM validation steps as detailed in section 2.1.
3.  **Final Deployment**: Execute `terraform apply` to create the private S3 bucket and CloudFront distribution using an Origin Access Identity (OAI) for enhanced security.

---

## 📧 3. Business Email & Deliverability Hardening
To ensure 100% inbox delivery and protect client domains from spoofing, verify the following records for every identity:
* **SPF (TXT)**: `v=spf1 include:amazonses.com ~all`
* **DKIM (CNAME)**: Verify that all three SES-generated CNAME records are propagated and "Verified" in the console.
* **DMARC (TXT)**: `v=DMARC1; p=quarantine;` — Essential for protecting the client's sender reputation.

---

## 🚨 4. Incident Response & Troubleshooting

### 4.1. Email Delivery Failures
* **Symptom**: Inbound mail is not arriving at the destination inbox.
* **Step 1**: Check the CloudWatch Dashboard for Lambda execution errors.
* **Step 2**: Verify the raw email file exists in the S3 inbound storage bucket (`sree84s-ses-inbound-mail-storage...`).
* **Step 3**: Inspect Lambda logs for `Permission Denied` (IAM Execution Role issues) or `Timeout` errors.

### 4.2. ECS Service Health Issues
* **Symptom**: Application Load Balancer (ALB) Target Group shows "Unhealthy" status.
* **Resolution**: Use CloudWatch Logs to identify application crashes. If no errors are found, force a new deployment:
  `aws ecs update-service --cluster vm-hosting-cluster --service <client-service-name> --force-new-deployment`

---

## 🗑️ 5. Client Offboarding (Deprovisioning)
1.  **Configuration Removal**: Remove the domain entry from Terraform variables.
2.  **Manual S3 Purge**: Manually delete all objects in the client's asset S3 bucket (Terraform will fail to delete a non-empty bucket).
3.  **Infrastructure Destruction**: Run `terraform apply` to remove the ECS Service, Route 53 records, and CloudFront distributions.
4.  **SES Identity Cleanup**: Manually delete the verified domain identity from the SES console.

---
**Last Updated**: December 18, 2025
**Document Owner**: DevOps Engineering Team