module "dynamodb_table" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "~> 4.0"

  name      = "${var.project}-${var.environment}-transactions"
  hash_key  = "pk"
  range_key = "sk"

  attributes = [
    {
      name = "pk"
      type = "S"
    },
    {
      name = "sk"
      type = "S"
    }
  ]

  billing_mode = "PAY_PER_REQUEST"

  deletion_protection_enabled = var.environment == "prod" ? true : false

  tags = var.tags
}
