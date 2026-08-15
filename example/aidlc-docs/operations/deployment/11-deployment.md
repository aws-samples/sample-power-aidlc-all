# Phase 11 — Deployment Automation and Infrastructure (Example)

> **Group:** Operations · **Greenfield phase 10 / Brownfield phase 11**
> **Purpose:** Automate deployment and provision infrastructure.

## 1. Target infrastructure (AWS, example)

| Component | Service |
|-----------|---------|
| SPA hosting | S3 + CloudFront (CDN) |
| API + worker | ECS Fargate behind an ALB |
| Database | RDS PostgreSQL (Multi-AZ) |
| Cache / queue | ElastiCache for Redis |
| Secrets | AWS Secrets Manager |

## 2. Infrastructure as code (example `infra/main.tf`)

```hcl
module "api" {
  source        = "./modules/ecs-service"
  name          = "taskflow-api"
  image         = var.api_image
  desired_count = 2            # stateless -> scale horizontally (NFR-4)
  cpu           = 512
  memory        = 1024
}
```

## 3. CI/CD deploy pipeline

```
build & test (CI)  ->  build images  ->  push to ECR
   ->  terraform apply (infra)  ->  ECS rolling deploy  ->  smoke test
```

- **Strategy:** blue/green via ECS with health-check gating.
- **Migrations:** run as a one-off ECS task before the new version takes traffic.
- **Rollback:** shift traffic back to the previous target group.

## 4. Environments

- `dev` → auto-deploy on merge to main.
- `prod` → manual approval gate, then automated rollout.

## 5. Feature flags

Auth/Redis (R-1) and reminders (UoW-E) ship behind flags for gradual rollout.
