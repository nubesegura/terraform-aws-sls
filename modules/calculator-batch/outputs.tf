output "api_endpoint" {
  description = "The URL of the API Gateway endpoint"
  value       = aws_api_gateway_stage.this.invoke_url
}

output "s3_bucket_name" {
  description = "The name of the S3 bucket for CSV uploads"
  value       = module.s3_bucket.s3_bucket_id
}

output "dynamodb_table_name" {
  description = "The name of the DynamoDB table"
  value       = module.dynamodb_table.dynamodb_table_id
}
