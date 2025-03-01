# AWS Kinesis Source connector



## Objective

Quickly test [Kinesis Connector](https://docs.confluent.io/current/connect/kafka-connect-kinesis/index.html#quick-start) connector.

## AWS Setup

* Make sure you have an [AWS account](https://docs.aws.amazon.com/streams/latest/dev/before-you-begin.html#setting-up-sign-up-for-aws).
* Set up [AWS Credentials](https://docs.confluent.io/current/connect/kafka-connect-kinesis/index.html#aws-credentials)

You can either export environment variables `AWS_REGION`, `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` or set files `~/.aws/credentials` and `~/.aws/config`.

Example:

```
[default]
aws_access_key_id=xxx
aws_secret_access_key=xxx
region=eu-west-3
```

Make sure that region corresponds to the one used by the test (eu-west-3 by default), otherwise the conector will fail to start with `Stream does not exist`.

## How to run

Simply run:

```
$ ./kinesis-source.sh
```

## Details of what the script is doing

Create a Kinesis stream `kafka_docker_playground` in $AWS_REGION region:

```
$ aws kinesis create-stream --stream-name $KINESIS_STREAM_NAME --shard-count 1
```

Insert records in Kinesis stream:

```
$ aws kinesis put-record --stream-name $KINESIS_STREAM_NAME --partition-key 123 --data test-message-1
```

The connector is created with:

```
curl -X PUT \
     -H "Content-Type: application/json" \
     --data '{
        "connector.class":"io.confluent.connect.kinesis.KinesisSourceConnector",
               "tasks.max": "1",
               "kafka.topic": "kinesis_topic",
               "kinesis.stream": "'"$KINESIS_STREAM_NAME"'",
               "confluent.license": "",
               "name": "kinesis-source",
               "confluent.topic.bootstrap.servers": "broker:9092",
               "confluent.topic.replication.factor": "1"
          }' \
     http://localhost:8083/connectors/kinesis-source/config | jq .
```

Verify we have received the data in kinesis_topic topic:

```
$ docker exec broker kafka-console-consumer --bootstrap-server broker:9092 --topic kinesis_topic --from-beginning --max-messages 1
```

Delete your stream and clean up resources to avoid incurring any unintended charges:

```
aws kinesis delete-stream --stream-name $KINESIS_STREAM_NAME
```

N.B: Control Center is reachable at [http://127.0.0.1:9021](http://127.0.0.1:9021])
