import boto3
import json
from datetime import datetime
import logging
import base64

# Setup logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Define the S3 Client
s3_client = boto3.client("s3")

# Transform payload as per requirements' to add additional fields to the events.
def transform_payload(payload):
    payload ["created_datetime"] = datetime.utcfromtimestamp(
            payload["created_at"]
        ).isoformat()
        
    payload["event_type"] = payload["event_name"].split(":")[0]
    
    payload["event_subtype"] = payload["event_name"].split(":")[1]
    
    return payload

def save_to_s3(payload):
    try:
        # Check if the UUID already exists in S3
        s3_client.head_object(
            Bucket="babbel-challenge-v1",
            Key=f'prefix/{payload["event_type"]}/{payload["event_subtype"]}/{payload["event_uuid"]}.json'
        )

        folder_path = "duplicated"
        s3_client.put_object(
            Bucket="babbel-challenge-v1",
            Key=f'{folder_path}/{payload["event_uuid"]}.json',
            Body=json.dumps(payload),
        )

    except s3_client.exceptions.ClientError as e:
        folder_path = f'prefix/{payload["event_type"]}/{payload["event_subtype"]}'

        # Save transformed payload to S3 bucket
        s3_client.put_object(
            Bucket="babbel-challenge-v1",
            Key=f'{folder_path}/{payload["event_uuid"]}.json',
            Body=json.dumps(payload),
        )
        logger.info("Payload saved to S3")

# Main lambda function
def lambda_handler(event, context):
    for record in event["Records"]:
        try:
            payload = json.loads(base64.b64decode(record["kinesis"]["data"]))

            # Transform payload
            transformed_payload = transform_payload(payload)

            # Save transformed payload to S3
            save_to_s3(transformed_payload)

        except Exception as e:
            logger.error(f"Error processing event: {e}")

