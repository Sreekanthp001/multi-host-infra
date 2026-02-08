# Quick Start Guide - Scaling to 100+ Domains

## 🚀 Ready to Deploy

Your infrastructure is now configured for **automatic scaling to 100+ domains**. Follow these steps to deploy.

---

## ✅ Pre-Deployment Checklist

- [x] Code changes implemented
- [x] Terraform validation passed
- [ ] Review terraform plan
- [ ] Run terraform apply
- [ ] Verify resources created

---

## 📝 Step-by-Step Deployment

### Step 1: Review Current Configuration

```bash
cd c:\devops\git-repo\multi-host-infra
```

Check your current domains in `terraform.tfvars`:

```hcl
client_domains = {
  "sree84s" = { domain = "sree84s.site", priority = 100 }
}

static_client_configs = {
  "clavio" = { domain_name = "clavio.store" }
}
```

**Current state:** 2 domains (1 dynamic, 1 static)

---

### Step 2: Preview Changes

```bash
terraform plan
```

**Expected output:**
```
Plan: X to add, Y to change, Z to destroy.

Changes to Outputs:
  + all_domain_names = [
      + "sree84s.site",
      + "clavio.store",
    ]
```

**What to verify:**
- ✅ `aws_route53_zone.client_hosted_zones["sree84s"]` - exists
- ✅ `aws_route53_zone.client_hosted_zones["clavio"]` - will be created
- ✅ `aws_acm_certificate.client_cert` - will be updated (new SANs)
- ✅ `aws_route53_record.alb_alias["sree84s"]` - exists
- ✅ `aws_route53_record.cloudfront_alias["clavio"]` - will be created

---

### Step 3: Apply Changes

```bash
terraform apply
```

Type `yes` when prompted.

**Timeline:**
- 0-5 min: Create hosted zones
- 5-15 min: ACM certificate validation
- 15-20 min: CloudFront distribution deployment
- **Total: ~20 minutes**

---

### Step 4: Verify Deployment

#### Check Hosted Zones

```bash
aws route53 list-hosted-zones --query "HostedZones[].Name" --output table
```

**Expected:**
```
-----------------
|ListHostedZones|
+---------------+
|  sree84s.site.|
|  clavio.store.|
+---------------+
```

#### Check ACM Certificate

```bash
aws acm list-certificates --region us-east-1 --query "CertificateSummaryList[0].SubjectAlternativeNameSummaries" --output table
```

**Expected:**
```
-----------------------
|ListCertificates     |
+---------------------+
|  sree84s.site       |
|  *.sree84s.site     |
|  clavio.store       |
|  *.clavio.store     |
+---------------------+
```

#### Check Alias Records

```bash
# Dynamic domain (ALB)
aws route53 list-resource-record-sets \
  --hosted-zone-id <sree84s-zone-id> \
  --query "ResourceRecordSets[?Type=='A']"

# Static domain (CloudFront)
aws route53 list-resource-record-sets \
  --hosted-zone-id <clavio-zone-id> \
  --query "ResourceRecordSets[?Type=='A']"
```

---

## 🎯 Adding New Domains

### Add a Dynamic Domain (ECS + ALB)

1. Edit `terraform.tfvars`:

```hcl
client_domains = {
  "sree84s" = { domain = "sree84s.site", priority = 100 },
  
  # ADD NEW DOMAIN
  "newclient" = { domain = "newclient.com", priority = 101 }
}
```

2. Apply:

```bash
terraform apply
```

3. **Auto-created resources:**
   - Route53 hosted zone for `newclient.com`
   - ACM certificate updated with `newclient.com` + `*.newclient.com`
   - DNS validation records
   - ALB alias record pointing to ALB
   - SES records (MX, SPF, DKIM, DMARC)

4. **Delegate nameservers:**

Get nameservers:
```bash
aws route53 get-hosted-zone --id <zone-id> --query "DelegationSet.NameServers"
```

Update at domain registrar:
```
ns-1234.awsdns-12.org
ns-5678.awsdns-34.com
ns-9012.awsdns-56.net
ns-3456.awsdns-78.co.uk
```

---

### Add a Static Domain (S3 + CloudFront)

1. Edit `terraform.tfvars`:

```hcl
static_client_configs = {
  "clavio" = { domain_name = "clavio.store" },
  
  # ADD NEW DOMAIN
  "newstatic" = { domain_name = "newstatic.io" }
}
```

2. Apply:

```bash
terraform apply
```

3. **Auto-created resources:**
   - Route53 hosted zone for `newstatic.io`
   - ACM certificate updated with `newstatic.io` + `*.newstatic.io`
   - DNS validation records
   - S3 bucket: `venturemond-infra-newstatic-static-content`
   - CloudFront distribution
   - CloudFront alias record

4. **Upload content to S3:**

```bash
aws s3 sync ./website-files s3://venturemond-infra-newstatic-static-content/
```

---

## 📊 Scaling to 10 Domains

### Example Configuration

```hcl
# terraform.tfvars

# 5 Dynamic Domains
client_domains = {
  "client1" = { domain = "client1.com", priority = 100 },
  "client2" = { domain = "client2.com", priority = 101 },
  "client3" = { domain = "client3.com", priority = 102 },
  "client4" = { domain = "client4.com", priority = 103 },
  "client5" = { domain = "client5.com", priority = 104 }
}

# 5 Static Domains
static_client_configs = {
  "static1" = { domain_name = "static1.com" },
  "static2" = { domain_name = "static2.com" },
  "static3" = { domain_name = "static3.com" },
  "static4" = { domain_name = "static4.com" },
  "static5" = { domain_name = "static5.com" }
}
```

