provider "aws" {
  region = "eu-west-1"  # Update with your desired AWS region
}

data "aws_iam_policy_document" "lambda_execution_role"{
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_execution_role" {  
  name = "lambda_execution_role"  
  assume_role_policy = data.aws_iam_policy_document.lambda_execution_role.json
}

data "archive_file" "python_lambda_package" {
  type = "zip"
  source_file = "lambda_function.py"
  output_path = "lambda.zip"
}

# Create AWS Lambda function
resource "aws_lambda_function" "event_processor" {
  filename      = "lambda.zip"  # Update with your Lambda deployment package
  function_name = "event-processor"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.8"

  environment {
    variables = {
      S3_BUCKET_NAME      = "babbel-challenge"  # Update with your S3 bucket name
      S3_BUCKET_PREFIX    = "prefix/"  # Update with your S3 bucket prefix
    }
  }
}

resource "aws_kinesis_stream" "test_stream" {
  name             = "terraform-kinesis-test"
  shard_count      = 1
  retention_period = 48

  shard_level_metrics = [
    "IncomingBytes",
    "OutgoingBytes",
  ]

  stream_mode_details {
    stream_mode = "ON_DEMAND"
  }

  tags = {
    Environment = "test"
  }
}
# Create S3 bucket for storing transformed events
resource "aws_s3_bucket" "processed_events_bucket" {
  bucket = "babbel-challenge"  # Update with your S3 bucket name
  acl    = "private"
}

# Create AWS Kinesis Data Firehose delivery stream
resource "aws_kinesis_firehose_delivery_stream" "event_delivery_stream" {
  name        = "event-delivery-stream"
  destination = "extended_s3"  # Use "extended_s3" for delivering data to S3

  extended_s3_configuration {
    bucket_arn             = aws_s3_bucket.processed_events_bucket.arn  # Reference the correct bucket ARN
    compression_format     = "UNCOMPRESSED"
    role_arn               = aws_iam_role.firehose_role.arn
    prefix                 = "raw-events/"
    error_output_prefix    = "firehose-errors/"
    cloudwatch_logging_options {
      enabled = true
      log_group_name = "/aws/kinesisfirehose/event-delivery-stream"
      log_stream_name = "firehose-log-stream"
    }
    processing_configuration {
      enabled = "true"

      processors {
        type = "Lambda"

        parameters {
          parameter_name  = "LambdaArn"
          parameter_value = "${aws_lambda_function.event_processor.arn}:$LATEST"
        }
      }
    }
  }
}


# Attach policies to IAM role for Lambda execution
resource "aws_iam_policy_attachment" "lambda_policy_attachment" {
  name       = "lambda_policy_attachment"
  roles      = [aws_iam_role.lambda_execution_role.name]

  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# IAM Role for Kinesis Data Firehose
resource "aws_iam_role" "firehose_role" {
  name = "firehose_role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = {
        Service = "firehose.amazonaws.com"
      },
      Action    = "sts:AssumeRole"
    }]
  })
}

# Attach policies to IAM role for Kinesis Data Firehose
resource "aws_iam_policy_attachment" "firehose_policy_attachment" {
  name       = "firehose_policy_attachment"
  roles      = [aws_iam_role.firehose_role.name]

  #policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonKinesisFirehoseFullAccess"
  policy_arn = "arn:aws:iam::aws:policy/AmazonKinesisFirehoseFullAccess"
}