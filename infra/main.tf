terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-north-1"
}

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
  credentials_arn     = aws_iam_role.order_callback.arn
  description         = "Order callback SQS queue"
  integration_type    = "AWS_PROXY"
  integration_subtype = "SQS-SendMessage"

  request_parameters = {
    "QueueUrl"    = aws_sqs_queue.order_callback_queue.url
    "MessageBody" = "$request.body"
  }
}

resource "aws_iam_role" "order_callback" {
  name = "order-callback"

  assume_role_policy = templatefile("${path.module}/templates/order-callback-role-policy.json", {})
}

# Create logging for the API gateway.
resource "aws_cloudwatch_log_group" "bigcommerce_webhook_handler" {
  name = "/aws/api_gw/${aws_apigatewayv2_api.bigcommerce_webhook_handler.name}"

  retention_in_days = 30
}

# Create the SQS queue that allows the API gateway integration.
resource "aws_sqs_queue" "order_callback_queue" {
  name = "order-callback"

  policy = templatefile("${path.module}/templates/order-callback-role-sqs-full-access-policy.json",
    {
      order_callback_role = aws_iam_role.order_callback.arn
    }
  )
}
