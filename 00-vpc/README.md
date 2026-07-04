# 00-vpc — Network Foundation

**Order: 1st (run this before everything else)**

## Purpose
Creates the network everything else lives in: the VPC, public / private /
database subnets across AZs, internet & NAT gateways, and route tables. This is
done by calling the reusable module
[`terraform-aws-vpc`](https://github.com/daws-90s/terraform-aws-vpc).

## What it creates
- 1 VPC + subnets (public, private, database) — via the `vpc` module
  ([main.tf](./main.tf)). `is_peering_required = false` here (no peering).
- SSM parameters so later layers can find the network ([parameters.tf](./parameters.tf)):
  - `/roboshop/dev/vpc_id`
  - `/roboshop/dev/public_subnet_ids`
  - `/roboshop/dev/private_subnet_ids`
  - `/roboshop/dev/database_subnet_ids`

## Depends on
Nothing — this is the first layer.

## Consumed by
Almost every later layer reads `vpc_id` and/or the subnet IDs from SSM
(10-sg, 30-bastion, 40-databases, 50-backend-alb, 60-catalogue, 80-frontend-alb).

## Run
```bash
terraform init && terraform apply
```
