# AWS Cross-Region VPC Peering with Terraform

##  Project Overview

This project demonstrates how to build and configure **cross-region VPC peering on AWS using Terraform**.

Two Amazon VPCs are created in different AWS regions and connected using an AWS VPC Peering Connection. Each VPC contains a public subnet and an EC2 instance. Route tables and security groups are configured so that the EC2 instances can communicate with each other using their **private IP addresses through the VPC peering connection**.

The complete infrastructure is provisioned and managed using **Terraform Infrastructure as Code (IaC)**.

---

##  Objectives

The main objectives of this project are:

- Create AWS VPCs using Terraform
- Deploy VPCs in different AWS regions
- Create subnets in both VPCs
- Configure Internet Gateways
- Configure route tables and route table associations
- Establish a cross-region VPC peering connection
- Configure routes for communication between the VPCs
- Configure Security Groups for controlled traffic
- Deploy EC2 instances in both VPCs
- Connect to EC2 instances using SSH
- Verify private network communication between the VPCs
- Manage the complete infrastructure using Terraform

---

##  Architecture

```text
                         AWS CLOUD

        ┌─────────────────────────────────────┐
        │          PRIMARY VPC                 │
        │          us-east-1                   │
        │          10.0.0.0/16                 │
        │                                     │
        │       Public Subnet                 │
        │                                     │
        │    ┌──────────────────────┐         │
        │    │     Primary EC2      │         │
        │    │     Private IP      │         │
        │    │     10.0.x.x        │         │
        │    └──────────┬───────────┘         │
        │               │                     │
        │          Route Table                │
        │               │                     │
        └───────────────┼─────────────────────┘
                        │
                        │
                  VPC PEERING
                        │
                        │
        ┌───────────────┼─────────────────────┐
        │               │                     │
        │        SECONDARY VPC                │
        │        ap-south-1                   │
        │        10.1.0.0/16                  │
        │                                     │
        │       Public Subnet                 │
        │                                     │
        │    ┌──────────────────────┐         │
        │    │    Secondary EC2     │         │
        │    │    Private IP       │         │
        │    │    10.1.x.x         │         │
        │    └──────────────────────┘         │
        │                                     │
        │          Route Table                │
        │                                     │
        └─────────────────────────────────────┘
```

---

##  AWS Regions and CIDR Blocks

Two VPCs are deployed in different AWS regions.

| VPC | AWS Region | CIDR Block |
|---|---|---|
| Primary VPC | `us-east-1` | `10.0.0.0/16` |
| Secondary VPC | `ap-south-1` | `10.1.0.0/16` |

The VPCs use **non-overlapping CIDR ranges**, which allows them to communicate through VPC peering.

---

##  Technologies Used

- **AWS VPC**
- **AWS VPC Peering**
- **Amazon EC2**
- **AWS Internet Gateway**
- **AWS Route Tables**
- **AWS Security Groups**
- **Terraform**
- **AWS CLI**
- **Git**
- **GitHub**
- **SSH**

---

#  AWS Infrastructure

## 1. VPCs

Two VPCs are created using Terraform.

### Primary VPC

```text
Region: us-east-1
CIDR: 10.0.0.0/16
```

### Secondary VPC

```text
Region: ap-south-1
CIDR: 10.1.0.0/16
```

Both VPCs have DNS support enabled:

```hcl
enable_dns_hostnames = true
enable_dns_support   = true
```

This allows resources inside the VPCs to use AWS DNS functionality.

---

## 2. Terraform Provider Aliases

Since the project uses two AWS regions, Terraform provider aliases are used.

```hcl
provider "aws" {
  region = "us-east-1"
  alias  = "primary"
}

provider "aws" {
  region = "ap-south-1"
  alias  = "secondary"
}
```

The aliases allow Terraform to create and manage resources in both AWS regions from the same Terraform configuration.

For example:

```hcl
provider = aws.primary
```

creates a resource in `us-east-1`.

While:

```hcl
provider = aws.secondary
```

creates a resource in `ap-south-1`.

---

## 3. Subnets

A subnet is created inside each VPC.

The subnets are configured with:

```hcl
map_public_ip_on_launch = true
```

This allows EC2 instances launched in these subnets to receive public IP addresses.

The public IP addresses are used for SSH access from the local machine.

The private IP addresses are used for communication between the VPCs through the peering connection.

---

## 4. Internet Gateways

An Internet Gateway is created for each VPC.

```text
Primary VPC
     |
Internet Gateway
     |
  Internet
```

and:

```text
Secondary VPC
     |
Internet Gateway
     |
  Internet
```

The Internet Gateways provide internet connectivity for resources in the public subnets.

---

## 5. Route Tables

Each VPC has its own route table.

The internet route is configured as:

```text
0.0.0.0/0 → Internet Gateway
```

This means traffic destined for the internet is sent through the Internet Gateway.

### Primary Route Table

```text
0.0.0.0/0 → Primary Internet Gateway
```

### Secondary Route Table

```text
0.0.0.0/0 → Secondary Internet Gateway
```

