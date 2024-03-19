
The repo holds the terraform configuration for the following functionalities

1. Create VPC(Virtual Private Cloud) network
1. Create Subnets inside VPC
1. Create firewall rules like no-ssh and single port expose
1. Create private service access to connect to cloud sql instance
1. Add SQL instance private IP, database user, password etc to the VM instance env variables with the 
help of startup script concept
1. Set up A record for DNS, which creates a link between DNS name and the VM instance
1. Setup a service account and attach it to a VM with proper IAM roles like logging writes which helps to send
logs to the google observability service

-------
# tf-gcp-infra
This repo is to manage google cloud platform automatically

### Steps to setup GCP

1. terraform init:
The terraform init command initializes a new or existing Terraform configuration. It downloads the necessary providers and initializes the working directory.

Usage:
```bash
terraform init
```

2. terraform plan:
The terraform plan command creates an execution plan, outlining the actions Terraform will take to apply the desired state. It helps you understand the changes that will be made to your infrastructure.

Usage:
```bash
terraform plan
```

3. terraform apply
The terraform apply command applies the changes specified in the Terraform configuration. It prompts for confirmation before making any changes.

Usage:
```bash
terraform apply
```
Use -auto-approve to skip the confirmation prompt:

```bash
terraform apply -auto-approve
```

4. terraform destroy
The terraform destroy command is used to destroy the infrastructure created by the Terraform configuration. It prompts for confirmation before proceeding.

Usage:
```bash
terraform destroy
```
Use -auto-approve to skip the confirmation prompt:

```bash
terraform destroy -auto-approve
```
Note: Use terraform destroy cautiously, as it irreversibly deletes resources. Only execute this command when you want to tear down the infrastructure

-----------

Keywords:
1. VPC
2. Subnets
3. Routes
4. Firewalls
5. VM
6. Private Service Access
7. Service Account
8. Cloud SQL
9. Cloud DNS
10. IAM
