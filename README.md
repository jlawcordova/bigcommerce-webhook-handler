# BigCommerce Order Callback Handler
A REST API callback handler for BigCommerce order webhooks. Made with AWS resources - API Gateway, SQS, and Lambda.

# Initialize the Infrastructure
All infrastructure are deployed using [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli) with the AWS provider. Make sure you have are [authenticated to your AWS account](https://docs.aws.amazon.com/cli/latest/userguide/sso-configure-profile-token.html#sso-configure-profile-token-auto-sso-session).

```
aws configure sso
```

Got to the [`infra``](./infra/) directory then initialize and apply the terraform configurations.

```
cd infra
terraform init
terraform apply
```