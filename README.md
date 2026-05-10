# go-app-devops

Infrastructure as Code (Terraform) + Helm chart + ArgoCD GitOps configuration for deploying the [go-portfolio](https://github.com/cs365-project/go-portfolio) application on Amazon EKS.

## Overview

This repository has two responsibilities:
1. **Provision cloud infrastructure** — VPC, EKS cluster, IAM roles, Jump Server via Terraform (applied through GitHub Actions)
2. **Define application deployment** — Helm chart consumed by ArgoCD for GitOps continuous delivery

## Architecture

```
GitHub Actions (terraform.yml)
    │
    ├── bootstrap  → create S3 bucket + DynamoDB table (remote state)
    ├── plan       → terraform plan (runs on PR / push to develop)
    ├── apply      → terraform apply + auto-install ArgoCD + sync app
    └── destroy    → terraform destroy

                    AWS Cloud (us-east-1)
                    ┌─────────────────────────────────────┐
                    │  VPC (10.0.0.0/16)                  │
                    │  ├── Public Subnets  [.1.x, .2.x]  │
                    │  │   └── Jump Server (EC2 t3.micro) │
                    │  └── Private Subnets [.3.x, .4.x]  │
                    │      └── EKS Node Group             │
                    │          (t3.medium, 1–3 nodes)     │
                    └─────────────────────────────────────┘
                              │
                         EKS Cluster (cs365-eks-cluster v1.33)
                              │
                    ┌─────────┴──────────────┐
                    │  Namespace: argocd      │
                    │  └── ArgoCD Server      │
                    │                         │
                    │  Namespace: ingress-nginx│
                    │  └── Nginx Ingress Ctrl │
                    │                         │
                    │  Namespace: go-app       │
                    │  ├── Deployment (x2)    │
                    │  ├── Service (ClusterIP) │
                    │  └── Ingress             │
                    └─────────────────────────┘

ArgoCD watches: go-app-devops/charts (develop branch)
→ Auto-sync on values.yaml change (image tag update from CI)
```

## Repository Structure

```
go-app-devops/
├── .github/
│   └── workflows/
│       └── terraform.yml           # Terraform CI/CD workflow
├── terraform/
│   ├── eks/
│   │   ├── main.tf                 # Module wiring
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── backend.tf              # S3 + DynamoDB remote state
│   │   └── dev.tfvars              # Environment values
│   └── modules/
│       ├── vpc/                    # VPC, subnets, IGW, NAT
│       ├── eks/                    # EKS cluster + managed node group
│       ├── iam/                    # EKS + node group IAM roles
│       └── jump-server/            # EC2 bastion with kubectl/helm/aws-cli
├── charts/                         # Helm chart
│   ├── Chart.yaml
│   ├── values.yaml                 # Image tag updated by CI automatically
│   └── templates/
│       ├── deployment.yaml
│       ├── service.yaml
│       ├── ingress.yaml
│       └── namespace.yaml
├── argocd/
│   └── application.yaml            # ArgoCD Application manifest
└── bootstrap-remote-state.sh       # S3 + DynamoDB setup script
```

## Terraform Infrastructure

| Module | Resources Created |
|---|---|
| `vpc` | VPC, 2 public + 2 private subnets, IGW, NAT Gateway, route tables |
| `eks` | EKS control plane (v1.33), managed node group (t3.medium, 1–3 nodes) |
| `iam` | EKS cluster role, node group role with required AWS policies |
| `jump-server` | EC2 t3.micro (Amazon Linux 2023) with kubectl, helm, aws-cli pre-installed |

**Remote State**: S3 bucket `cs365-tf-state-bucket` + DynamoDB table `cs365-tf-lock` (us-east-1)

## GitHub Actions Workflow (`terraform.yml`)

Triggered by:
- Push to `develop` or `uat` (terraform files changed) → runs `plan`
- PR to `main` → runs `plan` + posts result as PR comment
- Manual dispatch → choose `bootstrap / plan / apply / destroy`

| Job | When | Does |
|---|---|---|
| `bootstrap` | action=bootstrap | Creates S3 + DynamoDB for remote state |
| `terraform` (plan) | push/PR or action=plan | `fmt` → `init` → `validate` → `plan` |
| `terraform` (apply) | action=apply | `plan` → `apply` |
| `terraform` (destroy) | action=destroy | `destroy` |
| `install-argocd` | after apply | Install Nginx Ingress + ArgoCD + apply ArgoCD application + verify sync |

## Helm Chart

| Field | Value |
|---|---|
| Chart name | `go-portfolio-chart` |
| Namespace | `go-app` |
| Replicas | 2 |
| Image | `avian19/go-port:<tag>` (tag updated by CI automatically) |
| Service | ClusterIP on port 80 → container 8080 |
| Ingress | Nginx, path `/`, TLS optional |
| Health checks | Liveness + Readiness on `GET /` port 8080 |

## ArgoCD GitOps

```yaml
# argocd/application.yaml
source:
  repoURL: https://github.com/cs365-project/go-app-devops
  targetRevision: develop      # watches this branch
  path: charts
syncPolicy:
  automated:
    prune: true                # remove resources deleted from git
    selfHeal: true             # revert manual changes to cluster
```

ArgoCD detects every change to `charts/values.yaml` (image tag) and automatically deploys the new version to EKS — no manual sync required.

## Required GitHub Secrets

| Secret | Description |
|---|---|
| `AWS_ACCESS_KEY_ID` | AWS IAM access key |
| `AWS_SECRET_ACCESS_KEY` | AWS IAM secret key |
| `AWS_SESSION_TOKEN` | AWS session token (if using temporary credentials) |

## Getting the App URL

After `terraform apply` completes, the `install-argocd` job prints:

```
App URL: http://<aws-loadbalancer-hostname>
```

Or retrieve it manually from the jump server:
```bash
kubectl get ingress -n go-app
```

## Companion Repository

Application source code and CI pipeline:
[go-portfolio](https://github.com/cs365-project/go-portfolio)
