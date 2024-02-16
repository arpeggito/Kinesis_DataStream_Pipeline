import boto3
import json
from datetime import datetime
import logging

# Setup logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

s3_client = boto3.client("s3")

def transform_payload(payload):
    # Transform payload as per requirements
    transformed_payload = {
        "created_datetime": datetime.utcfromtimestamp(
            payload["created_at"]
        ).isoformat(),
        "event_type": payload["event_name"].split(":")[0],
        "event_subtype": payload["event_name"].split(":")[1],
        # Add other required fields
    }
    return transformed_payload

def save_to_s3(payload):
    try:
        # Check if the UUID already exists in S3
        existing_objects = s3_client.list_objects_v2(
            Bucket="babbel-challenge-v1",
            Prefix=f"prefix/{payload['event_type']}/{payload['event_subtype']}/{payload['event_uuid']}.json"
        )

        # If the UUID already exists, store the file in a duplicated folder
        if existing_objects.get("KeyCount", 0) > 0:
            folder_path = "duplicated/"
        else:
            # Create folder path based on event type and subtype
            folder_path = f"prefix/{payload['event_type']}/{payload['event_subtype']}/"

        # Save transformed payload to S3 bucket
        s3_client.put_object(
            Bucket="babbel-challenge-v1",
            Key=f"{folder_path}{payload['event_uuid']}.json",
            Body=json.dumps(payload),
        )
        logger.info("Payload saved to S3")
    except Exception as e:
        logger.error(f"Error saving payload to S3: {e}")

def lambda_handler(event, context):
    # for record in event["Records"]:
    try:
        payload = json.loads(event)

        # Transform payload
        transformed_payload = transform_payload(payload)

        # Save transformed payload to S3
        save_to_s3(transformed_payload)

    except Exception as e:
        logger.error(f"Error processing event: {e}")


