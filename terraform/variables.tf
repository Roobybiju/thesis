variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "eu-north-1"
}

variable "input_bucket_name" {
  description = "Base name of the S3 bucket for raw input images"
  type        = string
  default     = "input-images-bucket"
}

variable "output_bucket_name" {
  description = "Base name of the S3 bucket for processed images"
  type        = string
  default     = "processed-images-bucket"
}

variable "lambda_function_name" {
  description = "Name of the Lambda image-processor function"
  type        = string
  default     = "image-processor"
}