The route tables are associated with their respective subnets using Terraform route table associations.

---

#  VPC Peering

The main purpose of this project is to establish private communication between the two VPCs.

A cross-region VPC Peering Connection is created between:

```text
Primary VPC
10.0.0.0/16

       ↕
  VPC PEERING
       ↕

Secondary VPC
10.1.0.0/16
```

VPC peering allows resources in the two VPCs to communicate using their **private IP addresses**.

Traffic between the VPCs does not need to travel through the public internet.

---

#  Routing Through the Peering Connection

Creating a VPC peering connection alone is not enough.

The route tables must also contain routes pointing traffic destined for the other VPC toward the peering connection.

## Primary → Secondary

The Primary route table contains:

```text
Destination: 10.1.0.0/16
Target: VPC Peering Connection
```

This means:

> If the destination belongs to the Secondary VPC, send the traffic through the VPC peering connection.

## Secondary → Primary

The Secondary route table contains:

```text
Destination: 10.0.0.0/16
Target: VPC Peering Connection
```

This provides the return path.

Therefore, communication works in both directions.

```text
Primary VPC
10.0.0.0/16
     |
     | VPC Peering
     |
Secondary VPC
10.1.0.0/16
```

---

#  Security Groups

Security Groups are configured for both EC2 instances.

## SSH

TCP port `22` is allowed for SSH access.

```text
TCP → Port 22
```

This allows the administrator to connect to the EC2 instances remotely.

## ICMP

ICMP traffic is allowed from the CIDR block of the opposite VPC.

This allows connectivity testing using:

```bash
ping <private-ip>
```

For example:

```bash
ping 10.1.x.x
```

## HTTP

HTTP traffic can be allowed from the Primary VPC to the Secondary VPC using:

```text
TCP → Port 80
```

This can be used if Nginx or another web server is deployed on the Secondary EC2.

The Security Groups use VPC CIDR ranges to restrict internal communication rather than allowing unrestricted access.

---

#  EC2 Instances

One EC2 instance is deployed in each VPC.

## Primary EC2

```text
Region: us-east-1
VPC: Primary VPC
Private IP: 10.0.x.x
```

## Secondary EC2

```text
Region: ap-south-1
VPC: Secondary VPC
Private IP: 10.1.x.x
```

The EC2 instances use SSH key pairs for secure remote access.

The public IP addresses are used to establish SSH connections from the local Windows machine.

The private IP addresses are used to test communication across the VPC peering connection.

---

#  SSH Access

The EC2 instances can be accessed using their public IP addresses.

Example:

```bash
ssh -i <private-key> ubuntu@<public-ip>
```

The private key files are stored locally and are **not committed to GitHub**.

---

#  Testing and Verification

After deploying the infrastructure, connectivity between the EC2 instances was tested using their **private IP addresses**.

For example, from the Primary EC2:

```bash
ping 10.1.28.83
```

The ping test successfully demonstrated communication between the two EC2 instances.

The test verifies that:

- The VPC peering connection is active
- The Primary route table contains the correct peering route
- The Secondary route table contains the correct return route
- The Security Groups allow ICMP traffic
- The EC2 instances can communicate using private IP addresses
- Cross-region private connectivity is working

The reverse direction can also be tested:

```bash
ping 10.0.50.188
```

from the Secondary EC2.

---

#  Optional HTTP/Nginx Testing

The project can also be extended to demonstrate application-level communication.

Nginx can be installed on the Secondary EC2:

```bash
sudo apt update
sudo apt install nginx -y
```

The Nginx service can be checked using:

```bash
sudo systemctl status nginx
```

A custom webpage can be created in:

```text
/var/www/html/index.nginx-debian.html
```

For example:

```html
<!DOCTYPE html>
<html>
<head>
    <title>VPC Peering Demo</title>
</head>
<body>

    <h1>Secondary VPC</h1>
    <h2>Nginx Server</h2>

    <p>Region: ap-south-1</p>
    <p>Private IP: 10.1.28.83</p>

</body>
</html>
```

After allowing TCP port `80` from the Primary VPC, the Primary EC2 can access the Secondary EC2's Nginx server using its private IP:

```bash
curl http://10.1.28.83
```

This demonstrates application-level HTTP communication across the VPC peering connection.

---

#  Ping vs HTTP Testing

The project can demonstrate two different types of connectivity.

### Ping

```bash
ping 10.1.28.83
```

This tests:

```text
ICMP connectivity
```

It answers:

> Can the Primary EC2 reach the Secondary EC2?

### Curl

```bash
curl http://10.1.28.83
```

This tests:

```text
TCP
 ↓
Port 80
 ↓
HTTP
 ↓
Nginx
 ↓
Webpage
```

It answers:

> Can the Primary EC2 access an actual web service running inside the Secondary VPC?

---

#  Terraform Concepts Demonstrated

This project demonstrates several important Terraform concepts.

## Provider Aliases

Used to manage resources across multiple AWS regions.

```hcl
provider "aws" {
  region = "us-east-1"
  alias  = "primary"
}

provider "aws" {
  region = "ap-south-1"
  alias  = "secondary"
}
```

