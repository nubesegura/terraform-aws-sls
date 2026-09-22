data "aws_caller_identity" "current" {}

module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.0"

  bucket = "${var.project}-${var.environment}-data-${data.aws_caller_identity.current.account_id}"

  force_destroy = true # Useful for dev/qa environments

  # Block Public Access
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  versioning = {
    enabled = true
  }

  lifecycle_rule = [
    {
      id      = "expire-old-files"
      enabled = true
      expiration = {
        days = var.s3_retention_days
      }
    }
  ]

  tags = var.tags
}

# Notification to trigger Lambda on ObjectCreated
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = module.s3_bucket.s3_bucket_id

  lambda_function {
    lambda_function_arn = module.lambda_processor.lambda_function_arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".csv"
  }

  depends_on = [
    module.lambda_processor
  ]
}
