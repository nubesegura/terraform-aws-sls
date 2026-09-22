# -----------------------------------------------------------------------------
# LAMBDA 1: CSV Processor
# -----------------------------------------------------------------------------
data "archive_file" "lambda_processor_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src/processor"
  output_path = "${path.module}/processor.zip"
}

module "lambda_processor" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 7.0"

  function_name = "${var.project}-${var.environment}-processor"
  description   = "Processes CSV from S3 and saves to DynamoDB"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.13"

  create_package         = false
  local_existing_package = data.archive_file.lambda_processor_zip.output_path

  environment_variables = {
    DYNAMODB_TABLE_NAME = module.dynamodb_table.dynamodb_table_id
  }

  create_current_version_allowed_triggers = false
  allowed_triggers = {
    AllowExecutionFromS3Bucket = {
      principal  = "s3.amazonaws.com"
      source_arn = module.s3_bucket.s3_bucket_arn
    }
  }

  attach_policy_statements = true
  policy_statements = {
    s3_read = {
      effect    = "Allow",
      actions   = ["s3:GetObject"],
      resources = ["${module.s3_bucket.s3_bucket_arn}/*"]
    },
    dynamodb_write = {
      effect = "Allow",
      actions = [
        "dynamodb:PutItem",
        "dynamodb:BatchWriteItem"
      ],
      resources = [module.dynamodb_table.dynamodb_table_arn]
    }
  }

  tags = var.tags
}

# -----------------------------------------------------------------------------
# LAMBDA 2: API Query
# -----------------------------------------------------------------------------
data "archive_file" "lambda_query_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src/query"
  output_path = "${path.module}/query.zip"
}

module "lambda_query" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 7.0"

  function_name = "${var.project}-${var.environment}-query"
  description   = "API Gateway target to query transactions"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.13"

  create_package         = false
  local_existing_package = data.archive_file.lambda_query_zip.output_path

  environment_variables = {
    DYNAMODB_TABLE_NAME = module.dynamodb_table.dynamodb_table_id
  }

  create_current_version_allowed_triggers = false
  allowed_triggers = {
    APIGatewayAny = {
      service    = "apigateway"
      source_arn = "${aws_api_gateway_rest_api.this.execution_arn}/*/*"
    }
  }

  attach_policy_statements = true
  policy_statements = {
    dynamodb_read = {
      effect = "Allow",
      actions = [
        "dynamodb:Query",
        "dynamodb:Scan"
      ],
      resources = [module.dynamodb_table.dynamodb_table_arn]
    }
  }

  tags = var.tags
}
