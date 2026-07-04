# RoboShop Dev Infrastructure (Terraform)

This repository builds the **complete AWS infrastructure** for the RoboShop
application in the `dev` environment using Terraform.

It is split into **numbered folders**. Each folder is an **independent Terraform
root module** (it has its own `provider.tf`, its own remote state file in S3, and
you run `terraform apply` inside it separately). The number is the **order** in
which you must run them, because later layers depend on things created by
earlier layers.

---

## The big idea: how the layers talk to each other

The folders never read each other's state directly. Instead they use **AWS SSM
Parameter Store** as a shared "notice board":

- An **early** layer creates a resource (e.g. the VPC) and **writes** its ID to
  SSM, e.g. `/roboshop/dev/vpc_id`.
- A **later** layer **reads** that value from SSM (via a `data` source) when it
  needs it.

```
00-vpc  --writes-->  /roboshop/dev/vpc_id  --read by-->  10-sg, 60-catalogue ...
10-sg   --writes-->  /roboshop/dev/<name>_sg_id --read by--> 20-sg-rules, 30-bastion, 40-databases ...
```

This keeps every layer **loosely coupled** — you can destroy and recreate one
layer without touching the others, as long as the SSM parameters stay in place.

Naming convention for every parameter: `/<project>/<environment>/<key>`, e.g.
`/roboshop/dev/vpc_id`. `project` defaults to `roboshop` and `environment` to
`dev` (see each folder's `variables.tf`).

---

## Remote state

Every folder stores its state in the S3 bucket `remote-state-90s-dev` with a
**unique key** (see each `provider.tf`), and uses native S3 lock files. This
means each layer has its own isolated state file:

| Folder | State key |
|--------|-----------|
| 00-vpc | roboshop-vpc.tfstate |
| 10-sg | roboshop-sg.tfstate |
| 20-sg-rules | roboshop-sg-rules.tfstate |
| 30-bastion | roboshop-bastion.tfstate |
| 40-databases | roboshop-databases.tfstate |
| 50-backend-alb | roboshop-backend-alb.tfstate |
| 60-catalogue | roboshop-catalogue.tfstate |
| 70-acm | roboshop-acm.tfstate |
| 80-frontend-alb | roboshop-frontend-alb.tfstate |
| 90-components | roboshop-components.tfstate |

---

## Deployment order (apply top to bottom)

| # | Folder | Purpose |
|---|--------|---------|
| 1 | [00-vpc](./00-vpc) | Network foundation: VPC, subnets, NAT, peering. Publishes VPC & subnet IDs to SSM. |
| 2 | [10-sg](./10-sg) | Creates one security group per component. Publishes each SG ID to SSM. |
| 3 | [20-sg-rules](./20-sg-rules) | Adds the ingress rules that wire the security groups together. |
| 4 | [30-bastion](./30-bastion) | Jump host in a public subnet, used to reach private instances. |
| 5 | [40-databases](./40-databases) | MongoDB, Redis, RabbitMQ, MySQL instances + DNS records + MySQL password. |
| 6 | [50-backend-alb](./50-backend-alb) | Internal ALB for backend services. Publishes its listener ARN. |
| 7 | [60-catalogue](./60-catalogue) | Reference example of the "golden AMI + Auto Scaling Group" pattern for one service. |
| 8 | [70-acm](./70-acm) | Wildcard TLS certificate (ACM) for `*.daws90s.shop`. |
| 9 | [80-frontend-alb](./80-frontend-alb) | Internet-facing HTTPS ALB using the ACM certificate. |
| 10 | [90-components](./90-components) | Deploys **all** app components (catalogue, user, cart, shipping, payment, frontend) using a reusable module. |

> **Note on 60-catalogue vs 90-components:** `60-catalogue` is a hand-written,
> single-service example so you can *see* every resource in the golden-AMI/ASG
> pattern. `90-components` does the same thing for *every* service by calling a
> shared module in a loop. In a real deployment you would normally use seperate repos for each component.

---

## ⚠️ Things you MUST change before running (use your OWN values)

This repo is wired to the trainer's AWS account. **Before you `terraform apply`,
replace these two things with your own**, or your deployment will fail (or worse,
try to touch resources you don't own):

### 1. S3 remote-state bucket
The current bucket `remote-state-90s-dev` is hardcoded in **every**
`provider.tf`. S3 bucket names are **globally unique**, so you cannot reuse it —
create your own bucket and put its name in all 10 `provider.tf` files.

```hcl
# in every <folder>/provider.tf
backend "s3" {
  bucket       = "remote-state-90s-dev"   # <-- change to YOUR bucket name
  key          = "roboshop-vpc.tfstate"   # leave the key as-is (unique per folder)
  region       = "us-east-1"
  encrypt      = true
  use_lockfile = true
}
```

Quick way to change all of them at once (run from the repo root):
```bash
# replace with your bucket name
grep -rl "remote-state-90s-dev" . --include=provider.tf \
  | xargs sed -i 's/remote-state-90s-dev/YOUR-BUCKET-NAME/g'
```

### 2. Domain name + Route53 hosted zone
The domain `daws90s.shop` and hosted-zone id `Z07086101C1CVP7AT2UK4` are used for
all DNS records and the ACM certificate. Replace both with your own registered
domain and its zone id. They appear as:

- `variable "domain_name"` (default `daws90s.shop`) — in `40-databases`,
  `60-catalogue`, `70-acm`, `80-frontend-alb`, `90-components` `variables.tf`.
- `variable "zone_id"` (default `Z07086101C1CVP7AT2UK4`) — same folders.
- A few **hardcoded** `daws90s.shop` strings inside `main.tf` of `50-backend-alb`
  and `80-frontend-alb` (the wildcard/A records) — change those too.

```bash
# from repo root, after registering your domain + finding its zone id
grep -rl "daws90s.shop" . --include=*.tf \
  | xargs sed -i 's/daws90s.shop/your-domain.com/g'
# then edit the zone_id defaults to your hosted zone id
```

> After changing the domain, the app URLs also change, e.g.
> `roboshop-dev.daws90s.shop` → `roboshop-dev.your-domain.com`.

---

## How to run a single layer

```bash
cd 00-vpc
terraform init      # downloads providers + configures S3 backend
terraform plan      # preview changes
terraform apply     # create/update resources
```

Repeat for each folder **in order**. To tear everything down, run
`terraform destroy` in **reverse** order (90 → 00).

---

## Prerequisites

- Terraform >= 1.10 and AWS credentials configured (the S3 backend uses
  `use_lockfile`, a 1.10+ feature).
- **Your own** S3 bucket for remote state (must already exist) — see the
  **"Things you MUST change before running"** section above.
- **Your own** registered domain + Route53 hosted zone — see the same section.
- Reusable modules live in separate GitHub repos under the
  [`daws-90s`](https://github.com/daws-90s) org (VPC, SG, and component modules).

---

## Repo conventions (you'll see these in every folder)

- `provider.tf` — AWS provider version + S3 remote-state backend config.
- `variables.tf` — inputs, almost always `project=roboshop`, `environment=dev`.
- `data.tf` — reads values published by earlier layers (mostly from SSM).
- `locals.tf` — tidies those data values into short local names + `common_tags`.
- `main.tf` — the actual resources for this layer.
- `parameters.tf` — writes this layer's outputs **into SSM** for later layers.
- `outputs.tf` — optional Terraform outputs (printed after apply).