### Apply

```bash
terraform apply
```

### Resources Created

| Resource Type | Count | Notes |
|---------------|-------|-------|
| Route53 Hosted Zones | 10 | 1 per domain |
| ACM Certificate SANs | 20 | domain + wildcard |
| DNS Validation Records | 20 | 1 per SAN |
| ALB Alias Records | 5 | Dynamic domains |
| CloudFront Distributions | 5 | Static domains |
| CloudFront Alias Records | 5 | Static domains |
| S3 Buckets | 5 | Static content |
| **Total** | **70** | **Automatic** |

---

## 🔍 Troubleshooting

### Issue: ACM Validation Stuck

**Symptom:** Certificate validation takes > 30 minutes

**Solution:**

1. Check validation records exist:
```bash
aws route53 list-resource-record-sets \
  --hosted-zone-id <zone-id> \
  --query "ResourceRecordSets[?Type=='CNAME']"
```

2. Verify nameservers are delegated correctly

3. Wait up to 60 minutes (AWS can be slow)

---

### Issue: CloudFront Distribution Fails

**Symptom:** `InvalidViewerCertificate` error

**Solution:**

1. Verify certificate is in `us-east-1`:
```bash
aws acm describe-certificate \
  --certificate-arn <arn> \
  --region us-east-1
```

2. Increase wait time in `modules/static_hosting/main.tf`:
```hcl
resource "time_sleep" "wait_for_acm_propagation" {
  create_duration = "120s"  # Increase from 60s
}
```

3. Re-apply:
```bash
terraform apply
```

---

### Issue: Wrong Alias Record Created

**Symptom:** Static domain points to ALB or vice versa

**Solution:**

1. Check domain type in Terraform console:
```bash
terraform console
> local.all_domains
```

2. Verify output shows correct type:
```hcl
{
  "sree84s" = {
    domain = "sree84s.site"
    type   = "dynamic"  ← Should be "dynamic" for ALB
  }
  "clavio" = {
    domain = "clavio.store"
    type   = "static"   ← Should be "static" for CloudFront
  }
}
```

3. If incorrect, check `terraform.tfvars` syntax

---

## 📚 Documentation Reference

| Document | Purpose |
|----------|---------|
| `SCALING_ARCHITECTURE.md` | Detailed architecture explanation |
| `SCALING_CODE_REFERENCE.md` | Code snippets and examples |
| `SCALING_VISUAL_DIAGRAM.md` | ASCII diagrams |
| `SCALING_IMPLEMENTATION_SUMMARY.md` | Implementation summary |
| `QUICK_START_GUIDE.md` | This file |

---

## 🎯 Next Steps

### Immediate (Today)
- [ ] Run `terraform plan` to review changes
- [ ] Run `terraform apply` to deploy
- [ ] Verify resources created successfully
- [ ] Test domain resolution

### Short-term (This Week)
- [ ] Add 2-3 test domains
- [ ] Monitor ACM certificate validation time
- [ ] Document nameserver delegation process
- [ ] Set up CloudWatch alarms

### Long-term (This Month)
- [ ] Request ACM SAN limit increase (if planning 100+ domains)
- [ ] Implement CI/CD pipeline for domain addition
- [ ] Create runbook for common issues
- [ ] Set up automated monitoring

---

## 🚨 Important Notes

### ACM Certificate Limits

- **Default limit:** 100 SANs per certificate
- **Each domain uses 2 SANs:** domain + wildcard
- **Max domains (default):** 50 domains per certificate
- **Request increase:** Via AWS Support for 1000+ SANs

### Priority Management

- **Range:** 1-999
- **Recommendation:** Start at 100, increment by 1
- **Reserved:** 1-99 for system rules
- **Avoid conflicts:** Each priority must be unique

### Nameserver Delegation

After creating a hosted zone, you MUST delegate nameservers at your domain registrar:

1. Get nameservers from Route53
2. Update at domain registrar (GoDaddy, Namecheap, etc.)
3. Wait 24-48 hours for DNS propagation
4. Verify with: `dig NS yourdomain.com`

---

## ✅ Success Criteria

Your deployment is successful when:

- [x] `terraform validate` passes
- [ ] `terraform apply` completes without errors
- [ ] All hosted zones created
- [ ] ACM certificate includes all domains
- [ ] Alias records point to correct targets
- [ ] Domains resolve correctly (after nameserver delegation)

---

## 📞 Support

Need help?

1. **Check documentation:** Review the 4 scaling docs
2. **Use Terraform console:** Debug with `terraform console`
3. **Check AWS Console:** Verify resources manually
4. **Review logs:** CloudWatch logs for errors
5. **Contact team:** Infrastructure team for assistance

---

## 🎉 You're Ready!

Your infrastructure now supports:
- ✅ Automatic domain scaling
- ✅ Conditional routing (ALB vs CloudFront)
- ✅ Single ACM certificate for all domains
- ✅ Zero manual intervention
- ✅ Production-ready architecture

**Run `terraform apply` to deploy!** 🚀

---

**Last Updated:** 2026-02-08  
**Version:** 2.0 - Unified Scaling Architecture
