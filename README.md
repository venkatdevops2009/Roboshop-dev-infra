# RoboShop Dev Infrastructure (Terraform)

This repository builds the **complete AWS infrastructure** for the RoboShop multi-tier e-commerce application in the `dev` environment using Terraform.

It is split into **numbered folders**. Each folder is an **independent Terraform root module** (it has its own `provider.tf`, its own remote state file in S3, and you run `terraform apply` inside it separately). The number is the **order** in which you must run them, because later layers depend on things created by earlier layers.

---

## The big idea: how the layers talk to each other

The folders never read each other's state directly. Instead they use **AWS SSM Parameter Store** as a shared "notice board":

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

| Folder | State key | Purpose |
|--------|-----------|---------|
| 00-vpc | roboshop-vpc.tfstate | Network foundation |
| 10-sg | roboshop-sg.tfstate | Security groups |
| 20-sg-rules | roboshop-sg-rules.tfstate | Security group rules |
| 30-bastion | roboshop-bastion.tfstate | Bastion host |
| 40-databases | roboshop-databases.tfstate | Database instances |
| 50-backend-alb | roboshop-backend-alb.tfstate | Backend load balancer |
| 60-catalogue | roboshop-catalogue.tfstate | Golden AMI example |
| 70-acm | roboshop-acm.tfstate | TLS certificate |
| 80-frontend-alb | roboshop-frontend-alb.tfstate | Frontend load balancer |
| 90-components | roboshop-components.tfstate | All app components |
| 95-cdn | roboshop-cdn.tfstate | CloudFront CDN |

---

## Deployment order (apply top to bottom)

| # | Folder | Purpose |
|---|--------|---------|
| 1 | [00-vpc](./00-vpc) | **Network foundation:** VPC, public/private/database subnets across AZs, internet & NAT gateways, route tables. Publishes VPC & subnet IDs to SSM. |
| 2 | [10-sg](./10-sg) | **Security groups:** Creates one empty SG per component (mongodb, redis, mysql, rabbitmq, catalogue, user, cart, shipping, payment, backend_alb, frontend, frontend_alb, bastion). Publishes each SG ID to SSM. |
| 3 | [20-sg-rules](./20-sg-rules) | **SG ingress rules:** Adds allow-rules that wire the security groups together, avoiding circular dependencies. |
| 4 | [30-bastion](./30-bastion) | **Bastion host:** Jump server in a public subnet for SSH access to private instances. |
| 5 | [40-databases](./40-databases) | **Database instances:** EC2-based MongoDB, Redis, RabbitMQ, and MySQL instances with provisioning scripts, plus Route53 DNS records and MySQL password storage in Secrets Manager. |
| 6 | [50-backend-alb](./50-backend-alb) | **Backend load balancer:** Internal Application Load Balancer for routing backend service traffic. Publishes listener ARN to SSM. |
| 7 | [60-catalogue](./60-catalogue) | **Reference golden AMI pattern:** Hand-written single-service example demonstrating the full "golden AMI + Launch Template + Auto Scaling Group" pattern for the catalogue service, including target group and listener rule. |
| 8 | [70-acm](./70-acm) | **TLS certificate:** Wildcard ACM certificate for `*.daws90s.shop` domain. |
| 9 | [80-frontend-alb](./80-frontend-alb) | **Frontend load balancer:** Internet-facing HTTPS ALB with ACM certificate, handles external traffic and routes to frontend. |
| 10 | [90-components](./90-components) | **All app components:** Deploys **all** services (catalogue, user, cart, shipping, payment, frontend) using a reusable Terraform module called in a `for_each` loop, parameterized by app version and ALB rule priority. |
| 11 | [95-cdn](./95-cdn) | **CloudFront CDN:** CloudFront distribution with caching policies for `/media/*` and `/videos/*` paths, HTTPS enforcement, and Route53 alias record pointing to CDN domain. |

