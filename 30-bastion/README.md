# 30-bastion — Bastion / Jump Host

**Order: 4th**

## Purpose
Creates a small EC2 instance in a **public** subnet that you SSH into to reach
the **private** instances (databases, app servers) that have no public IP. It
also has Terraform pre-installed and admin rights, so it can be used as a
"control" box.

## What it creates
- An EC2 instance in the first public subnet using the `Redhat-9-DevOps-Practice`
  AMI, `t3.micro`, with a 50GB root + resized `/home` ([main.tf](./main.tf),
  [bastion.sh.tftpl](./bastion.sh.tftpl)).
- An IAM role + instance profile with **AdministratorAccess** ([iam.tf](./iam.tf)).
- `user_data` (from `bastion.sh.tftpl`) that grows the disk partition and
  installs Terraform on first boot.

## Depends on
- `00-vpc` → `public_subnet_ids`
- `10-sg` → `bastion_sg_id`
- `20-sg-rules` → so SSH (22) from your IP is actually allowed
  ([data.tf](./data.tf)).

## Consumed by
Not consumed by other layers directly — it's an operator tool. Databases/app
SGs already allow SSH *from* the bastion SG (set up in `20-sg-rules`).

## Run
```bash
terraform init && terraform apply
```
