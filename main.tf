provider "aws" {
  region = "eu-central-1"  # Update with your desired AWS region
}

# Policy document for granting permissionsLambda
data "aws_iam_policy_document" "lambda_execution_role"{
  statement {
    effect = "Allow"
    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda_execution_role" {  
  name = "lambda_execution_role"  
  assume_role_policy = data.aws_iam_policy_document.lambda_execution_role.json
}

# Generates an archive from our script to a zip file to send to Lambda.
data "archive_file" "python_lambda_package" {
  type = "zip"
  source_file = "lambda_function.py"
  output_path = "lambda.zip"
}

# Attach policies to IAM role for Lambda execution
resource "aws_iam_policy_attachment" "lambda_policy_attachment" {
  name       = "lambda_policy_attachment"
  roles      = [aws_iam_role.lambda_execution_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaKinesisExecutionRole"
}

# Attach policies to IAM role for Lambda to have access to the S3 bucket.
resource "aws_iam_policy_attachment" "lambda_policy_attachment_s3" {
  name       = "lambda_policy_s3"
  roles      = [aws_iam_role.lambda_execution_role.name]
  policy_arn = aws_iam_policy.access_s3.arn
}

# IAM policies for the resources where we define some actions to be performed. 
resource "aws_iam_policy" "access_s3" {
  name = "access_s3"
  policy =jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "s3:ListAccessPointsForObjectLambda",
                "s3:GetAccessPoint",
                "s3:PutAccountPublicAccessBlock",
                "s3:ListAccessPoints",
                "s3:CreateStorageLensGroup",
                "s3:ListJobs",
                "s3:PutStorageLensConfiguration",
                "s3:ListMultiRegionAccessPoints",
                "s3:ListStorageLensGroups",
                "s3:ListStorageLensConfigurations",
                "s3:GetAccountPublicAccessBlock",
                "s3:ListAllMyBuckets",
                "s3:ListAccessGrantsInstances",
                "s3:PutAccessPointPublicAccessBlock",
                "s3:CreateJob"
            ],
            "Resource": "*"
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": [
                "arn:aws:s3:::babbel-challenge-v1",
                "arn:aws:s3:::babbel-challenge-v1/*"
            ]
        }
    ]
  })
}
resource "aws_iam_policy" "lambda_policies" {
  name = "lambda-policy"
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "kinesis:DescribeStream",
          "kinesis:DescribeStreamSummary",
          "kinesis:GetRecords",
          "kinesis:GetShardIterator",
          "kinesis:ListShards",
          "kinesis:ListStreams",
          "kinesis:SubscribeToShard",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Effect": "Allow",
        "Resource":  ["*"]
      },
      {
        "Action": [
          "lambda:InvokeFunction",
          "lambda:GetFunctionConfiguration"
        ],
        "Effect": "Allow",
        "Resource":  [aws_lambda_function.event_processor.arn]
      }
    ]
  })
}

# Create AWS Lambda function
resource "aws_lambda_function" "event_processor" {
  filename      = "lambda.zip"
  function_name = "event-processor"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.8"
  timeout       = 60
  source_code_hash = data.archive_file.python_lambda_package.output_base64sha256
}

# Creates a Kinesis Data Stream
resource "aws_kinesis_stream" "test_stream" {
  name             = "terraform-kinesis-test"
  retention_period = 48

  shard_level_metrics = [
    "IncomingBytes",
    "OutgoingBytes",
  ]

  stream_mode_details {
    stream_mode = "ON_DEMAND"
  }
}

# Makes the stream we just created as a Trigger for lambda
resource "aws_lambda_event_source_mapping" "kinesis_event_mapping" {
  event_source_arn  = aws_kinesis_stream.test_stream.arn
  function_name     = aws_lambda_function.event_processor.arn
  starting_position = "TRIM_HORIZON"
}

# Create S3 bucket for storing transformed events
resource "aws_s3_bucket" "processed_events_bucket" {
  bucket = "babbel-challenge-v1"  # Update with your S3 bucket name
  acl    = "private"
}

# Set to false the ACL in the bucket
resource "aws_s3_bucket_public_access_block" "processed_events_bucket" {
  bucket = aws_s3_bucket.processed_events_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Policy document for granting permissions to describe the Kinesis stream
data "aws_iam_policy_document" "kinesis_describe_stream" {
  statement {
    effect = "Allow"
    
    actions = ["kinesis:DescribeStream"]

    resources = ["arn:aws:kinesis:eu-central-1:247857555516:stream/terraform-kinesis-test"]
  }
}

# IAM policy for describing the Kinesis stream
resource "aws_iam_policy" "kinesis_describe_stream" {
  name        = "kinesis-describe-stream-policy"
  policy      = data.aws_iam_policy_document.kinesis_describe_stream.json
}

# Cloudwatch log groups
resource "aws_cloudwatch_log_group" "kinesis_DS_log" {
  name = "/aws/kinesisdatastream/data_to_lambda"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name = "/aws/lambda/firehose_lambda_processor"
  retention_in_days = 14
}