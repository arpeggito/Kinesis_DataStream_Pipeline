provider "aws" {
  region = "us-east-1"  # Update with your desired AWS region
}

# Create DynamoDB table for storing processed event UUIDs
resource "aws_dynamodb_table" "processed_events_table" {
  name           = "processed_events"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "event_uuid"
  attribute {
    name = "event_uuid"
    type = "S"
  }
}

# Create AWS Lambda function
resource "aws_lambda_function" "event_processor" {
  filename      = "lambda.zip"  # Update with your Lambda deployment package
  function_name = "event-processor"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "lambda.lambda_handler"
  runtime       = "python3.8"

  environment {
    variables = {
      DYNAMODB_TABLE_NAME = aws_dynamodb_table.processed_events_table.name
      S3_BUCKET_NAME      = aws_s3_bucket.processed_events_bucket.id
    }
  }
}

# Create AWS Kinesis stream
resource "aws_kinesis_stream" "event_stream" {
  name             = "event-stream"
  shard_count      = 0  # Set shard_count to 0 for on-demand capacity mode
}

# Create AWS Kinesis Data Firehose delivery stream
resource "aws_kinesis_firehose_delivery_stream" "event_delivery_stream" {
  name        = "event-delivery-stream"
  destination = "s3"

  s3_configuration {
    bucket_arn             = aws_s3_bucket.processed_events_bucket.arn
    buffer_size            = 5
    buffer_interval        = 60
    compression_format     = "UNCOMPRESSED"
    role_arn               = aws_iam_role.firehose_role.arn
    prefix                 = "raw-events/"
    error_output_prefix    = "firehose-errors/"
    cloudwatch_logging_options {
      enabled = true
      log_group_name = "/aws/kinesisfirehose/event-delivery-stream"
      log_stream_name = "firehose-log-stream"
    }
  }
}

# Create S3 bucket for storing transformed events
resource "aws_s3_bucket" "processed_events_bucket" {
  bucket_prefix = "processed-events"
}

# IAM Role for Lambda execution
resource "aws_iam_role" "lambda_execution_role" {
  name               = "lambda_execution_role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      },
      Action    = "sts:AssumeRole"
    }]
  })

  # Attach policies
  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Action    = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      Resource  = "arn:aws:logs:*:*:*"
    },{
      Effect   = "Allow",
      Action   = "dynamodb:*",
      Resource = aws_dynamodb_table.processed_events_table.arn
    },{
      Effect   = "Allow",
      Action   = "s3:*",
      Resource = "${aws_s3_bucket.processed_events_bucket.arn}/*"
    },{
      Effect   = "Allow",
      Action   = "kinesis:*",
      Resource = aws_kinesis_stream.event_stream.arn
    }]
  })
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
  inline_policy {
    name = "firehose_policy"
    policy = jsonencode({
      Version = "2012-10-17",
      Statement = [{
        Effect    = "Allow",
        Action    = [
          "s3:AbortMultipartUpload",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:PutObject",
          "s3:PutObjectAcl"
        ],
        Resource  = [
          aws_s3_bucket.processed_events_bucket.arn,
          "${aws_s3_bucket.processed_events_bucket.arn}/*"
        ]
      },{
        Effect   = "Allow",
        Action   = [
          "kinesis:DescribeStream",
          "kinesis:GetShardIterator",
          "kinesis:GetRecords"
        ],
        Resource = aws_kinesis_stream.event_stream.arn
      }]
    })
  }
}

# IAM Role Policy Attachment for Lambda execution
resource "aws_iam_role_policy_attachment" "lambda_execution" {
  policy_arn = aws_iam_policy.lambda_execution.arn
  role       = aws_iam_role.lambda_execution_role.name
}

# IAM Role Policy Attachment for Kinesis Data Firehose
resource "aws_iam_role_policy_attachment" "firehose_delivery" {
  policy_arn = aws_iam_policy.firehose_delivery.arn
  role       = aws_iam_role.firehose_role.name
}