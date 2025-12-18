# 🚀 Multi-Tenant AWS Hosting & Business Email Infrastructure

This repository contains the production-ready Terraform configuration for a scalable, multi-tenant platform on AWS. [cite_start]It handles both dynamic web applications and static assets, integrated with an enterprise-grade business email system[cite: 1, 3, 5].

## 🏗️ Architecture Overview
The platform leverages a **Hub-and-Spoke** model to support 70-100 client domains with two primary hosting flows:

1.  [cite_start]**Dynamic Hosting (ECS Fargate):** High-availability containerized apps behind an Application Load Balancer (ALB) using Host-Based Routing[cite: 21, 22].
2.  [cite_start]**Static Hosting (S3 + CloudFront):** Global content delivery via CDN for lightning-fast performance[cite: 24, 62].
3.  [cite_start]**Business Email (SES + Lambda):** Automated email forwarding and deliverability hardening (SPF, DKIM, DMARC) for client domains[cite: 28, 31, 33].



## 🛠️ Key Technical Stack
* [cite_start]**Infrastructure:** Terraform (IaC) - 100% automated & idempotent[cite: 11, 54, 80].
* [cite_start]**Compute:** AWS ECS Fargate (Serverless Containers) with Auto-scaling[cite: 21, 26, 60].
* [cite_start]**Networking:** Multi-AZ VPC with Public/Private subnets and NAT Gateways[cite: 17, 18, 58].
* [cite_start]**Security:** ACM (SSL/TLS), IAM Least Privilege, and S3 Bucket Policies[cite: 23, 44, 89].
* [cite_start]**Monitoring:** Centralized CloudWatch Dashboard for SES and Lambda health[cite: 39, 40, 41].

## 📊 Monitoring & Observability
We have implemented a **unified CloudWatch Dashboard** (`Cloud-Email-Infrastructure-V2`) that tracks:
* [cite_start]**Email Health:** Real-time monitoring of SES Sends, Bounces, and Rejections[cite: 34, 40].
* [cite_start]**Lambda Performance:** Invocations and error tracking for the Email Forwarder[cite: 40].
* [cite_start]**Live Logs:** Integrated Log Insights to track successful email forwardings per client[cite: 41].

## 📧 Business Email Implementation
For every client domain, the platform automatically configures:
* [cite_start]**Verification:** Domain identity verification in SES[cite: 29, 68].
* [cite_start]**Hardening:** Automatic DNS records for **SPF, DKIM, and DMARC** to ensure high deliverability[cite: 31, 69, 70].
* [cite_start]**Forwarding:** A Lambda-based solution that routes `info@clientdomain.com` to the client's designated Gmail/Outlook[cite: 33, 72].

## 🚀 Quick Start
1.  **Initialize:** `terraform init`
2.  **Plan:** `terraform plan -var-file="production.tfvars"`
3.  **Deploy:** `terraform apply -auto-approve`

## 📖 Operational Documentation
* [cite_start]**[Runbook.md](./Runbook.md):** Step-by-step guide for onboarding new clients, rotating certificates, and incident response[cite: 13, 74, 82].
* [cite_start]**CI/CD:** GitHub Actions workflow located in `.github/workflows/` for automated deployments[cite: 12, 49, 73].