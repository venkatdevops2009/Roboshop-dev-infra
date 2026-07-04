# 70-acm — TLS Certificate (ACM)

**Order: 8th**

## Purpose
Requests and validates a **wildcard TLS certificate** for `*.daws90s.shop` so the
public frontend ALB can serve HTTPS.

## What it creates
([main.tf](./main.tf))
- `aws_acm_certificate` for `*.daws90s.shop` with **DNS validation**.
- Route53 validation records (created automatically from the cert's
  `domain_validation_options`).
- `aws_acm_certificate_validation` — waits until the certificate is issued.
- The validated certificate ARN stored in SSM `/roboshop/dev/certificate_arn`
  ([parameters.tf](./parameters.tf)).

## Depends on
- A Route53 hosted zone for `daws90s.shop` (zone id in [variables.tf](./variables.tf)).
- No dependency on the other numbered layers, but it must exist **before**
  `80-frontend-alb`.

## Consumed by
- `80-frontend-alb` → reads `/roboshop/dev/certificate_arn` for its HTTPS listener.

## Run
```bash
terraform init && terraform apply
```
