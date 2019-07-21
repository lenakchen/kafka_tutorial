# open a shell - zookeeper is at localhost:2181
cd /usr/local/bin/kafka 
bin/zookeeper-server-start.sh config/zookeeper.properties

# open another shell - kafka is at localhost:9092
cd /usr/local/bin/kafka 
bin/kafka-server-start.sh config/server.properties

# open another shell - 
# creat input topic with two partitions
cd /usr/local/bin/kafka 
bin/kafka-topics.sh --create --zookeeper localhost:2181 --replication-factor 1 --partitions 2 \
--topic streams-plaintext-input

# creat output topic
cd /usr/local/bin/kafka 
bin/kafka-topics.sh --create --zookeeper localhost:2181 --replication-factor 1 --partitions 2 \
--topic streams-wordcount-output

# launch a consumer on the output topic
cd /usr/local/bin/kafka 
bin/kafka-console-consumer.sh --bootstrap-server 0.0.0.0:9092 \
--topic streams-wordcount-output --from-beginning \
 --formatter kafka.tools.DefaultMessageFormatter \
 --property print.key=true \
 --property print.value=true \
 --property key.deserializer=org.apache.kafka.common.serialization.StringDeserializer \
 --property value.deserializer=org.apache.kafka.common.serialization.LongDeserializer

# launch the streams application in IntelliJ

# start a kafka producer
cd /usr/local/bin/kafka 
bin/kafka-console-producer.sh --broker-list 0.0.0.0:9092 --topic streams-plaintext-input

# package your application as a fat jar
cd ~/Develop/kafka_tutorial/streams_starter
mvn clean package
  

# run your fat jar
cd ~/Develop/kafka_tutorial/streams_starter
java -jar target/word-count-1.0-SNAPSHOT-jar-with-dependencies.jar 

# list all topics that we have in Kafka (so we can observe the internal topics)
cd /usr/local/bin/kafka 
bin/kafka-topics.sh --list --zookeeper localhost:2181
# the following results contain internal topics
__consumer_offsets
streams-plaintext-input
streams-wordcount-output
wordcount-app-KSTREAM-AGGREGATE-STATE-STORE-0000000004-changelog # the application.id prefix
wordcount-app-KSTREAM-AGGREGATE-STATE-STORE-0000000004-repartition

# launch a consumer on the internal topic
cd /usr/local/bin/kafka 
bin/kafka-console-consumer.sh --bootstrap-server 0.0.0.0:9092 \
--topic wordcount-app-KSTREAM-AGGREGATE-STATE-STORE-0000000004-changelog \
--from-beginning \
 --formatter kafka.tools.DefaultMessageFormatter \
 --property print.key=true \
 --property print.value=true \
 --property key.deserializer=org.apache.kafka.common.serialization.StringDeserializer \
 --property value.deserializer=org.apache.kafka.common.serialization.LongDeserializer
