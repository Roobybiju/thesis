# agents.md

## Serverless Architecture in DevOps Workflows

### 1. Project Overview

This project demonstrates a serverless architecture integrated with
DevOps workflows. The system processes images uploaded to cloud storage
using event-driven AWS Lambda functions and automates deployment using
CI/CD pipelines. The architecture eliminates the need for provisioning
or managing servers, allowing the focus to remain on application logic
and deployment automation.

------------------------------------------------------------------------

### 2. Architecture Components

-   **AWS S3 (Input Bucket)** — Receives raw image uploads from users and acts as the event source trigger
-   **AWS Lambda (Image Processing Agent)** — Stateless compute function that handles image transformation logic on demand
-   **AWS S3 (Output Bucket)** — Stores the processed images after Lambda execution
-   **IAM Roles & Policies** — Enforces least-privilege access between AWS services
-   **GitHub Actions (CI/CD Agent)** — Automates build, package, and deployment pipelines on every code push
-   **Terraform (IaC Agent)** — Declares and provisions all cloud infrastructure in a reproducible, version-controlled manner

------------------------------------------------------------------------

### 3. Agent Roles & Responsibilities

#### 3.1 Lambda Agent (Image Processor)

The Lambda function acts as the core processing agent. It is invoked
automatically when an object is uploaded to the S3 input bucket. The
agent performs the following responsibilities:

-   Reads the uploaded image from the source S3 bucket using the event metadata (bucket name and object key)
-   Converts the image to grayscale using an in-memory processing approach to avoid disk I/O
-   Writes the transformed image to the designated output S3 bucket with a `processed-` prefix on the key
-   Returns a structured HTTP-style response indicating success or failure
-   Handles runtime exceptions gracefully without crashing the invocation context

The function uses Python 3.10 runtime and depends on the `boto3` SDK for AWS interactions and `Pillow` for image processing.

------------------------------------------------------------------------

#### 3.2 Terraform Agent (Infrastructure Provisioner)

Terraform manages the entire infrastructure lifecycle as code. It is
responsible for provisioning and maintaining the following resources:

-   **Input S3 Bucket** (`input-images-bucket`) — configured as the upload target
-   **Output S3 Bucket** (`processed-images-bucket`) — configured as the storage destination for processed images
-   **Lambda Function** (`image-processor`) — deployed from a packaged zip artifact, wired to the Python handler and assigned an execution role
-   **IAM Execution Role** (`lambda-execution-role`) — grants Lambda the `sts:AssumeRole` permission and access to interact with S3

Terraform uses a declarative approach: the desired state is defined in `.tf` files, and Terraform computes and applies only the changes needed to reach that state.

------------------------------------------------------------------------

#### 3.3 GitHub Actions Agent (CI/CD Pipeline)

The GitHub Actions pipeline automates the full deployment lifecycle
triggered on every push to the `main` branch. It operates in stages:

-   **Checkout** — pulls the latest source code from the repository
-   **Build & Package** — compresses the Lambda function directory into a deployable `.zip` artifact
-   **AWS Authentication** — configures short-lived credentials using GitHub Secrets (`AWS_ACCESS_KEY`, `AWS_SECRET_KEY`) to avoid hardcoded values
-   **Infrastructure Deployment** — runs `terraform init` and `terraform apply` to provision or update cloud resources automatically

Secrets are managed through GitHub's encrypted secrets store, keeping credentials out of the codebase entirely.

------------------------------------------------------------------------

### 4. Workflow

1.  Developer pushes code changes to the `main` branch on GitHub
2.  GitHub Actions pipeline triggers automatically
3.  Lambda function is packaged and AWS credentials are configured via secrets
4.  Terraform provisions or updates infrastructure (S3 buckets, Lambda, IAM role)
5.  User uploads an image to the S3 input bucket
6.  S3 emits an event notification which triggers the Lambda function
7.  Lambda reads the image, converts it to grayscale using in-memory processing
8.  The processed image is saved to the output S3 bucket with a prefixed key
9.  Lambda returns a `200 OK` response on success or a `500` error response on failure

------------------------------------------------------------------------

### 5. IAM Security Model

Access control between services follows the principle of least privilege:

-   The Lambda execution role is granted only the permissions it needs — `s3:GetObject` on the input bucket and `s3:PutObject` on the output bucket
-   GitHub Actions authenticates using short-lived credentials stored as encrypted secrets, never embedded in code
-   Terraform manages role policies as versioned code, making permission changes auditable through Git history

------------------------------------------------------------------------

### 6. DevOps Practices Implemented

-   **Continuous Integration** — Code changes automatically trigger pipeline validation on every push
-   **Continuous Deployment** — Terraform applies infrastructure changes without manual intervention
-   **Infrastructure as Code** — All AWS resources are defined in Terraform, enabling repeatable deployments
-   **Version Control** — Both application code and infrastructure definitions are tracked in Git
-   **Automated Builds** — Lambda packaging and deployment are fully scripted, removing manual steps
-   **Secret Management** — Credentials are stored in GitHub Secrets and injected at runtime, never committed to the repository

------------------------------------------------------------------------

### 7. Advantages

-   **Scalable and cost-efficient** — Lambda scales automatically with demand; billing is per invocation with no idle costs
-   **No server management** — The cloud provider handles runtime patching, scaling, and availability
-   **Automated deployment** — The full pipeline from code commit to live infrastructure runs without manual steps
-   **Event-driven processing** — Lambda only runs when triggered, making the system highly responsive and resource-efficient
-   **Reproducible infrastructure** — Terraform ensures the same environment can be recreated consistently across stages

------------------------------------------------------------------------

### 8. Project Structure

```
project/
├── lambda/
│   └── app.py              # Lambda handler and image processing logic
├── terraform/
│   ├── main.tf             # Core infrastructure definitions
│   ├── variables.tf        # Input variable declarations
│   └── outputs.tf          # Output value definitions
└── .github/
    └── workflows/
        └── deploy.yml      # GitHub Actions CI/CD pipeline definition
```

------------------------------------------------------------------------

### 9. Future Enhancements

-   **API Gateway** — Expose a REST endpoint to allow direct HTTP-based image uploads, bypassing the need for S3 SDK access
-   **DynamoDB Integration** — Store processing metadata (original key, processed key, timestamp, status) for auditing and querying
-   **CloudWatch Monitoring** — Set up log groups, metric filters, and alarms to track Lambda errors, duration, and throttling
-   **Multi-function Workflows** — Extend the pipeline to chain multiple Lambda functions using AWS Step Functions for more complex processing tasks
-   **S3 Lifecycle Policies** — Automatically archive or delete processed images after a retention period to manage storage costs

------------------------------------------------------------------------

### 10. Conclusion

This project demonstrates how serverless architecture integrates with
DevOps workflows to produce a scalable, automated, and maintainable
system. By combining AWS Lambda for event-driven compute, Terraform for
infrastructure management, and GitHub Actions for continuous deployment,
the architecture removes operational overhead while preserving full
control over the deployment lifecycle. Each agent — Lambda, Terraform,
and GitHub Actions — operates with a well-defined responsibility,
communicates through established interfaces, and is governed by
security policies that enforce least-privilege access.
