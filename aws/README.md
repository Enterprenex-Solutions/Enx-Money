# ENX Money — Production AWS Cloud Architecture & Deployment Guide

## Architecture Overview

```
                     ENX MONEY
                         │
        ┌────────────────┴────────────────┐
        │                                 │
   Web / Mobile App                  Admin Panel
        │                                 │
        └────────────────┬────────────────┘
                         ↓
                   AWS CloudFront
                         ↓
                  Backend / API
                    EC2 / ECS
                         ↓
              ┌──────────┴──────────┐
              ↓                     ↓
           AWS RDS                 AWS S3
            MySQL              Receipts / PDFs
              │
              ↓
        AWS CloudWatch
          Monitoring
```

## Mandatory Principle: Zero Developer Laptop Dependency

The production application is designed to operate completely independently of the developer's machine:
- The backend runs inside AWS ECS Fargate or EC2 instances with auto-healing and multi-task redundancy.
- The database is managed in a private AWS RDS MySQL Multi-AZ cluster with automated snapshots and daily backups.
- File assets (GST invoices, PDF statements, business docs) are encrypted and stored in Amazon S3.
- All client apps (Android APK, AAB, Web) communicate strictly over HTTPS via AWS CloudFront / ALB.
- **The developer's laptop can be completely powered off, closed, or disconnected from the internet, and ENX Money will continue operating 24/7 for users worldwide.**

---

## 1. Quick Deploy with AWS CloudFormation

### Prerequisites:
- AWS CLI configured with administrator or deployment credentials (`aws configure`)
- Amazon ECR repository created for the container image:
  ```bash
  aws ecr create-repository --repository-name enxmoney-backend --region ap-south-1
  ```

### Step 1: Build & Push Production Docker Image
```bash
cd server
docker build -t enxmoney-backend:latest .
aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin <ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com
docker tag enxmoney-backend:latest <ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com/enxmoney-backend:latest
docker push <ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com/enxmoney-backend:latest
```

### Step 2: Deploy CloudFormation Stack
```bash
aws cloudformation deploy \
  --template-file aws/aws-production-cloudformation.yml \
  --stack-name enx-money-production \
  --parameter-overrides \
      EnvironmentName=production \
      DBMasterUsername=enx_admin \
      DBMasterPassword="YourStrongDatabasePassword2026!" \
      AppImageUri=<ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com/enxmoney-backend:latest \
  --capabilities CAPABILITY_IAM \
  --region ap-south-1
```

### Step 3: Verify Deployment
Retrieve the output CloudFront domain:
```bash
aws cloudformation describe-stacks --stack-name enx-money-production --query "Stacks[0].Outputs" --output table
```
Test the public deep health check:
```bash
curl -i https://<YOUR_CLOUDFRONT_DOMAIN>/health
```
Expected response:
```json
{
  "status": "HEALTHY",
  "service": "ENX Money Auth & Business Backend",
  "environment": "production",
  "version": "1.0.0",
  "database": "connected",
  "uptime": 124.5,
  "memory": { ... }
}
```

---

## 2. Deploy on a Standalone AWS EC2 Instance (Alternative)

If using a dedicated AWS EC2 Ubuntu instance:
1. Launch an `Ubuntu 24.04 LTS` (t3.medium recommended) instance in AWS EC2.
2. Configure Security Group:
   - Inbound: Port 80 (HTTP), Port 443 (HTTPS), Port 22 (SSH).
3. Connect via SSH:
   ```bash
   ssh -i your-key.pem ubuntu@<EC2_PUBLIC_IP>
   ```
4. Install Docker & Docker Compose:
   ```bash
   curl -fsSL https://get.docker.com -o get-docker.sh && sudo sh get-docker.sh
   sudo usermod -aG docker $USER
   sudo apt-get install -y docker-compose-plugin
   ```
5. Clone repository, configure `.env`, and launch:
   ```bash
   git clone https://github.com/Enterprenex-Solution-Pvt-Ltd/Enx-Money.git
   cd Enx-Money
   docker compose -f docker-compose.prod.yml up -d --build
   ```
6. Set up free SSL with Certbot / Nginx or connect AWS CloudFront in front of the EC2 instance.
