resource "aws_api_gateway_rest_api" "this" {
  name        = "${var.project}-${var.environment}-api"
  description = "API Gateway for querying calculator transactions"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = var.tags
}

resource "aws_api_gateway_resource" "query" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "query"
}

resource "aws_api_gateway_method" "get_query" {
  rest_api_id      = aws_api_gateway_rest_api.this.id
  resource_id      = aws_api_gateway_resource.query.id
  http_method      = "GET"
  authorization    = "NONE"
  api_key_required = true
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.query.id
  http_method             = aws_api_gateway_method.get_query.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.lambda_query.lambda_function_invoke_arn
}

resource "aws_api_gateway_deployment" "this" {
  depends_on = [aws_api_gateway_integration.lambda_integration]

  rest_api_id = aws_api_gateway_rest_api.this.id

  # Hack to force deployment on changes
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.query.id,
      aws_api_gateway_method.get_query.id,
      aws_api_gateway_integration.lambda_integration.id
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "this" {
  deployment_id = aws_api_gateway_deployment.this.id
  rest_api_id   = aws_api_gateway_rest_api.this.id
  stage_name    = var.environment

  tags = var.tags
}

resource "aws_api_gateway_api_key" "this" {
  name  = "${var.project}-${var.environment}-key"
  value = var.api_key

  tags = var.tags
}

resource "aws_api_gateway_usage_plan" "this" {
  name        = "${var.project}-${var.environment}-usage-plan"
  description = "Usage plan for ${var.environment}"

  api_stages {
    api_id = aws_api_gateway_rest_api.this.id
    stage  = aws_api_gateway_stage.this.stage_name
  }

  tags = var.tags
}

resource "aws_api_gateway_usage_plan_key" "this" {
  key_id        = aws_api_gateway_api_key.this.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.this.id
}
