### Apache Kafka Series - Kafka Streams for Data Processing 
# Linux / mac only

# open a shell - zookeeper is at localhost:2181
cd /usr/local/bin/kafka 
bin/zookeeper-server-start.sh config/zookeeper.properties

# open another shell - kafka is at localhost:9092
cd /usr/local/bin/kafka 
bin/kafka-server-start.sh config/server.properties

# open another shell - 
# creat input topic
cd /usr/local/bin/kafka 
bin/kafka-topics.sh --create --zookeeper localhost:2181 --replication-factor 1 --partitions 1 \
--topic streams-plaintext-input

# creat output topic
cd /usr/local/bin/kafka 
bin/kafka-topics.sh --create --zookeeper localhost:2181 --replication-factor 1 --partitions 1 \
--topic streams-wordcount-output

# check the topics
cd /usr/local/bin/kafka 
bin/kafka-topics.sh --zookeeper localhost:2181 --list

# start a kafka producer
cd /usr/local/bin/kafka 
bin/kafka-console-producer.sh --broker-list 0.0.0.0:9092 --topic streams-plaintext-input
# enter
kafka streams udemy
kafka data processing
kafka streams course
kafka sql
kafka streams udemy
kafka data processing
kafka streams course
kafka sql
data sql
test

# { error_ocurred: false, span_type: web, span_created_at: 1561651420495, host_id: 101, endpoint_id: 121886 }
# { error_ocurred: false, span_type: web, span_created_at: 1561651421469, host_id: 65, endpoint_id: 174776 }
# { error_ocurred: true, span_type: web, span_created_at: 1561651421468, host_id: 86, endpoint_id: 108803 }
# { error_ocurred: false, span_type: database, span_created_at: 1561651422475, host_id: 104, endpoint_id: 17494 }
# { error_ocurred: false, span_type: database, span_created_at: 1561651426296, host_id: 82, endpoint_id: 174786 }
# { error_ocurred: false, span_type: web, span_created_at: 1561651442452, host_id: 89, endpoint_id: 108808 }
# { error_ocurred: true, span_type: web, span_created_at: 1561651444614, host_id: 78, endpoint_id: 108750 }

# open another shell
# start a kafka consumer to verify the data has been written
cd /usr/local/bin/kafka 
bin/kafka-console-consumer.sh --bootstrap-server 0.0.0.0:9092 --topic streams-plaintext-input --from-beginning

 # start a consumer on the output topic
cd /usr/local/bin/kafka 
bin/kafka-console-consumer.sh --bootstrap-server 0.0.0.0:9092 \
--topic streams-wordcount-output --from-beginning \
 --formatter kafka.tools.DefaultMessageFormatter \
 --property print.key=true \
 --property print.value=true \
 --property key.deserializer=org.apache.kafka.common.serialization.StringDeserializer \
 --property value.deserializer=org.apache.kafka.common.serialization.LongDeserializer

# observing the streaming after running word count
# kafka	1
# streams	1
# udemy	1
# kafka	2
# data	1
# processing	1
# kafka	3
# streams	2
# course	1
# kafka	4
# sql	1
# kafka	5
# streams	3
# udemy	2
# kafka	6
# data	2
# processing	2
# kafka	7
# streams	4
# course	2
# kafka	8
# sql	2
# data	3
# sql	3
# test	1
 # start the streams application
 cd /usr/local/bin/kafka
 bin/kafka-run-class.sh org.apache.kafka.streams.examples.wordcount.WordCountDemo





 # install java8 and maven
brew install maven
 # install IntelliJ
 # create new Maven project in IntelliJ
 # add new dependency in pom.xml
 # type  <dependencies></dependencies>
 # find the latest kafka stream maven and copy paste the dependency 
 # then search for slf4j: use slf4j-api and slf4j-log4j12
 # remove <scope>test</scope>
 <dependencies>
        <!-- https://mvnrepository.com/artifact/org.apache.kafka/kafka-streams -->
        <dependency>
            <groupId>org.apache.kafka</groupId>
            <artifactId>kafka-streams</artifactId>
            <version>2.3.0</version>
        </dependency>

        <!-- https://mvnrepository.com/artifact/org.slf4j/slf4j-api -->
        <dependency>
            <groupId>org.slf4j</groupId>
            <artifactId>slf4j-api</artifactId>
            <version>1.7.26</version>
        </dependency>

        <!-- https://mvnrepository.com/artifact/org.slf4j/slf4j-log4j12 -->
        <dependency>
            <groupId>org.slf4j</groupId>
            <artifactId>slf4j-log4j12</artifactId>
            <version>1.7.26</version>
        </dependency>

    </dependencies>


    # go to src/main/resource and create a new file, log4j.properties, which prints into console

    # add plugins into pom.xml
    <build>
        <plugins>
            # add maven compiler plugin and java plugin (to build fat jar)
        </plugins>

    </build>


# WordCount Streams App Properties
# 1. bootstrap.servers: need to connect to kafka (usually port 9092)
# 2. auto.offset.rest.config: set to `earliest` to consume the topic from start
# 3. application.id: specific to Streams application only, will be used for
#   * Consumer group.id = application.id (most important one to remember)
#   * Default client.id prefix
#   * Prefix to internal changelog topics
# don't change the application.id often, if you change, the Kakfa Streams think it's a new stream application 
# and restart processing your data
# 4. default.[key|value].serde (for Serialization and Deserialization of data)


# Go to src/main/java/, create new Java class with name of your groupId.ClassName
`com.github.lenakchen.kafka.streams.StreamsStarterApp`
# in the class `public class StreamsStarterApp`, type `psvm` and click tab:
`public static void main(String[] args) {

    }`

# Java 8 Lambda Functions
#e.g KStream<String, Long> stream = ...;
`stream.filter((key, value) -> value > 0 );`
# the types of key and value and inferred at compile time


# WordCount Streams App Topology
# Remember data in Kafka Streams is <Key, Value>
# 1. Stream: from Kafka                                                    <null, "Kafka Kafka Streams">
# 2. MapValues: lowercase                                                  <null, "kafka kafka streams">
# 3. FlatMapValues: split by space                   <null, "kafka">, <null, "kafka">, <null, "streams"> 
# 4. SelectKey: to apply a key            <"kafka", "kafka">, <"kafka", "kafka">, <"streams", "streams">
# 5. GroupByKey: before aggregation    (<"kafka", "kafka">, <"kafka", "kafka">), (<"streams", "streams">)
# 6. Count: occurrences in each group                                        <"kafka", 2>, <"streams", 1>
# 7. To: in order to write the resutls back to Kfaka                       data point is written to Kafka


# Adding a shutdown hood is key to allow for a graceful shutdown of the Kafka
# Streams application, which will help the speed of restart
# This should be in every Kafka Streams application you create
// Add shutdown hook to stop the Kafka Streams threads
// You can optionally provide a timeout to 'close'
Runtime.getRuntime().addShutdownHook(new Thread(streams::close))


# WordCount running from IntelliJ
# 1. create the final topic using kafka-topics
// launch zookeeper, kafka broker, 
# 2. run a kafka-console-consumer to the final topic
# 3. run the application from IntelliJ
# 4. publish some more data to the input topic using kafka-console-producer


# Scaling our application

