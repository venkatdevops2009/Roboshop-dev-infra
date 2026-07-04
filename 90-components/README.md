# 90-components — All Application Components

**Order: 10th (last)**

## Purpose
Deploys **every** RoboShop application component using a single reusable module,
[`terraform-roboshop-component`](https://github.com/daws-90s/terraform-roboshop-component).
This is the generalised version of the `60-catalogue` example: instead of writing
the golden-AMI + ASG resources by hand for each service, it calls one module in a
loop.

## What it creates
([main.tf](./main.tf))
- A `module "components"` with `for_each = var.components`, so each entry in the
  map becomes a full component deployment (build instance → golden AMI → launch
  template → target group → ASG → ALB listener rule).
- Components and their settings live in [variables.tf](./variables.tf):

  | Component | rule_priority | app_version |
  |-----------|---------------|-------------|
  | catalogue | 10 | v3 |
  | user | 20 | v3 |
  | cart | 30 | v3 |
  | shipping | 40 | v3 |
  | payment | 50 | v3 |
  | frontend | 10 | v3 |

  `rule_priority` = the listener-rule priority on the ALB. `app_version` = which
  app build to deploy.

## Depends on
Effectively **everything before it**: the network (00), SGs + rules (10/20),
databases (40), the backend ALB (50) for backend services, and the ACM cert +
frontend ALB (70/80) for the frontend. The module reads the values it needs from
SSM internally.

## Consumed by
Nothing — this is the top of the stack (the running application).

## Run
```bash
terraform init && terraform apply
```
> To add/remove a component or bump a version, edit the `components` map in
> `variables.tf` and re-apply.
