# 40-databases — Database & Messaging Tier

**Order: 5th**

## Purpose
Creates the stateful backends RoboShop needs: **MongoDB, Redis, RabbitMQ and
MySQL**. Each is an EC2 instance in a **database** subnet, configured
automatically with Ansible, and given a friendly DNS name.

## What it creates
For each of mongodb / redis / rabbitmq / mysql ([main.tf](./main.tf)):
- An EC2 instance in a database subnet with its own SG.
- A `terraform_data` provisioner that copies `bootstrap.sh` to the instance and
  runs it. `bootstrap.sh` installs Ansible, clones `roboshop-ansible-v3`, and
  runs the playbook for that component ([bootstrap.sh](./bootstrap.sh)).
- A Route53 A-record, e.g. `mysql-dev.daws90s.shop` ([r53.tf](./r53.tf)).

MySQL also gets:
- An IAM role/profile allowing it to **read its root password from SSM**
  ([iam.tf](./iam.tf), `mysql-iam-policy.json`).
- The root password stored in SSM as a **SecureString**
  `/roboshop/dev/mysql_root_password` ([parameters.tf](./parameters.tf)), fed
  from `var.mysql_root_password` in [terraform.tfvars](./terraform.tfvars).

## Depends on
- `00-vpc` → `database_subnet_ids`
- `10-sg` → the four database SG IDs
- `20-sg-rules` → so app components can reach the DB ports ([data.tf](./data.tf)).

## Consumed by
- App components (in `90-components` and the `roboshop-ansible-v3` playbooks)
  connect using the DNS names above and, for shipping, the
  `/roboshop/dev/mysql_root_password` parameter.

## Run
```bash
terraform init && terraform apply
```
> `terraform.tfvars` sets `mysql_root_password`. Keep this value in sync with
> whatever the app roles use to log into MySQL.