## Data Sources

AWS AMI information and Availability Zones are retrieved dynamically using Terraform data sources instead of hardcoding resource information.

## Variables

Configuration values such as:

- VPC CIDR blocks
- AWS regions
- Other infrastructure parameters

are managed using Terraform variables.

## Resource Dependencies

Terraform automatically determines many dependencies from resource references.

Explicit dependencies can also be defined using:

```hcl
depends_on
```

This project uses dependencies to ensure that resources such as VPC peering are properly established before dependent routes are created.

## Outputs

Terraform outputs important information such as:

- EC2 private IP addresses
- EC2 public IP addresses

This makes it easy to retrieve the information required for testing and SSH access.

---

#  Deployment

## Prerequisites

Before deploying the project, install and configure:

- Terraform
- AWS CLI
- Git
- An AWS account
- AWS credentials with appropriate permissions

---

## Configure AWS CLI

Configure AWS credentials:

```bash
aws configure
```

Verify the AWS connection:

```bash
aws sts get-caller-identity
```

This confirms that the terminal is authenticated with AWS.

---

## Initialize Terraform

Inside the project directory:

```bash
terraform init
```

This initializes the Terraform working directory and downloads the required AWS provider.

---

## Validate Terraform Configuration

```bash
terraform validate
```

This checks whether the Terraform configuration is syntactically valid.

---

## Format Terraform Code

```bash
terraform fmt
```

This formats the Terraform configuration files according to Terraform's standard formatting.

---

## Review the Infrastructure

```bash
terraform plan
```

This displays the resources Terraform plans to create, modify, or destroy.

---

## Deploy the Infrastructure

```bash
terraform apply
```

Confirm the deployment when Terraform asks for approval.

---

## View Terraform Outputs

```bash
terraform output
```

This displays the configured EC2 public and private IP addresses.

---

#  Destroy Infrastructure

When the project is no longer required, the AWS resources can be removed using:

```bash
terraform destroy
```

This removes the AWS infrastructure managed by Terraform and helps prevent unnecessary AWS charges.

---

#  Security Considerations

The following security practices are followed:

- SSH private keys are not committed to GitHub.
- `.pem` files are excluded using `.gitignore`.
- Terraform state files are excluded from the repository.
- AWS credentials are not stored in Terraform source code.
- Security Groups are used to control network traffic.
- VPC CIDR ranges are used to restrict internal communication.
- The two VPCs use non-overlapping CIDR ranges.
- Private IPs are used for communication across the peering connection.

Sensitive files should never be pushed to a public GitHub repository.

---

#  Key Concepts Learned

This project provided hands-on experience with:

- Infrastructure as Code
- Terraform
- AWS VPC
- VPC CIDR blocks
- Subnets
- Internet Gateways
- Route Tables
- Routes
- Route Table Associations
- VPC Peering
- Cross-region networking
- AWS Provider Aliases
- Security Groups
- EC2
- AMI Data Sources
- Availability Zone Data Sources
- SSH
- Private IP communication
- ICMP
- TCP
- HTTP
- Nginx
- Terraform dependencies
- Terraform outputs
- AWS CLI

---

#  Why VPC Peering?

VPC Peering allows resources in different VPCs to communicate privately using private IP addresses.

It can be useful when organizations have:

- Applications distributed across multiple VPCs
- Workloads deployed across different AWS regions
- Separate development and production environments
- Services that require private communication
- Applications distributed across multiple network environments

Example:

```text
Application VPC
      |
      | Private Communication
      |
  VPC Peering
      |
      |
Service VPC
```

VPC peering provides a direct network connection between the VPCs without requiring traffic to travel through the public internet.

---

#  Project Outcome

The project successfully demonstrates a complete **cross-region AWS VPC peering architecture provisioned using Terraform**.

Two VPCs were created in different AWS regions, with subnets, Internet Gateways, route tables, Security Groups, and EC2 instances.

A VPC Peering Connection was established between the VPCs, and routes were configured in both directions.

The EC2 instances were successfully able to communicate using their **private IP addresses across the VPC peering connection**, confirming that the peering connection, routing configuration, and Security Groups were correctly configured.

This project provided practical experience with **AWS networking, cross-region communication, EC2, Security Groups, and Infrastructure as Code using Terraform**.

---

#  Author

**Yuvan Dhurkesh**

B.Tech Computer Science Engineering

Cloud & DevOps Enthusiast

---

#  Future Improvements

Possible improvements for this project include:

- Add Nginx to demonstrate HTTP communication across the VPCs
- Add multiple subnets across multiple Availability Zones
- Add NAT Gateways for private subnets
- Deploy application servers instead of standalone EC2 instances
- Convert the infrastructure into reusable Terraform modules
- Add remote Terraform state using Amazon S3
- Add CI/CD using GitHub Actions
- Add monitoring using Amazon CloudWatch
- Implement more restrictive Security Group rules
- Add automated Terraform validation and security scanning
- Implement centralized logging and monitoring
