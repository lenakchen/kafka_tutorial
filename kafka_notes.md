
# Kafka

## Kafka Architecture Overview
* broker: where data reside
* cluster: multiple servers (more than one broker coordinating together)
* producer: can attach a schema(JSON, XML, AVRO, etc) to the msg (which can be just binary, no format)
* consumer: should not be beholden by the schema of the data for the code to work
* topic: think it as a table name as in relational database. 
* partition: kafka is scalable through splitting the topic into a configurable number of partitions. Think of kafka as a commit log, each partition can be as a separate and single log.


### Offset
A placeholder:
* last read msg position
* maintained by the consumer
* corresponds the msg identifier

producer send msg immutable


## Msg Retension Policy
1. kafka retains all published msg regardless of consumption, 
retension period is configurable with default log.retention.hours=168 (or 7 days)

2. Retension period is defined on a per-topic basis

3. Physical storage resources can constrain msg retention. log.retention.bytes is a size-based retention policy for logs, i.e the allowed size of the topic. Segments are pruned from the log as long as the remaining segments don't drop below log.retention.bytes. default: log.retention.bytes=1073741824




### Demo
1. Initate kafka zookeeper with default setting
```bash
$ cd /usr/local/bin/kafka 
/usr/local/bin/kafka$ bin/zookeeper-server-start.sh config/zookeeper.properties
...
[2019-06-10 13:56:18,052] INFO binding to port 0.0.0.0/0.0.0.0:2181 
(org.apache.zookeeper.server.NIOServerCnxnFactory)
...
```

 to verify
```bash
 $ nc -vz localhost 2181 # instead of telnet
```

2. start a single kafka broker with default setting
```bash
# prefer use multiple bootstrap servers for fault-tolerance
/usr/local/bin/kafka$ bin/kafka-server-start.sh config/server.properties
...
INFO Registered broker 0 at path /brokers/ids/0 with addresses: 
ArrayBuffer(EndPoint(mn-c02xx17yjg5m.allstate.com,9092,ListenerName(PLAINTEXT),PLAINTEXT)),
 czxid (broker epoch): 24 (kafka.zk.KafkaZkClient)
 ...
 INFO Awaiting socket connections on s0.0.0.0:9092. (kafka.network.Acceptor)
 ...
```

 3. create work for kafka
  note we need to pass in the zookeeper server because there might be multiple zookeeper instances, each managing their own independent clusters. Remember it's the zookeeper component that is responsible for assigning a broker to be responsible for the topic.


 ```bash 
 /usr/local/bin/kafka$ bin/kafka-topics.sh --create --topic my_topic \
 --zookeeper localhost:2181 --replication-factor 1 --partitions 1
WARNING: Due to limitations in metric names, topics with a period ('.') or underscore ('_') 
could collide. 
To avoid issues it is best to use either, but not both.
Created topic my_topic.
```

##### when the topic was created, the things behind the scene
1. zookeeper scanned its registry of brokers and assign a broker as leader for the topic
2. on the broker there is a log directory. In there, a new diretory was created.
```
... In the terminal of where broker is running
INFO Created log for partition my_topic-0 in /tmp/kafka-logs with properties=
...
```
* in the ```/tmp/kafka-logs/``` there is ```my_topic-0``` folder, which contains index file and log file.

4. inquire about the topics that are available on the cluster

```bash
/usr/local/bin/kafka$ bin/kafka-topics.sh --list --zookeeper localhost:2181
```

5. produce and consume some msgs
* instantiate a producer with minimal configs 
```bash
# don't use localhost:9092 which is failed to be resolved by DNS
/usr/local/bin/kafka$ bin/kafka-console-producer.sh \
--broker-list 0.0.0.0:9092 --topic my_topic
>Message 1
>MyMessage 2
>MyMessage 3
>Anything goes here ...
```


* start consumer
```bash
/usr/local/bin/kafka$ bin/kafka-console-consumer.sh \
--bootstrap-server 0.0.0.0:9092 \
 --topic my_topic --from-beginning
Message 1
MyMessage 2
MyMessage 3
Anything goes here ...
{'id': 12345}

# The *.log in /tmp/kafka-logs/my_topics-0 saved the messages with text and binary
```

```bash
# when use offset. partition is required when offset is used
/usr/local/bin/kafka$ bin/kafka-console-consumer.sh \
--bootstrap-server 0.0.0.0:9092 \
 --topic my_topic --partition 0 --offset 3
Anything goes here ...
{'id': 12345}
```

* Think of Kafka as distributed commit log, or distributed raw database that brokers read and write using publishing and subscribe semantics


##  Kafka Partitions     
Each topic has one or more partitions, so that
1. scale
2. fault-tolerance
3. higher throughput
Each partition is maintained on at least one or more brokers.

#### example of single partition

```bash

$ bin/kafka-topics.sh --create --topic my_topic \
--zookeeper localhost:2181 \
--replication-factor 1 \
--partitions 1
```

* Each topic at least has a single partition (Partition 0), the physical representation of the topic as a commit log stored on one or more broker. That log is maintained in the /tmp/kafka-logs/{topic}-{partition}/ (.index and .log)

* There is legitimate reasons for having a single partition, but there is a tradeoffs for having a single partition, which limits scalability and throughput because a physical node upon which broker and log resides is limited by certain resources.

* Each partition must fit entirely on one machine, you cannot split it into multiple machines. not to mention the IO constrains.

* In general, the scalability of apache kafka is determined by the number of partitions being managed by multiple broker nodes.

#### example: multiple partitions
```bash
$ bin/kafka-topics.sh --create --topic my_topic \
 --zookeeper localhost:2181 \
 --replication-factor 3 \
 --partitions 1
 ```
