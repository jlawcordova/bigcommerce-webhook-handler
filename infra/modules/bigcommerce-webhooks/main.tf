# Create the API Gateway, its stages, routes, role and integrations.
resource "aws_apigatewayv2_api" "bigcommerce_webhook" {
  name          = var.project
  protocol_type = "HTTP"

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.bigcommerce_webhook.id
  name        = "default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.bigcommerce_webhook_api_gateway.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
      }
    )
  }
}

resource "aws_apigatewayv2_route" "bigcommerce_webhook" {
  api_id = aws_apigatewayv2_api.bigcommerce_webhook.id

  route_key = "POST /webhooks"
  target    = "integrations/${aws_apigatewayv2_integration.bigcommerce_webhook.id}"
}

resource "aws_apigatewayv2_integration" "bigcommerce_webhook" {
  api_id              = aws_apigatewayv2_api.bigcommerce_webhook.id
  credentials_arn     = aws_iam_role.bigcommerce_webhook_api_gateway_integration.arn
  description         = "SQS integration with the BigCommerce webhook API Gateway."
  integration_type    = "AWS_PROXY"
  integration_subtype = "SQS-SendMessage"

  request_parameters = {
    "QueueUrl"    = aws_sqs_queue.bigcommerce_webhook.url
    "MessageBody" = "$request.body"
  }
}

resource "aws_iam_role" "bigcommerce_webhook_api_gateway_integration" {
  name = "${var.project}-api-gateway-integration"

  assume_role_policy = templatefile("${path.module}/templates/bigcommerce-webhook-api-gateway-role-policy.json", {})

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

# Create logging for the API gateway.
resource "aws_cloudwatch_log_group" "bigcommerce_webhook_api_gateway" {
  name = "/aws/api_gw/${aws_apigatewayv2_api.bigcommerce_webhook.name}"

  retention_in_days = 30

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

# Create the SQS queue that allows the API gateway integration.
resource "aws_sqs_queue" "bigcommerce_webhook" {
  name = var.project

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_sqs_queue_policy" "bigcommerce_webhook" {
  queue_url = aws_sqs_queue.bigcommerce_webhook.id
  policy = templatefile("${path.module}/templates/bigcommerce-webhook-sqs-queue-policy.json",
    {
      bigcommerce_webhook_api_gateway_integration_role = aws_iam_role.bigcommerce_webhook_api_gateway_integration.arn
    }
  )
}

# Setup the Lambda function, its roles, and corresponding S3 bucket.
resource "aws_lambda_function" "bigcommerce_webhook" {
  function_name = var.project

  s3_bucket = aws_s3_bucket.bigcommerce_webhook.id
  s3_key    = aws_s3_object.bigcommerce_webhook.key

  runtime = "nodejs18.x"
  handler = "index.handler"

  source_code_hash = data.archive_file.bigcommerce_webhook.output_base64sha256
  role             = aws_iam_role.bigcommerce_webhook_lambda.arn

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_s3_bucket" "bigcommerce_webhook" {
  bucket = "${var.project}"

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_s3_object" "bigcommerce_webhook" {
  bucket = aws_s3_bucket.bigcommerce_webhook.id

  key    = "src.zip"
  source = data.archive_file.bigcommerce_webhook.output_path

  etag = filemd5(data.archive_file.bigcommerce_webhook.output_path)
}

data "archive_file" "bigcommerce_webhook" {
  type = "zip"

  output_path = "${path.module}/src.zip"
  source_dir  = "${path.module}${var.lambda_src_path}"
}

resource "aws_iam_role" "bigcommerce_webhook_lambda" {
  name = "${var.project}-lambda"

  assume_role_policy = templatefile("${path.module}/templates/bigcommerce-webhook-lambda-role-policy.json", {})

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

# Create logging for the Lambda function.
resource "aws_cloudwatch_log_group" "bigcommerce_webhook_lambda" {
  name = "/aws/lambda/${aws_lambda_function.bigcommerce_webhook.function_name}"

  retention_in_days = 30

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}
