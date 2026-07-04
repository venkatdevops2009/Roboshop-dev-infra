# 20-sg-rules — Security Group Rules (the wiring)

**Order: 3rd**

## Purpose
Adds the **ingress rules** that decide *who can talk to whom*. Each rule allows
traffic **from** one security group **to** another on a specific port. This is
where the network security of RoboShop actually lives.

## What it creates
Individual `aws_security_group_rule` resources ([main.tf](./main.tf)), for example:
- MongoDB (27017) ← catalogue, user
- Redis (6379) ← user, cart
- MySQL (3306) ← shipping
- RabbitMQ (5672) ← payment
- Each app component (8080) ← backend ALB
- Backend ALB (80) ← frontend + each component
- Frontend (80) ← frontend ALB
- Frontend ALB (443/80) ← the whole internet (`0.0.0.0/0`)
- Bastion (22) ← **your current public IP only** (looked up live via
  `https://ipv4.icanhazip.com`)
- SSH (22) into every private SG ← bastion

## Depends on
- `10-sg` → reads **every** `*_sg_id` from SSM ([data.tf](./data.tf), [locals.tf](./locals.tf)).

## Consumed by
Nothing writes back here — this layer only attaches rules to existing SGs.

## Run
```bash
terraform init && terraform apply
```
> Tip: because the bastion rule uses *your* public IP, re-apply if your IP
> changes and you lose SSH access to the bastion.
