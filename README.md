## Data Processing Pipeline README

## Technologies Chosen and Explanations

1. **Kinesis Data Stream:** Used for ingesting a high volume of events in real-time. It's scalable and durable, ensuring that no events are lost.

2. **Kinesis Data Firehose:** Routes data from the Kinesis Data Stream to S3 while handling scalability and buffering. Simplifies data delivery and management.

3. **Lambda Function:** Processes incoming events, transforms them according to specifications, and performs deduplication using DynamoDB. Serverless nature ensures scalability and cost-effectiveness.

4. **S3:** Stores transformed data partitioned based on event type and created date. Offers high durability, scalability, and cost-effectiveness for storing large volumes of data.

## Design Questions

1. Handling Duplicate Events:

    - **Approach:** Utilize the event_uuid to identify duplicates. Maintain a record of processed event UUIDs in a separate S3 prefix to filter out duplicates.
    - **Quality Metrics:**
        - **Duplicate event rate:** Percentage of events that are duplicates.
        - **Processing latency:** Time taken to identify and filter out duplicates.
        
2. Partitioning Strategy:

    - **Approach:** Partition data in S3 based on event_type and created_datetime. Adjust partitioning strategy based on changes in event volume.
    - **Scalability:** Horizontal scaling with AWS services like S3 ensures performance as the volume increases or decreases.

3. Data Storage Format:

    - **Approach:** Use JSON format for storing data in S3 for human readability. Parquet format can be considered for better performance and storage efficiency if needed.

## Conclusion
This architecture provides a robust and scalable solution for processing and storing a high volume of diverse events in real-time. By leveraging AWS services like Kinesis, Lambda, DynamoDB, and S3, we ensure efficient data processing, deduplication, and storage, while maintaining scalability and cost-effectiveness.

![Babbel_Challenge drawio](https://github.com/arpeggito/babbel_challenge/assets/145495639/c86498aa-f576-4dbc-94c7-d1a318676c39)

## How to make it work.
Note: To run this, you'll need to have the amazon cli with your account.
1. To start the AWS Services (Kinesis Data Stream, Lambda, S3), you'll need to run the following commands:
    ## terraform init
    ## terraform plan
    ## terraform apply
2. Verify of the services: You can navigate into your AWS account, and start to check that the services are up and correctly configured
    ## Kinesis Data Stream: verify that the resource was created, Capacity mode is On-Demand.
    ## Lambda: Check that the resource is created, and that the code was uploaded. (I've attached a Json file to test the script)
    ## S3 Bucket: Verify that the S3 bucket was created. 

3. To inject data to the Kinesis data stream, you can perform thje following commands

    aws kinesis put-record --stream-name terraform-kinesis-test --partition-key 12345 --data file://event2.json
    aws kinesis get-shard-iterator --shard-id shardId-xxxxxxxxx --shard-iterator-type TRIM_HORIZON --stream-name terraform-kinesis-test
    aws kinesis get-records --shard-iterator "shard iterator obtained from the previous command"

4. Verifications:
    To verify that the kinesis data stream is successfully receiving the records:
        a. go to the Data viewer tab in the Data Stream Summary
        b. Select the shard that the record was sent to
        c. Select Starting Position Trim Horizon
        d. Get records
