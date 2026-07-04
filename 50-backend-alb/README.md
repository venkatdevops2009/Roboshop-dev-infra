# 50-backend-alb — Internal Backend Load Balancer

**Order: 6th**

## Purpose
Creates an **internal** (private) Application Load Balancer that sits in front of
all the backend services (catalogue, user, cart, shipping, payment). Backend
components register themselves against this ALB's listener.

## What it creates
([main.tf](./main.tf))
- An **internal** ALB in the private subnets with the `backend_alb` SG.
- An HTTP :80 listener with a default "fixed-response" (placeholder). Real
  routing rules are added later by each component.
- A Route53 wildcard record `*.backend-alb-dev.daws90s.shop` pointing at the ALB.
- The listener ARN stored in SSM `/roboshop/dev/backend_alb_listener_arn`
  ([parameters.tf](./parameters.tf)).

## Depends on
- `00-vpc` → `private_subnet_ids`
- `10-sg` → `backend_alb_sg_id` ([data.tf](./data.tf)).

## Consumed by
- `60-catalogue` and `90-components` — each component adds an
  `aws_lb_listener_rule` to this listener (via the stored listener ARN) so the
  ALB routes `<component>.backend-alb-dev.daws90s.shop` to its target group.

## Run
```bash
terraform init && terraform apply
```
