# 10-sg — Security Groups

**Order: 2nd**

## Purpose
Creates one **empty** security group (SG) for every component in the system. It
only creates the SGs here — the actual allow-rules are added in the next layer
(`20-sg-rules`). Splitting "create SG" from "add rules" avoids circular
dependencies (rules often reference two SGs that must both exist first).

## What it creates
- One SG per name in `var.sg_names` ([variables.tf](./variables.tf)), using the
  reusable [`terraform-aws-sg`](https://github.com/daws-90s/terraform-aws-sg)
  module with `count` ([main.tf](./main.tf)). The list covers:
  `mongodb, redis, mysql, rabbitmq, catalogue, user, cart, shipping, payment,
  backend_alb, frontend, frontend_alb, bastion`.
- One SSM parameter per SG holding its ID ([parameters.tf](./parameters.tf)):
  `/roboshop/dev/<name>_sg_id` (e.g. `/roboshop/dev/mongodb_sg_id`).

## Depends on
- `00-vpc` → reads `/roboshop/dev/vpc_id` ([data.tf](./data.tf)).

## Consumed by
- `20-sg-rules` (needs all SG IDs to wire rules)
- `30-bastion`, `40-databases`, `50-backend-alb`, `60-catalogue`, `80-frontend-alb`
  (each attaches its own SG).

## Run
```bash
terraform init && terraform apply
```
