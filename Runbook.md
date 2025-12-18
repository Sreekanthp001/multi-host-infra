# 🚀 Operational Runbook: Multi-Domain Hosting Platform

Eee runbook AWS Multi-Domain Hosting Infrastructure ni manage chese Operations Team ki oka comprehensive guide. Kotha DevOps Engineer evaraina vachina, minimal context tho onboard avvadaniki idhi help avthundi.

---

## 📊 1. Real-Time Monitoring (The Command Center)
Infrastructure health ni track cheyadaniki mundhu ee Dashboard chudandi:
* **Dashboard Name:** `Cloud-Email-Infrastructure-V2`
* **URL:** [CloudWatch Dashboard Link](https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=Cloud-Email-Infrastructure-V2)
* **Key Widgets:**
    * **SES Statistics:** Sends, Rejects, and Bounces track cheyadaniki.
    * **Lambda Performance:** Forwarding Lambda errors monitoring kosam.
    * **Live Forwarding Logs:** Successful email deliveries ni real-time lo chudochu.

---

## 🏗️ 2. Onboarding a New Client Domain

### 2.1. Client Type 1: Full Service Hosting (ECS/Fargate)
**Use Case:** Dynamic applications (Node.js, PHP, etc.)
1.  **Variables Update:** `variables.tf` lo `client_domains` list ki kotha domain add cheyandi.
2.  **Terraform Apply:** `terraform apply` cheyandi. ACM certificate "Pending Validation" lo aaguthundi.
3.  **DNS Delegation:** Route 53 lo create aina **NS Records** ni client ki ivvandi (Registrar lo update cheyali).
4.  **Verification:** ACM status **`Issued`** ga maraka, malli `terraform apply` kottandi.
5.  **Post-Deployment:** `alb_dns_name` ki domain point ayyindha ledha check cheyandi.

### 2.2. Client Type 2: Static Hosting (S3/CloudFront)
**Use Case:** Static sites (HTML/CSS/JS)
1.  **Variables Update:** `variables.tf` lo `static_client_domains` list ki domain add cheyandi.
2.  **DNS/ACM Setup:** Paina chepina steps (NS records & ACM validation) follow avvandi.
3.  **Final Apply:** ACM Issued ayyaka `terraform apply` cheyandi.
4.  **Content Upload:** Client ki S3 bucket access ivvandi assets upload cheyadaniki.

---

## 📧 3. Business Email Management & Hardening

[cite_start]Prathi client domain ki ee kindha records thappakunda check cheyali[cite: 1, 4]:
* [cite_start]**SPF (TXT):** `v=spf1 include:amazonses.com ~all` [cite: 31]
* [cite_start]**DKIM (CNAME):** SES provide chesina 3 records Route 53 lo active undali[cite: 69].
* [cite_start]**DMARC (TXT):** `v=DMARC1; p=quarantine;` (Brand protection kosam)[cite: 70].

---

## 🚨 4. Incident Response & Troubleshooting

### 4.1. Email Forwarding Failures
* **Dashboard Check:** CloudWatch Dashboard lo "Forwarding Errors" check cheyandi.
* [cite_start]**S3 Storage:** Raw emails `sree84s-ses-inbound-mail-storage...` bucket lo unnayo ledho chudandi[cite: 33, 72].
* [cite_start]**Lambda Logs:** `vm-hosting-ses-forwarder-lambda` logs lo `Permission Denied` or `Timeout` errors chudandi[cite: 40, 41].

### 4.2. ECS Service Unhealthy
* [cite_start]**Target Group:** ALB Target Group lo instances "Healthy" ga unnayo ledho chudandi[cite: 27, 59].
* **Force Deploy:** Emi work avvaka pothe: `aws ecs update-service --cluster vm-hosting-cluster --service <service-name> --force-new-deployment`.

---

## 🗑️ 5. Offboarding a Client
1.  **Remove References:** Terraform variables nundi domain ni delete cheyandi.
2.  [cite_start]**Empty S3 Buckets:** Manual ga S3 assets ni delete cheyandi (Empty ga lekunte Terraform bucket ni delete cheyadhu)[cite: 36].
3.  **Terraform Apply:** Final ga `terraform apply` kotti resources destroy cheyandi.
4.  [cite_start]**SES Cleanup:** Verified identity ni SES console nundi remove cheyandi[cite: 68].

---
**Last Updated:** 18-12-2025
**Owner:** DevOps Team / SreeDev