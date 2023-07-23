resource "aws_apigatewayv2_api" "bigcommerce_webhook_handler" {
  name          = "bigcommerce_webhook_handler"
  protocol_type = "HTTP"
}

# Create the API Gateway, its routes, role and integrations.
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.bigcommerce_webhook_handler.id
  name        = "default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.bigcommerce_webhook_handler.arn

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

resource "aws_apigatewayv2_route" "order_callback" {
  api_id = aws_apigatewayv2_api.bigcommerce_webhook_handler.id

  route_key = "POST /order-callback"
  target    = "integrations/${aws_apigatewayv2_integration.order_callback.id}"
}

resource "aws_apigatewayv2_integration" "order_callback" {
  api_id              = aws_apigatewayv2_api.bigcommerce_webhook_handler.id
  credentials_arn     = aws_iam_role.order_callback_api_gateway.arn
  description         = "Order callback SQS queue"
  integration_type    = "AWS_PROXY"
  integration_subtype = "SQS-SendMessage"

  request_parameters = {
    "QueueUrl"    = aws_sqs_queue.order_callback.url
    "MessageBody" = "$request.body"
  }
}

# Create logging for the API gateway.
resource "aws_cloudwatch_log_group" "bigcommerce_webhook_handler" {
  name = "/aws/api_gw/${aws_apigatewayv2_api.bigcommerce_webhook_handler.name}"

  retention_in_days = 30
}

# Create the SQS queue that allows the API gateway integration.
resource "aws_sqs_queue" "order_callback" {
  name = "order-callback"
}

resource "aws_sqs_queue_policy" "order_callback" {
  queue_url = aws_sqs_queue.order_callback.id
  policy = templatefile("${path.module}/templates/order-callback-role-sqs-full-access-policy.json",
    {
      order_callback_role = aws_iam_role.order_callback_api_gateway.arn
    }
  )
}

resource "aws_iam_role" "order_callback_api_gateway" {
  name = "order-callback-api-gateway"

  assume_role_policy = templatefile("${path.module}/templates/order-callback-api-gateway-role-policy.json", {})
}

# Setup the Lambda function.
resource "aws_lambda_function" "order_callback" {
  function_name = "order-callback"

  s3_bucket = aws_s3_bucket.order_callback.id
  s3_key    = aws_s3_object.order_callback.key

  runtime = "nodejs18.x"
  handler = "index.handler"

  source_code_hash = data.archive_file.order_callback.output_base64sha256
  role             = aws_iam_role.order_callback_lambda.arn
}

# Setup the Lambda function roles and policies.
resource "aws_iam_role" "order_callback_lambda" {
  name = "order-callback-lambda"

  assume_role_policy = templatefile("${path.module}/templates/order-callback-lambda-role-policy.json", {})
}

# Setup the bucket for the Lambda function code.
resource "aws_s3_bucket" "order_callback" {
  bucket = var.order_callback_bucket_name
}

resource "aws_s3_object" "order_callback" {
  bucket = aws_s3_bucket.order_callback.id

  key    = "src.zip"
  source = data.archive_file.order_callback.output_path

  etag = filemd5(data.archive_file.order_callback.output_path)
}

data "archive_file" "order_callback" {
  type = "zip"

  output_path = "${path.module}/src.zip"
  source_dir  = "${path.module}/../src"
}

resource "aws_cloudwatch_log_group" "order_callback" {
  name = "/aws/lambda/order-callback"

  retention_in_days = 30
}
