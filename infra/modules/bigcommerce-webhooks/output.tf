output "destination" {
  description = "The destination for the BigCommerce webhook."

  value = "${aws_apigatewayv2_stage.default.invoke_url}/webhooks"
}