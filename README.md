# Crescendo DevOps Exam

A comprehensive Infrastructure-as-Code (IaC) project demonstrating AWS infrastructure automation using Terraform and GitHub Actions CI/CD pipelines.

## Table of Contents

- [Project Overview](#project-overview)
- [AWS Architecture](#aws-architecture)
- [GitHub Actions Workflows](#github-actions-workflows)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
- [Terraform Configuration](#terraform-configuration)
- [CI/CD Pipeline](#cicd-pipeline)
- [Monitoring and Security](#monitoring-and-security)

## Project Overview

This repository contains a complete DevOps infrastructure setup for the Crescendo application, featuring:

- **Infrastructure as Code**: Complete AWS infrastructure defined using Terraform
- **Automated Deployments**: GitHub Actions workflows for terraform plan, apply, and destroy operations
- **Multi-Environment Support**: Support for development, staging, and production environments
- **High Availability**: Multi-AZ deployment with Auto Scaling and Load Balancing
- **Security**: WAF protection, security groups, and IAM roles
- **Content Delivery**: CloudFront distribution for edge caching

---

## AWS Architecture

### High-Level Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                     CloudFront Distribution                 │
│              (Global Edge Caching & WAF Protection)         │
└────────────────────────────┬────────────────────────────────┘
                             │
                             │ HTTPS (Redirected)
                             │
┌────────────────────────────┴────────────────────────────────┐
│                  AWS Region (us-east-2)                    │
│                                                              │
│  ┌────────────────────────────────────────────────────┐   │
│  │ VPC: 10.0.0.0/16                                   │   │
│  │                                                     │   │
│  │  ┌──────────────────────────────────────────────┐  │   │
│  │  │         Internet Gateway                     │  │   │
│  │  └──────────────────────────────────────────────┘  │   │
│  │                       │                             │   │
│  │   ┌─────────────────────┴─────────────────────┐   │   │
│  │   │                                           │   │   │
│  │   │        Public Subnets (Multi-AZ)         │   │   │
│  │   │  AZ-1: 10.0.0.0/24  │  AZ-2: 10.0.2.0/24│   │   │
│  │   │                                           │   │   │
│  │   │  ┌─────────────────────────────────────┐ │   │   │
│  │   │  │  Application Load Balancer (ALB)    │ │   │   │
│  │   │  │  - Health Check: HTTP /  (30s)     │ │   │   │
│  │   │  │  - Target Group: Port 80           │ │   │   │
│  │   │  └──────────────┬──────────────────────┘ │   │   │
│  │   │                 │                         │   │   │
│  │   └─────────────────┼─────────────────────────┘   │   │
│  │                     │                             │   │
│  │  ┌──────────────────┴──────────────────────┐    │   │
│  │  │        EC2 Auto Scaling Group           │    │   │
│  │  │  Instance Type: t3.medium               │    │   │
│  │  │  Min Size: 1, Max Size: 2               │    │   │
│  │  │  Desired Capacity: 1                    │    │   │
│  │  │                                          │    │   │
│  │  │  ┌─────────────┐  ┌─────────────┐      │    │   │
│  │  │  │  EC2 AZ-1   │  │  EC2 AZ-2   │      │    │   │
│  │  │  │             │  │             │      │    │   │
│  │  │  │ - Nginx     │  │ - Nginx     │      │    │   │
│  │  │  │ - Tomcat    │  │ - Tomcat    │      │    │   │
│  │  │  │ - Magnolia  │  │ - Magnolia  │      │    │   │
│  │  │  │   CMS       │  │   CMS       │      │    │   │
│  │  │  └─────────────┘  └─────────────┘      │    │   │
│  │  │                                          │    │   │
│  │  └──────────────────────────────────────────┘    │   │
│  │                                                     │   │
│  │  ┌──────────────────────────────────────────────┐ │   │
│  │  │        Private Subnets (Multi-AZ)           │ │   │
│  │  │  AZ-1: 10.0.1.0/24  │  AZ-2: 10.0.3.0/24  │ │   │
│  │  │                                             │ │   │
│  │  │        NAT Gateway for Outbound Traffic    │ │   │
│  │  └──────────────────────────────────────────────┘ │   │
│  │                                                     │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

### Architecture Components

#### 1. **Networking (VPC)**
- **VPC CIDR**: `10.0.0.0/16`
- **Multi-AZ Deployment**: 2 Availability Zones
- **Public Subnets**: 
  - AZ-1: `10.0.0.0/24`
  - AZ-2: `10.0.2.0/24`
  - Features: Auto-assign Public IP, Route to Internet Gateway
- **Private Subnets**:
  - AZ-1: `10.0.1.0/24`
  - AZ-2: `10.0.3.0/24`
  - Features: NAT Gateway for secure outbound internet access
- **Internet Gateway**: Provides internet connectivity
- **NAT Gateway**: Enables private subnet instances to reach internet while remaining private
- **Route Tables**: Separate routing for public and private subnets

#### 2. **Load Balancing & Edge Caching**

**Application Load Balancer (ALB)**
- Deployed across public subnets in both AZs
- Port: 80 (HTTP)
- Health Checks:
  - Path: `/`
  - Protocol: HTTP
  - Interval: 30 seconds
  - Timeout: 5 seconds
  - Healthy Threshold: 2 consecutive successful checks
  - Unhealthy Threshold: 2 consecutive failed checks
- Target Group: Forwards traffic to EC2 instances

**CloudFront Distribution**
- Global edge caching and content delivery
- Origin: ALB DNS name
- Protocol Policy: Redirect HTTP to HTTPS
- Cache Behavior:
  - Allowed Methods: GET, HEAD, OPTIONS, DELETE, PATCH, POST, PUT
  - Cached Methods: GET, HEAD
  - Default TTL: 300 seconds
  - Max TTL: 3600 seconds
  - Compression: Enabled
- Custom Header: `X-Custom-Header: From-CloudFront`
- Price Class: PriceClass_100 (lowest cost, limited regions)
- Certificate: CloudFront default certificate

#### 3. **Security & Web Application Firewall**

**AWS WAF (Web Application Firewall)**
- Scope: CloudFront
- Rules:
  1. **AWSManagedRulesCommonRuleSet**
     - Protects against common web exploits (SQL injection, XSS, etc.)
  2. **AWSManagedRulesKnownBadInputsRuleSet**
     - Blocks requests with known malicious patterns
  3. **RateLimitRule**
     - Limit: 2000 requests per 5 minutes per IP
     - Aggregate Key: IP address
- CloudWatch Metrics: Enabled for all rules
- Default Action: Allow (unless rules block)

**Security Groups**
- **ALB Security Group**:
  - Ingress: Port 80 (HTTP) from `0.0.0.0/0`
  - Egress: All traffic
- **EC2 Instance Security Group**:
  - Ingress: Port 80 from ALB security group
  - Ingress: Port 22 from EC2 Instance Connect CIDR
  - Egress: All traffic

#### 4. **Compute & Auto Scaling**

**EC2 Instances**
- **AMI**: Amazon Linux 2 (Latest)
- **Instance Type**: `t3.medium` (burstable, cost-effective)
- **Storage**: 50 GB gp2 EBS volume
- **IAM Role**: EC2 Instance Connect permissions

**Auto Scaling Group**
- **Min Size**: 1 instance
- **Max Size**: 2 instances
- **Desired Capacity**: 1 instance
- **Health Check Type**: ELB
- **Grace Period**: 600 seconds

**Applications Deployed**
- **Nginx**: Web server and reverse proxy (Port 80)
- **Tomcat**: Application server (Port 8080)
- **Magnolia CMS**: Content Management System (served through Tomcat)

#### 5. **Backend Infrastructure**

**S3 Remote State Storage**
- Bucket: `blackofi-terraform-storage`
- Key: `crescendo/dev.tfstate`
- Region: `us-east-2`
- State Locking: Enabled

**Data Sources**
- AWS Availability Zones (dynamic lookup)
- Amazon Linux 2 AMI (latest)

---

## GitHub Actions Workflows

### 1. **Terraform Refresh, Plan & Apply** (`terraform.yml`)

**Trigger Events**
- Push to `main` branch with changes to `terraform/` or workflow file
- Pull Requests to `main` branch with changes to `terraform/`
- Manual workflow dispatch

**Environment Configuration**
- Terraform Version: `v1.15.4`
- AWS Region: Retrieved from environment variables
- Credentials: AWS Access Key ID and Secret Access Key

**Workflow Steps**

| Step | Action | Condition |
|------|--------|-----------|
| 1. Checkout | Clone repository code | Always |
| 2. Setup Terraform | Install Terraform v1.15.4 | Always |
| 3. Configure AWS | Setup AWS credentials | Always |
| 4. Terraform Init | Initialize Terraform backend | Always |
| 5. Format Check | Validate HCL formatting | Always |
| 6. Validate | Check Terraform configuration | Always |
| 7. Refresh | Update state file | Not on PR |
| 8. Plan | Generate execution plan | Always |
| 9. Apply | Apply changes to infrastructure | Main branch push/dispatch only |
| 10. Export Outputs | Generate outputs JSON | Main branch push/dispatch only |
| 11. Upload Outputs | Store outputs as artifact | Main branch push/dispatch only |

**Key Features**
- Automatic formatting validation
- State file refresh on push (not on PR)
- Safe plan-before-apply workflow
- Artifact retention: 30 days
- Continue on error for plan failures (prevents blocking)

### 2. **Terraform Destroy** (`terraform-destroy.yml`)

**Trigger Events**
- Manual workflow dispatch only
- Requires selection of target environment (dev)

**Two-Stage Workflow**

**Stage 1: Plan Destroy**
- Reviews what will be destroyed
- Creates and uploads destroy plan artifact
- Manual verification point
- Retention: 1 day

**Stage 2: Execute Destroy**
- Dependent on successful plan stage
- Downloads destroy plan from artifact
- Executes `terraform apply` with destroy plan
- Requires explicit environment approval

**Safety Features**
- No automatic destruction (manual only)
- Staged approach with artifact upload
- Environment-gated execution
- Plan visibility before execution

---

## Project Structure

```
Crescendo-DevOps-exam/
├── .github/
│   └── workflows/
│       ├── terraform.yml                 # Main CI/CD workflow
│       └── terraform-destroy.yml         # Destroy workflow
├── terraform/
│   ├── .terraform.lock.hcl              # Dependency lock file
│   ├── environments/
│   │   └── dev/
│   │       ├── main.tf                  # Dev environment config
│   │       ├── variables.tf             # Dev variables
│   │       └── .terraform/              # Local state (for reference)
│   └── modules/
│       ├── network/
│       │   ├── main.tf                  # VPC, ALB, CloudFront, WAF
│       │   ├── variables.tf             # Network variables
│       │   └── outputs.tf               # Network outputs
│       └── compute/
│           ├── main.tf                  # EC2, ASG, IAM, Security Groups
│           ├── variables.tf             # Compute variables
│           └── outputs.tf               # Compute outputs
├── .gitignore
└── README.md                            # This file
```

---

## Prerequisites

### Local Development
- **Terraform**: v1.15.4 or higher
- **AWS CLI**: v2.x
- **Git**: Latest version
- **AWS Account**: With appropriate permissions

### GitHub Secrets & Variables
Set up the following in your GitHub repository:

**Secrets** (Settings → Secrets and variables → Actions)
```
AWS_ACCESS_KEY_ID          # AWS IAM user access key
AWS_SECRET_ACCESS_KEY      # AWS IAM user secret key
```

**Variables** (Settings → Secrets and variables → Variables)
```
AWS_REGION                 # e.g., us-east-2
```

**Environment Settings** (Settings → Environments)
Create a `dev` environment with deployment restrictions as needed.

---

## Getting Started

### 1. Clone the Repository
```bash
git clone https://github.com/yourusername/Crescendo-DevOps-exam.git
cd Crescendo-DevOps-exam
```

### 2. Configure AWS Credentials

**Option A: AWS CLI Configuration**
```bash
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Enter default region (us-east-2)
# Enter default output format (json)
```

**Option B: Environment Variables**
```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_REGION="us-east-2"
```

### 3. Initialize Terraform
```bash
cd terraform/environments/dev
terraform init
```

### 4. Plan Infrastructure
```bash
terraform plan -out=tfplan
```

### 5. Apply Configuration
```bash
terraform apply tfplan
```

### 6. Retrieve Outputs
```bash
terraform output -json > outputs.json
cat outputs.json
```

---

## Terraform Configuration

### Variables Overview

#### Network Variables
| Variable | Default | Description |
|----------|---------|-------------|
| `name` | crescendo | Name prefix for resources |
| `vpc_cidr` | 10.0.0.0/16 | VPC CIDR block |
| `az_count` | 2 | Number of availability zones |

#### Compute Variables
| Variable | Default | Description |
|----------|---------|-------------|
| `instance_type` | t3.medium | EC2 instance type |
| `asg_min_size` | 1 | Minimum ASG instances |
| `asg_max_size` | 2 | Maximum ASG instances |
| `asg_desired_capacity` | 1 | Desired ASG capacity |
| `volume_size` | 50 | EBS volume size (GB) |
| `volume_type` | gp2 | EBS volume type |

### Output Values

After applying, retrieve these outputs:
```bash
terraform output
# or JSON format
terraform output -json
```

**Available Outputs:**
- `alb_dns`: ALB DNS name for direct access
- `cloudfront_dns`: CloudFront domain for cached access
- `asg_name`: Auto Scaling Group identifier
- `asg_arn`: ASG ARN for reference

---

## CI/CD Pipeline

### Deployment Flow

```
┌─────────────┐
│  Developer  │
│  Push Code  │
└──────┬──────┘
       │
       ▼
┌──────────────────────────────────────┐
│  GitHub Actions Triggered            │
│  Event: Push/PR/Dispatch             │
└──────┬───────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────┐
│  1. Checkout Code                    │
│  2. Setup Terraform                  │
│  3. Configure AWS Credentials        │
└──────┬───────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────┐
│  4. Terraform Init                   │
│  5. Format & Validate                │
│  6. Refresh State (if push)          │
└──────┬───────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────┐
│  7. Generate Plan                    │
│     - Review changes                 │
│     - Continue on error              │
└──────┬───────────────────────────────┘
       │
       ├─────────────────────────────────────┐
       │ (If PR)                             │ (If Push to Main)
       ▼                                     ▼
  ┌─────────────┐                ┌───────────────────────┐
  │ Show Plan   │                │ 8. Apply Changes      │
  │ in PR       │                │ 9. Export Outputs     │
  └─────────────┘                │ 10. Upload Artifacts  │
                                 └───────────────────────┘
```

### Artifact Management

**Terraform Outputs Artifact**
- **Name**: `terraform-outputs`
- **Path**: `terraform/environments/dev/outputs.json`
- **Retention**: 30 days
- **Triggered**: After successful apply

### Monitoring Workflow Runs

1. Go to: **Repository → Actions**
2. Select workflow: **Terraform Refresh, Plan & Apply**
3. View latest run:
   - Check build status (green = success)
   - Review plan output
   - Check artifact uploads
4. For PRs: See plan summary in PR comments

---

## Monitoring and Security

### CloudWatch Monitoring

**WAF Metrics**
- Common Rule Set violations
- Known Bad Inputs blocks
- Rate limit triggers

**Load Balancer Metrics**
- Request count
- Target response time
- HTTP 4xx/5xx errors
- Healthy/Unhealthy target count

**Auto Scaling Metrics**
- Desired capacity
- In-service instances
- Pending instances

### Security Best Practices

1. **Terraform State**
   - Remote state in S3 with encryption
   - State locking enabled
   - Limit access to state bucket

2. **AWS Credentials**
   - Use GitHub Secrets for credentials
   - Rotate credentials regularly
   - Use IAM roles with least privilege

3. **Network Security**
   - WAF enabled on CloudFront
   - Security groups restrict traffic
   - Private subnets for sensitive resources

4. **EC2 Instance Connect**
   - SSH access restricted to Instance Connect CIDR
   - No direct SSH key needed
   - Audit trail in CloudTrail

### Scaling Considerations

**Current Configuration**
- Min: 1, Max: 2 instances
- Suitable for development environments
- Production: Increase to Min: 2, Max: 4+

**Scaling Triggers**
- Currently manual only
- To add auto-scaling policies:
  - CPU utilization > 70%
  - ALB request count per target
  - Custom CloudWatch metrics

---

## Troubleshooting

### Terraform Issues

**"Backend initialization failed"**
- Verify S3 bucket exists and is accessible
- Check AWS credentials
- Ensure bucket region matches (`us-east-2`)

**"Terraform fmt check failed"**
- Run: `terraform fmt -recursive terraform/`
- Commit the formatted changes

**"Invalid provider version"**
- Run: `terraform init -upgrade`
- Check `.terraform.lock.hcl` in git

### AWS Connectivity Issues

**"No valid credentials found"**
- Verify GitHub secrets are configured
- Test locally: `aws sts get-caller-identity`
- Check IAM user permissions

**"EC2 instances not launching"**
- Check NAT Gateway status
- Review EC2 launch template user data logs
- Verify security group rules
- Check subnet IP availability

### CloudFront/ALB Issues

**"504 Bad Gateway"**
- Verify ALB security group allows port 80
- Check EC2 security group ingress from ALB
- Verify health checks passing
- Review ALB target group status

---

## Contributing

1. Create feature branch: `git checkout -b feature/your-feature`
2. Make changes and test locally
3. Commit with descriptive messages
4. Push to branch and create Pull Request
5. Await GitHub Actions validation
6. Merge after approval
