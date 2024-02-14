import boto3
import json
from datetime import datetime
import logging

# Setup logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

s3_client = boto3.client("s3")
dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table("processed_events")

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

def lambda_handler(event, context):
    for record in event["Records"]:
        try:
            payload = json.loads(record["kinesis"]["data"])
            event_uuid = payload["event_uuid"]

            # Check if event_uuid already processed
            response = table.get_item(Key={"event_uuid": event_uuid})
            if "Item" not in response:
                # Transform payload
                transformed_payload = transform_payload(payload)

                # Save transformed payload to S3
                save_to_s3(transformed_payload)

                # Record processed event_uuid
                table.put_item(Item={"event_uuid": event_uuid})
            else:
                logger.info(f"Event with UUID {event_uuid} already processed")
        except Exception as e:
            logger.error(f"Error processing event: {e}")

def save_to_s3(payload):
    try:
        # Save transformed payload to S3 bucket
        s3_client.put_object(
            Bucket="Babbel-Challenge",
            Key="prefix/"
            + payload["event_type"]
            + "/"
            + payload["event_subtype"]
            + "/"
            + payload["event_uuid"]
            + ".json",
            Body=json.dumps(payload),
        )
        logger.info("Payload saved to S3")
    except Exception as e:
        logger.error(f"Error saving payload to S3: {e}")
