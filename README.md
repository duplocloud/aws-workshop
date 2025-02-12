# VM to EKS Demo Repository

Welcome to the **VM to EKS Demo** repository! This simple application demonstrates the end-to-end process of migrating a traditional, virtual-machine-based deployment on DigitalOcean to a fully containerized workload running on AWS EKS. Along the way, the demo also highlights how to incorporate compliance best practices and how [DuploCloud](https://duplocloud.com) can streamline your journey—from infrastructure provisioning and container orchestration to security and governance.

---

## Key Features

1. **VM to Container Transition**  
   Learn how to take a simple app running on a traditional virtual machine and package it into containers.

2. **Migration to AWS EKS**  
   Discover best practices for setting up and deploying workloads to Amazon’s Elastic Kubernetes Service.

3. **Security & Compliance**  
   Implement basic security controls and compliance checks to maintain a robust and auditable workflow.

4. **DuploCloud Integration**  
   See how DuploCloud simplifies infrastructure setup, automates compliance requirements, and manages Kubernetes resources.

---

## What You’ll Learn

- **Containerization**: How to containerize an existing application using Docker.  
- **Kubernetes Manifests**: Methods to create and configure Kubernetes manifests for EKS.  
- **DuploCloud Automation**: How to leverage DuploCloud’s platform to automate deployments, security, and compliance policies.  
- **Migration Best Practices**: Best practices for transitioning from a VM-based environment to a cloud-native platform.

---

Use this repository as a guide or starting point for your own migration projects. By following the examples and instructions provided, you’ll quickly see how to move from a VM-based setup on DigitalOcean to a managed Kubernetes service on AWS—complete with streamlined automation and compliance.

Feel free to explore, contribute, or raise issues!



Below is a complete example of a `README.md` file for your GitHub repository. Adjust the content as needed to reflect your project's details:

---

# Infrastructure as Code (IaC) Repository

This repository contains the Terraform configurations to provision and manage our infrastructure. It includes all the necessary code to set up resources on DigitalOcean (DO), DigitalOcean Spaces, virtual machines, and additional services that your application requires.

> **Warning:** Before you apply any changes, ensure that you have set the required environment variables. These variables include sensitive credentials and configuration settings that Terraform uses to build your infrastructure.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Environment Variables](#environment-variables)
- [Usage](#usage)
  - [Initialize Terraform](#initialize-terraform)
  - [Plan the Deployment](#plan-the-deployment)
  - [Apply the Infrastructure](#apply-the-infrastructure)
  - [Destroy the Infrastructure](#destroy-the-infrastructure)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## Prerequisites

- **Terraform:** [Install Terraform](https://www.terraform.io/downloads.html) (version 0.12 or later recommended).
- **DigitalOcean API Token:** Required to interact with the DigitalOcean API.
- **DO Spaces Credentials:** Access key and secret key for DigitalOcean Spaces.
- **VM Credentials:** Username and password for any virtual machines you plan to provision.
- **Additional Application Settings:** Such as application secret key and database name.

## Environment Variables

Before running any Terraform commands, export the following environment variables in your terminal. This ensures Terraform picks up the necessary credentials and configuration values:

```bash
export TF_VAR_do_token=""          # Your DigitalOcean API token
export TF_VAR_spaces_access_key=""   # Your DigitalOcean Spaces access key
export TF_VAR_spaces_secret_key=""   # Your DigitalOcean Spaces secret key
export TF_VAR_vm_user=""             # The username for your virtual machines
export TF_VAR_vm_password=""         # The password for your virtual machines
export TF_VAR_region="nyc3"          # The region for provisioning (default: nyc3)
export TF_VAR_app_secret_key=""      # Your application secret key
export TF_VAR_db_name=""             # The name of the database to be created
export TF_VAR_name_prefix="01"       # A prefix for naming your resources
```

> **Note:**  
> - **Security:** Do not commit these values to version control. Use secure methods for managing your secrets.
> - You can add these exports to your shell profile (e.g., `.bashrc` or `.zshrc`) to load them automatically.

## Usage

All Terraform configurations reside in the `iac` folder. Follow the steps below to deploy your infrastructure:

### 1. Clone the Repository

Clone this repository to your local machine:

```bash
git clone https://github.com/yourusername/your-repo-name.git
cd your-repo-name/iac
```

### 2. Initialize Terraform

Initialize your working directory to download required providers and modules:

```bash
terraform init
```

### 3. Plan the Deployment

Generate and review an execution plan to see what changes Terraform will make:

```bash
terraform plan
```

### 4. Apply the Infrastructure

Deploy your infrastructure by applying the Terraform configuration:

```bash
terraform apply
```

Terraform will prompt you for confirmation before making any changes. Type `yes` to proceed.

### 5. Destroy the Infrastructure (Optional)

If you need to remove all provisioned resources, run:

```bash
terraform destroy
```

## Troubleshooting

- **Unset Variables:**  
  If you encounter errors related to missing variables, ensure that all `TF_VAR_*` environment variables are properly set in your current shell session.

- **Credential Issues:**  
  Double-check that your API tokens and credentials are correct and have the necessary permissions.

- **Terraform Errors:**  
  Consult the [Terraform documentation](https://www.terraform.io/docs) or seek help from community forums if you experience issues during initialization or apply.

## Contributing

Contributions are welcome! If you have suggestions for improvements or encounter issues, please open an issue or submit a pull request. When contributing:

- Follow the repository's coding style.
- Ensure any changes are tested.
- Do not include sensitive credentials in your commits.

## License

This project is licensed under the [MIT License](LICENSE).

---

Below is an example `README.md` file that explains how to use the two migration scripts—one for migrating a PostgreSQL database and the other for migrating files from DigitalOcean Spaces to an AWS S3 bucket. Adjust the content as needed for your environment.

---

# Migration Scripts

This repository contains two migration scripts designed to help you transfer data between different environments:

1. **PostgreSQL Database Migration Script:**  
   Dumps a PostgreSQL database from a source host and restores it to a destination host, complete with progress feedback.

2. **DigitalOcean Spaces to AWS S3 Migration Script:**  
   Migrates files from a DigitalOcean Spaces bucket to an AWS S3 bucket using `rclone` with a progress display.

> **Warning:**  
> These scripts require sensitive credentials and connection details. **Do not commit your credentials** to any public repository. Always handle them securely.

---

## Prerequisites

### For the PostgreSQL Migration Script

- **PostgreSQL Client Tools:**  
  - `pg_dump` (to dump the database)  
  - `psql` (to restore the database)

- **Optional:**  
  - `pv` (for a progress bar display).  
    > Install on Ubuntu/Debian: `sudo apt-get install pv`

- **Access:**  
  - Connection details for both source and destination PostgreSQL databases.

### For the DigitalOcean Spaces to AWS S3 Migration Script

- **rclone:**  
  Install [rclone](https://rclone.org/downloads/) if not already installed.

- **Credentials:**  
  - **DigitalOcean Spaces:** Bucket name, endpoint URL, access key, and secret key.  
  - **AWS S3:** Bucket name, region, access key, and secret key.

---

## Setup

1. **Clone the Repository**

   ```bash
   git clone https://github.com/yourusername/migration-scripts.git
   cd migration-scripts
   ```

2. **Make the Scripts Executable**

   ```bash
   chmod +x migrate_postgres.sh
   chmod +x migrate_spaces_to_s3.sh
   ```

---

## PostgreSQL Migration Script

### Description

This script:
- Dumps a source PostgreSQL database to a local file.
- Restores that dump file into a destination PostgreSQL database.
- Displays progress using `pv` (if installed) or a spinner otherwise.
- Optionally cleans up the dump file after a successful migration.

### How to Run

1. **Execute the Script:**

   ```bash
   ./migrate_postgres.sh
   ```

2. **Follow the Prompts:**

   - **Source Database:**  
     Provide the source host, database name, user, and password.
     
   - **Destination Database:**  
     Provide the destination host, database name, user, and password.
     
3. **Progress Display:**  
   The script will display a progress bar or a spinner during both dump and restore operations.

4. **Cleanup Option:**  
   After a successful migration, you'll be asked if you want to remove the dump file.

---

## DigitalOcean Spaces to AWS S3 Migration Script

### Description

This script:
- Uses `rclone` to copy files from a DigitalOcean Spaces bucket to an AWS S3 bucket.
- Prompts you for all necessary credentials and configuration details.
- Creates a temporary `rclone` configuration file for the migration.
- Displays progress using `rclone`'s `--progress` flag.

### How to Run

1. **Execute the Script:**

   ```bash
   ./migrate_spaces_to_s3.sh
   ```

2. **Follow the Prompts:**

   - **DigitalOcean Spaces:**
     - Bucket name
     - Endpoint URL (e.g., `https://nyc3.digitaloceanspaces.com`)
     - Access key
     - Secret key

   - **AWS S3:**
     - Bucket name
     - Region (e.g., `us-east-1`)
     - Access key
     - Secret key

3. **Migration Process:**  
   The script creates a temporary rclone configuration, then performs the migration while displaying progress. The temporary configuration file is deleted once the migration is complete.

---

## Troubleshooting

- **Missing Tools:**  
  Ensure that `pg_dump`, `psql`, and `rclone` are installed and available in your system's PATH.

- **Permission Issues:**  
  Confirm the scripts have execute permissions (use `chmod +x`).

- **Credential Errors:**  
  Verify that the provided credentials and connection details are correct and have sufficient permissions.

- **Progress Display:**  
  If `pv` is not installed, the PostgreSQL script will fall back to a simple spinner animation.

---

## License

This project is licensed under the [MIT License](LICENSE).

---

