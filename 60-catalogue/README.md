# 60-catalogue — Reference Example: Golden AMI + Auto Scaling Group

**Order: 7th** — *teaching example; see the note below*

## Purpose
A **fully hand-written example** of how ONE app service is deployed end-to-end.
Study this folder to understand the pattern; `90-components` then does the same
thing for every service using a shared module.

## The pattern (all in [main.tf](./main.tf))
1. **Build instance** — launch a temporary EC2 instance and configure it with
   Ansible via `bootstrap.sh` (`sudo sh bootstrap.sh catalogue dev v3`).
2. **Stop it** — `aws_ec2_instance_state` stops the instance cleanly.
3. **Bake a golden AMI** — `aws_ami_from_instance` snapshots the configured
   instance into a reusable image.
4. **Launch template** — points at the new AMI.
5. **Target group** — health-checked on `/health` :8080.
6. **Auto Scaling Group** — min 1 / desired 2 / max 10, rolling instance refresh.
7. **Scaling policy** — target-tracking on 75% average CPU.
8. **Listener rule** — routes `catalogue.backend-alb-dev.daws90s.shop` on the
   backend ALB to this target group.
9. **Cleanup** — a `local-exec` terminates the original temporary build instance.

## Depends on
- `00-vpc` (`vpc_id`, `private_subnet_ids`)
- `10-sg` (`catalogue_sg_id`)
- `50-backend-alb` (`backend_alb_listener_arn`) ([data.tf](./data.tf)).

## Note — 60-catalogue vs 90-components
This folder and `90-components` overlap on purpose. `60-catalogue` is the
"read every line" teaching version for a single service. `90-components`
generalises it into a loop over all services. In a real run you'd typically use
one or the other — not both — to avoid two ASGs for catalogue.

## Run
```bash
terraform init && terraform apply
```
