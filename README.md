### Cosign usage with Azure CI/CD Pipelines

#### Services

* AWS CodeCommit, AWS CodePipeline, AWS CodeDeploy --> Azure DevOps
* AWS CodeBuild --> Azure DevOps Pipeline / GitHub Actions
* AWS IAM --> Azure Active Directory / Azure role-based access control
* AWS S3 --> Azure Blob Storage
* Server-side encryption with AWS S3 KMS --> Azure Storage Service Encryption
* AWS KMS, CloudHSM --> Azure Key Vault
* AWS ECS / Fargate --> Azure Container Services
* AWS ECR --> Azure Container Registry
* AWS CloudWatch / X-Ray --> Azure Monitor

#### Usage

1. Create remote storage account.
2. Azure Blog Storage is for Terraform remote state storage.
3. Configure Terraform Backend State with Azure Blog Storage.
3. Create Azure Key Vault and Azure Container Registry.
4. Define Service Principals.
5. Generate Cosign Key Pair and store in Azure Key Vault.
6. Provide proper authorization to the signer and reader service principals.
7. Use Azure DevOps to house the repository and setup pipelines
8. Automate the container image signing through CI Pipeline (GitHub Actions)