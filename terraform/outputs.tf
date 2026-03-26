output "input_bucket_name" {
  description = "Name of the input S3 bucket"
  value       = aws_s3_bucket.input_bucket.bucket
}

output "output_bucket_name" {
  description = "Name of the output S3 bucket"
  value       = aws_s3_bucket.output_bucket.bucket
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.image_processor.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.image_processor.arn
}

output "lambda_execution_role_arn" {
  description = "ARN of the Lambda IAM execution role"
  value       = aws_iam_role.lambda_execution_role.arn
}

output "aws_account_id" {
  description = "AWS Account ID used for deployment"
  value       = data.aws_caller_identity.current.account_id
}
