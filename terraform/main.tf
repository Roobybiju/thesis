terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  required_version = ">= 1.5.0"
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

# ─────────────────────────────────────────
# S3 — Input Bucket
# ─────────────────────────────────────────
resource "aws_s3_bucket" "input_bucket" {
  bucket        = "${var.input_bucket_name}-${data.aws_caller_identity.current.account_id}"
  force_destroy = true

  tags = {
    Name        = "Input Images Bucket"
    Environment = "Production"
  }
}

resource "aws_s3_bucket_public_access_block" "input_bucket_public_access" {
  bucket = aws_s3_bucket.input_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ─────────────────────────────────────────
# S3 — Output Bucket
# ─────────────────────────────────────────
resource "aws_s3_bucket" "output_bucket" {
  bucket        = "${var.output_bucket_name}-${data.aws_caller_identity.current.account_id}"
  force_destroy = true

  tags = {
    Name        = "Processed Images Bucket"
    Environment = "Production"
  }
}

resource "aws_s3_bucket_public_access_block" "output_bucket_public_access" {
  bucket = aws_s3_bucket.output_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ─────────────────────────────────────────
# IAM — Lambda Execution Role
# ─────────────────────────────────────────
resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "Lambda Execution Role"
  }
}

# Least-privilege S3 policy
resource "aws_iam_role_policy" "lambda_s3_policy" {
  name = "lambda-s3-policy"
  role = aws_iam_role.lambda_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = "${aws_s3_bucket.input_bucket.arn}/*"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject"]
        Resource = "${aws_s3_bucket.output_bucket.arn}/*"
      }
    ]
  })
}

# Allow Lambda to write CloudWatch logs
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ─────────────────────────────────────────
# Lambda — Image Processor
# ─────────────────────────────────────────
resource "aws_lambda_function" "image_processor" {
  filename         = "../lambda/lambda_function.zip"
  function_name    = var.lambda_function_name
  role             = aws_iam_role.lambda_execution_role.arn
  handler          = "app.lambda_handler"
  runtime          = "python3.10"
  source_code_hash = filebase64sha256("../lambda/lambda_function.zip")
  timeout          = 30
  memory_size      = 256

  environment {
    variables = {
      OUTPUT_BUCKET = aws_s3_bucket.output_bucket.bucket
    }
  }

  tags = {
    Name = "Image Processor Lambda"
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_iam_role_policy.lambda_s3_policy
  ]
}

# Allow S3 to invoke Lambda
resource "aws_lambda_permission" "allow_s3_invoke" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.image_processor.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.input_bucket.arn
}

# S3 event notification → Lambda
resource "aws_s3_bucket_notification" "input_bucket_notification" {
  bucket = aws_s3_bucket.input_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.image_processor.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_s3_invoke]
}