> **Note on 60-catalogue vs 90-components:** `60-catalogue` is a hand-written,
> single-service example so you can *see* every resource in the golden-AMI/ASG
> pattern. `90-components` does the same thing for *every* service by calling a
> shared module in a loop. In a real deployment you would normally use separate repos for each component.

---

## Architecture overview

### Infrastructure layers

1. **Networking (00-vpc):** Base VPC with public/private/database subnets across 3 AZs, NAT gateways, and internet gateway.

2. **Security (10-sg, 20-sg-rules):** Security groups per component with carefully defined ingress/egress rules to enforce least privilege.

3. **Bastion (30-bastion):** SSH jump host for accessing private instances.

4. **Data layer (40-databases):** 
   - MongoDB (NoSQL, product catalog)
   - Redis (in-memory cache, cart)
   - RabbitMQ (message broker, async tasks)
   - MySQL (relational DB, user orders)
   - All provisioned with bootstrap scripts

5. **Load balancing (50-backend-alb, 80-frontend-alb):**
   - Internal ALB for inter-service communication (backend)
   - Public HTTPS ALB for client traffic (frontend)

6. **Application services (60-catalogue example, 90-components production):**
   - Golden AMI pattern: EC2 → provision with scripts → AMI → Launch Template → Auto Scaling Group
   - Each service auto-scales based on CPU utilization (target: 75%)
   - Each has target groups and ALB listener rules for traffic routing

7. **CDN (95-cdn):** 
   - CloudFront distribution fronting the public ALB
   - Static content cached at edge (media, videos)
   - Dynamic requests bypass cache
   - HTTPS-only enforcement

### Data flow

```
Internet → CloudFront (95-cdn) → Frontend ALB (80) → Frontend Service (90)
                                      ↓
                            Backend ALB (50) ← Catalogue/User/Cart/etc (90)
                                      ↓
                    Databases (40): MongoDB, Redis, RabbitMQ, MySQL
```

---

## ⚠️ Things you MUST change before running (use your OWN values)

