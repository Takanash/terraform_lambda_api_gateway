variable "access_key" {}
variable "aws_profile" {}
variable "secret_key" {}
variable "region" {}
variable "lambda_bucket_name" {}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  required_version = ">= 1.2.0"
  backend "s3" {}
}

provider "aws" {
  profile    = var.aws_profile
  region     = var.region
  access_key = var.access_key
  secret_key = var.secret_key
}

locals {
  tmp_dir = "tmp"
  hello_lambda_function_name = "hello"
  hello_api_gateway_name = "hello"
}

# for Lambda
resource "aws_s3_bucket" "lambda_bucket" {
  bucket = var.lambda_bucket_name
}

data "archive_file" "lambda_hello_world" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${local.tmp_dir}/${local.hello_lambda_function_name}.zip"
}

resource "aws_s3_object" "lambda_hello" {
  bucket = aws_s3_bucket.lambda_bucket.id

  key = "${local.hello_lambda_function_name}.zip"
  source = data.archive_file.lambda_hello_world.output_path

  etag = filemd5(data.archive_file.lambda_hello_world.output_path)
}

resource "aws_lambda_function" "hello" {
  function_name = local.hello_lambda_function_name

  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key    = aws_s3_object.lambda_hello.key

  runtime = "python3.11"
  handler = "${local.hello_lambda_function_name}.lambda_handler"

  source_code_hash = data.archive_file.lambda_hello_world.output_base64sha256
  role = aws_iam_role.lambda_exec.arn
}

resource "aws_cloudwatch_log_group" "hello" {
  name = "/aws/lambda/${aws_lambda_function.hello.function_name}"
  retention_in_days = 7
}

resource "aws_iam_role" "lambda_exec" {
  name = "lambda_${local.hello_lambda_function_name}_exec"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_exec.name
}

# for API Gateway
resource "aws_apigatewayv2_api" "lambda" {
  name          = "lambda_${local.hello_api_gateway_name}_gw"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "lambda" {
  name          = "lambda_${local.hello_api_gateway_name}_stage"
  api_id        = aws_apigatewayv2_api.lambda.id
  auto_deploy   = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.arn
      format          = jsonencode({
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
      })
  }
}

resource "aws_apigatewayv2_integration" "hello" {
  api_id        = aws_apigatewayv2_api.lambda.id
  integration_uri = aws_lambda_function.hello.invoke_arn
  integration_type = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "hello" {
  api_id  = aws_apigatewayv2_api.lambda.id
  route_key = "GET /hello"
  target = "integrations/${aws_apigatewayv2_integration.hello.id}"
}

resource "aws_cloudwatch_log_group" "api_gw" {
  name = "/aws/apigateway/${aws_apigatewayv2_api.lambda.name}"
  retention_in_days = 7
}

resource "aws_lambda_permission" "api_gw" {
  statement_id = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.hello.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.lambda.execution_arn}/*/*"
}
