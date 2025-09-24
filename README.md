# Odoo Infrastructure as Code

This repository contains Terraform and Ansible code for deploying Odoo on DigitalOcean.

## Structure

- `.github/workflows/` - GitHub Actions workflows
- `terraform/` - Infrastructure provisioning
- `ansible/` - Application deployment
- `scripts/` - Utility scripts

## Workflows

### Provision Infrastructure
- Deploys DigitalOcean droplets, networking, and DNS
- Located in `.github/workflows/terraform/provision.yml`

### Configure Deployment
- Deploys Odoo application using Ansible
- Located in `.github/workflows/ansible/deploy.yml`

### Update Deployment
- Updates existing Odoo deployments
- Located in `.github/workflows/ansible/update.yml`

### Destroy Infrastructure
- Tears down infrastructure
- Located in `.github/workflows/terraform/destroy.yml`

## Usage

1. Set up required secrets in GitHub
2. Run the "Provision Infrastructure" workflow
3. Run the "Configure Deployment" workflow
4. Push to main branch for automatic updates

## Environments

- `dev` - Development environment
- `staging` - Staging environment  
- `production` - Production environment