This repo is wired to the trainer's AWS account. **Before you `terraform apply`,
replace these two things with your own**, or your deployment will fail (or worse,
try to touch resources you don't own):

### 1. S3 remote-state bucket

The current bucket `remote-state-90s-dev` is hardcoded in **every**
`provider.tf`. S3 bucket names are **globally unique**, so you cannot reuse it —
create your own bucket and put its name in all 11 `provider.tf` files.

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
grep -rl "remote-state-90s-dev" . --include="provider.tf" \
  | xargs sed -i 's/remote-state-90s-dev/YOUR-BUCKET-NAME/g'
```

### 2. Domain name + Route53 hosted zone

The domain `daws90s.shop` and hosted-zone id `Z07086101C1CVP7AT2UK4` are used for
all DNS records and the ACM certificate. Replace both with your own registered
domain and its zone id. They appear as:

- `variable "domain_name"` (default `daws90s.shop`) — in `40-databases`,
  `60-catalogue`, `70-acm`, `80-frontend-alb`, `90-components`, `95-cdn` `variables.tf`.
- `variable "zone_id"` (default `Z07086101C1CVP7AT2UK4`) — same folders.
- A few **hardcoded** `daws90s.shop` strings inside `main.tf` of `50-backend-alb`,
  `80-frontend-alb`, and `95-cdn` (the wildcard/A records) — change those too.

```bash
# from repo root, after registering your domain + finding its zone id
grep -rl "daws90s.shop" . --include="*.tf" \
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
`terraform destroy` in **reverse** order (95 → 00).

---

## Automated deployment with Jenkins

A [Jenkinsfile](./Jenkinsfile) orchestrates multi-stage Terraform deployments. It:

- Accepts `plan`, `apply`, or `destroy` actions via parameter
- Applies layers in order: 40-databases → 50-backend-alb → 70-acm → 80-frontend-alb → 90-components → 95-cdn
- Requires manual approval for `apply` and `destroy`
- Reverses the order for `destroy` (95 → 40)

**Note:** The Jenkinsfile only covers layers 40-95; layers 00-30 (VPC, SGs, bastion) must be set up manually or in a separate pipeline.

---

## Prerequisites

- **Terraform >= 1.10** (for `use_lockfile` in S3 backend)
- **AWS credentials** configured (via `~/.aws/credentials`, environment variables, or IAM role)
- **Your own S3 bucket** for remote state (must already exist) — see the **"Things you MUST change"** section
- **Your own registered domain** + Route53 hosted zone — see the same section
- Reusable Terraform modules from the [`daws-90s`](https://github.com/daws-90s) GitHub org:
  - [`terraform-aws-vpc`](https://github.com/daws-90s/terraform-aws-vpc) — VPC module
  - [`terraform-aws-sg`](https://github.com/daws-90s/terraform-aws-sg) — Security group module
  - [`terraform-roboshop-component`](https://github.com/daws-90s/terraform-roboshop-component) — Service deployment module

---

## Repo conventions (you'll see these in every folder)

- **`provider.tf`** — AWS provider version + S3 remote-state backend config
- **`variables.tf`** — input variables, usually `project=roboshop`, `environment=dev`, domain/zone for DNS
- **`data.tf`** — reads values published by earlier layers via SSM Parameter Store
- **`locals.tf`** — local variables tidying up data sources into short names + `common_tags`
- **`main.tf`** — actual AWS resources (EC2, ALB, ASG, CloudFront, etc.)
- **`parameters.tf`** — writes this layer's outputs into SSM for later layers to consume
- **`outputs.tf`** — optional Terraform outputs (printed after `terraform apply`)

---

## Common workflows

### Deploy from scratch
```bash
for dir in 00-vpc 10-sg 20-sg-rules 30-bastion 40-databases 50-backend-alb 60-catalogue 70-acm 80-frontend-alb 90-components 95-cdn; do
  (cd $dir && terraform init && terraform apply)
done
```

### Destroy everything
```bash
for dir in 95-cdn 90-components 80-frontend-alb 70-acm 60-catalogue 50-backend-alb 40-databases 30-bastion 20-sg-rules 10-sg 00-vpc; do
  (cd $dir && terraform destroy -auto-approve)
done
```

### Update a single service (e.g., catalogue version bump)
```bash
cd 60-catalogue
terraform apply -var="app_version=v2"
```

Or for all components:
```bash
cd 90-components
terraform apply -var-file=my-versions.tfvars
```

### Troubleshooting state issues

If layers get out of sync or you need to recover:
```bash
# Check state of one layer
cd 40-databases
terraform state list
terraform state show aws_instance.mongodb

# Manually fix (rare)
terraform state rm aws_instance.mongodb  # dangerous!
terraform import aws_instance.mongodb i-0abc1234  # recover from AWS
```

---

## FAQ

**Q: Can I run layers in parallel?**  
A: No, each layer depends on SSM parameters written by earlier ones. Run them sequentially.

**Q: What if I destroy just one layer?**  
A: Later layers may break if they depend on resources from that layer. The SSM parameters remain, so if you recreate it, dependent layers should work again.

**Q: How do I add a new microservice?**  
A: Add it to the `var.components` map in `90-components/terraform.tfvars`, or use a separate module + layer file (best practice).

**Q: Why is 60-catalogue separate from 90-components?**  
A: 60-catalogue is an educational reference showing every step of the golden AMI pattern. 90-components applies the pattern at scale using a reusable module.

**Q: How does auto-scaling work?**  
A: Each service's Auto Scaling Group targets 75% CPU utilization. ASG launches/terminates instances to maintain that target.

---

## Resources

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest)
- [AWS VPC Best Practices](https://docs.aws.amazon.com/vpc/latest/userguide/)
- [AWS Security Groups](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_SecurityGroups.html)
- [AWS SSM Parameter Store](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html)
- [AWS Application Load Balancer](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/)
- [AWS Auto Scaling](https://docs.aws.amazon.com/autoscaling/ec2/userguide/)
- [CloudFront Distribution](https://docs.aws.amazon.com/cloudfront/latest/developerguide/)
