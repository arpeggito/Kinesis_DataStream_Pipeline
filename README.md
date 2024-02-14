## Data Processing Pipeline README

## Technologies Chosen and Explanations

1. **Kinesis Data Stream:** Used for ingesting a high volume of events in real-time. It's scalable and durable, ensuring that no events are lost.

2. **Kinesis Data Firehose:** Routes data from the Kinesis Data Stream to S3 while handling scalability and buffering. Simplifies data delivery and management.

3. **Lambda Function:** Processes incoming events, transforms them according to specifications, and performs deduplication using DynamoDB. Serverless nature ensures scalability and cost-effectiveness.

4. **DynamoDB:** Stores processed event UUIDs to filter out duplicates. Provides fast and scalable database operations.

5. **S3:** Stores transformed data partitioned based on event type and created date. Offers high durability, scalability, and cost-effectiveness for storing large volumes of data.

## Design Questions

1. Handling Duplicate Events:

    - **Approach:** Utilize the event_uuid to identify duplicates. Maintain a record of processed event UUIDs in DynamoDB to filter out duplicates before processing.
    - **Quality Metrics:**
        - **Duplicate event rate:** Percentage of events that are duplicates.
        - **Processing latency:** Time taken to identify and filter out duplicates.

        -**NOTE:** This is I've selected DynamoDB, since it provides fast and predictable performance, making it suitable for storing and querying large volumes of data. Its scalability ensures that it can handle the high throughput of event UUID queries in real-time.

2. Partitioning Strategy:

    - **Approach:** Partition data in S3 based on event_type and created_datetime. Adjust partitioning strategy based on changes in event volume.
    - **Scalability:** Horizontal scaling with AWS services like S3 ensures performance as the volume increases or decreases.

3. Data Storage Format:

    - **Approach:** Use JSON format for storing data in S3 for human readability. Parquet format can be considered for better performance and storage efficiency if needed.

## Conclusion
This architecture provides a robust and scalable solution for processing and storing a high volume of diverse events in real-time. By leveraging AWS services like Kinesis, Lambda, DynamoDB, and S3, we ensure efficient data processing, deduplication, and storage, while maintaining scalability and cost-effectiveness.

![Babbel_Challenge drawio](https://github.com/arpeggito/babbel_challenge/assets/145495639/c86498aa-f576-4dbc-94c7-d1a318676c39)