* A single topic is split across 3 different log files, ideally managed by 3 broker nodes. Each partition is mutually exclusive from one another in that they receive unique msg from a producer producing on the same topic. This enable each partition to share the burden of the msg load across different broker nodes and increase the parallelism of certain operations like msg consumption. 

* Producer establishes partitioning scheme to partition msgs
* How partitions are distributed to the available brokers
1. command to create a topic with 3 partitions is issued
2. Zookeeper, who is maintaining metadata regarding the cluster, chooses responsible leaders among the available brokers for managing a single partition within a topic.
3. Each unique Kafka broker will create a log for the newly assigned partition. 
4. As assignments are broadcast, each individual broker maintains a subset of the metadata that zoopkeeper does, particularly the mapping of what partitions are being managed by what brokers in the cluster. This enables any individual broker to direct a producer client to the appropriate broker for producing messages to a specific partition. Along the way, status is being sent by each broker to zookeeper
5. When a producer is ready to publish msgs to a topic, it must have knowledge of at least one broker in the cluster, so it can find the leaders of the topic partitions. Each broker knows which partitions are owned by which leader. The related metadata is sent to producer so it can begin to send msgs to the individual brokers or the partitions in that topic.
6. Consumer inquires of zookeeper which broker own which partitions and gets additional metadata that affects the consumer's consumption behavior, particularly when there are lots of consumers sharing the consumption workload. Consumer pulls the msg from the brokers based on the msg offset per partition. Because msgs are produced to multiple partitions and at potentially different times, consumers working with multiple partitions are likely going to consume msg in different orders, and will therefore be responsible for handling the order if it is required.



###  Partitioning Trade-offs
* The more partitions the greater the zookeeper overhead
  - with large partition numbers ensure proper zookeeper capacity
* msg ordering can become complex
  - Single partition for global ordering
  - Consumer-handling for ordering
* The more partitions the longer the leader fail-over time
  
### Fault tolerance
 - Broker failure
 - Network failure
 - Disk failure

* replication-factor: set up redudant data copies. The topic partitions have x replica at any given time.

### Replication factor
* reliable work distribution: 
    - redundancy of msg
    - cluster resiliency
    - fault-toe tlerance
* Guarantees
    - N-1 broker failure tolerance
    - minimum 2-3
* Configure on a per-topic basis
* Example of process
1. rep-factor=3, the leader gets peer brokers to participate in a quorum to replicate the log.
2. report thru cluster the number of in-sync replicas (ISRs) is equal to the rep-factor for the topic in each partition within it
3. if a quorum cannot be established and/or the number of ISRs < rep-factor, intervention may be required

### Distribution example: 3 brokers, 5 partitions, 3 replica
To distirubte, kafka use round robin.
1) randomly choose a broker as starting point, and assign partition 1-5 one by one
Broker 3: A1, A4, 
Broker 1: A2, A5
Broker 2: A3
2) for replica 1, choose starting point+1 Broker to start with
Broker 3: A1, A4, *A3R1,
Broker 1: A2, A5, *A1R1, *A4R1
Broker 2: A3,     *A2R1, *A5R1
2) for replica 2, choose starting point+2 Broker to start with
Broker 3: A1, A4, A3R1, *A2R2, *A5R2
Broker 1: A2, A5, A1R1, A4R1, *A3R2
Broker 2: A3, A2R1, A5R1, *A1R2, *A4R2

### Viewing Topic State
```bash
~$ bin/kafka-topics.sh --describe --topic my_topic \
--zookeeper localhost:2181
```
### Demo: Multi-broker Kafka Setup
* 
```bash
# setting up multi-broker on a single machine: set up a separate server.properties file for each broker
# things to change in the server-x.properties, replace x with number
# broker.id=x; listeners=PLAINTEXT://:909x; log.dirs=/tmp/kafka-logs-x; 
# run three brokers
$ bin/kafka-server-start.sh config/server-x.properties

# create new topic
 $ bin/kafka-topics.sh \
 --create --topic replicated_topic \
 --zookeeper localhost:2181 \
 --replication-factor 3 \
 --partitions 1

# check the topic
$ bin/kafka-topics.sh \
--describe --topic replicated_topic \
--zookeeper localhost:2181

Topic:replicated_topic	PartitionCount:1	ReplicationFactor:3	Configs:
Topic: replicated_topic	Partition: 0	Leader: 2	Replicas: 2,0,1	 Isr: 2,0,1
# Leader host: node 1
# Replicas for this partition 0 are on node 2, 0 and 1, in the same order as ISR
# since the ISR number is equal to Replicas, the partition and the quorum managing it are in healthy state

# create producer
$ bin/kafka-console-producer.sh \
--broker-list 0.0.0.0:9092,0.0.0.0:9093,0.0.0.0:9094 \
--topic replicated_topic
>{'id': 123}
>{'id':456}
>{'id':789}

# create consumer: --zookeeper is depreciated
$ bin/kafka-console-consumer.sh \
--bootstrap-server 0.0.0.0:9092 \
--topic replicated_topic \
--from-beginning

# simulate a broker fault by kill the session of leader node (broker id 2)
# now check the topic details: 
# the leader is changed. still 3 replicas, but only 2 in-syn replicas. this means quorum is unhealthy. If more brokers are available, kafka would already add it to the quorum and start replica.
$ bin/kafka-topics.sh \
> --describe --topic replicated_topic \
> --zookeeper localhost:2181
Topic:replicated_topic	PartitionCount:1	ReplicationFactor:3	Configs:
	Topic: replicated_topic	Partition: 0	Leader: 0	Replicas: 2,0,1	Isr: 0,1

```




## Producing msgs with Kafka Producer





##