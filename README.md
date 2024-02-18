## Data Processing Pipeline README

## Technologies Chosen and Explanations

1. **Kinesis Data Stream:** Used for ingesting a high volume of events in real-time. It's scalable and durable, ensuring that no events are lost.

2. **Lambda Function:** Processes incoming events, transforms them according to specifications of the challenge, and performs separation of duplicated. Serverless nature ensures scalability and cost-effectiveness.

3. **S3:** Stores transformed data partitioned based on event type and created date. Offers high durability, scalability, and cost-effectiveness for storing large volumes of data.

4. **Python:** To perform the data manipulation/transformation.

5. **Terraform:** To deploy the AWS resources as IaC.

## Design Questions

1. Handling Duplicate Events:

    - **Approach:** Utilize the event_uuid to identify duplicated events. Maintain a record of processed event UUIDs in a separate S3 prefix to filter out duplicates.
    - **Quality Metrics:**
        - **Duplicate event rate:** Percentage of events that are duplicates.
        - **Processing latency:** Time taken to identify and filter out duplicates.
        
2. Partitioning Strategy:

    - **Approach:** Since I'm utilizing the On-Demand feature of Kinesis, my approach will be to have shards/partition based on type of events because of the Dynamic Scaling (Scale up at shard level when the patterns of traffic are too high, and scale down when the traffic is low), this approach also provides isolation and efficiency by dedicating shards to specific event types which can lead to more efficient resource utilization, and also cost efficiency with On-Demand mode, you pay only for the resources you use, without the need to provision capacity in advance. 
    - **Scalability:** Horizontal scaling with AWS services like Kinesis on-demand mode, Lambda and S3 ensures performance as the volume increases or decreases. 

3. Data Storage Format:

    - **Approach:** Use JSON format for storing data in S3 for human readability. Parquet format can be considered for better performance and storage efficiency if needed (Maybe for a Data Analysis perspective)

![Babbel_Challenge drawio](https://github.com/arpeggito/babbel_challenge/assets/145495639/edff27c8-7602-44d9-aeda-85f2fff1f6b9)

## How to make it work.
- Note: To run this, you'll need to have the Amazon Cli with your account.
## 1. To start the AWS Services (Kinesis Data Stream, Lambda, S3), you'll need to run the following commands:
   
    a. terraform init

    b. terraform plan

    c. terraform apply
   
## 2. Verify the services: You can navigate into your AWS account, and start to check that the services are up and correctly configured

    - Kinesis Data Stream: verify that the resource was created, Capacity mode is On-Demand.

    ![Terraform_kinesis_datastream](https://github.com/arpeggito/babbel_challenge/assets/145495639/5691223b-ed35-404e-90b5-ba7780f6dad4)

    - Lambda: Check that the function is created with the Kinesis Data Stream as a trigger source. (I've attached a JSON file to test the script)
    
    ![image](https://github.com/arpeggito/babbel_challenge/assets/145495639/6ed19eec-e017-4740-a895-8a8d7c94fc59)

    - S3 Bucket: Verify that the S3 bucket was created.

    ![S3_bucket](https://github.com/arpeggito/babbel_challenge/assets/145495639/9541c06e-b1b2-4c9e-9c4f-46b6e0baaae6)

   


## 3. To inject data into the Kinesis data stream, you can perform the following commands

    - aws kinesis put-record --stream-name terraform-kinesis-test --partition-key 12345 --data file://event2.json

    - aws kinesis get-shard-iterator --shard-id shardId-xxxxxxxxx --shard-iterator-type TRIM_HORIZON --stream-name terraform-kinesis-test

    - aws kinesis get-records --shard-iterator "shard iterator obtained from the previous command"

## 4. Verifications:
    To verify that the kinesis data stream is successfully receiving the records:
        a. go to the Data Viewer tab in the Data Stream Summary
        b. Select the shard that the record was sent to
        c. Select Starting Position Trim Horizon
        d. Get records
       ![Kinesis_Stream_validation](https://github.com/arpeggito/babbel_challenge/assets/145495639/ba1a1fe9-01ea-4337-9b46-b09c2e85076b)

   To verify if the Lambda is performing the transformation:
        a. Go to the S3 bucket
        b. Check if there's a 'prefix/' and 'duplicated/' folder
           Note: The duplicated folder will only show up if you send 2 times the same event with the same 'UUID'
        ![image](https://github.com/arpeggito/babbel_challenge/assets/145495639/99fbf3b4-73b6-4162-afaa-77a8ac64e7ef)

## Conclusion
This architecture provides a robust and scalable solution for processing and storing a high volume of diverse events in real-time. By leveraging AWS services like Kinesis, Lambda, and S3, we ensure efficient data processing, deduplication, and storage, while maintaining scalability and cost-effectiveness.


