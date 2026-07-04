# 80-frontend-alb — Public HTTPS Load Balancer

**Order: 9th**

## Purpose
Creates the **internet-facing** Application Load Balancer that users hit in their
browser. It terminates HTTPS using the ACM certificate from `70-acm`.

## What it creates
([main.tf](./main.tf))
- An **external** ALB in the public subnets with the `frontend_alb` SG.
- An HTTPS :443 listener using the ACM certificate, with a placeholder
  fixed-response (the frontend component adds the real routing rule).
- A Route53 A-record `roboshop-dev.daws90s.shop` → the ALB.
- The listener ARN stored in SSM `/roboshop/dev/frontend_alb_listener_arn`
  ([parameters.tf](./parameters.tf)).

## Depends on
- `00-vpc` → `public_subnet_ids`
- `10-sg` → `frontend_alb_sg_id`
- `70-acm` → `certificate_arn` ([data.tf](./data.tf)).

## Consumed by
- The `frontend` component (in `90-components`) attaches a listener rule to this
  listener.

## Run
```bash
terraform init && terraform apply
```
