package com.github.lenakchen.kafka.streams;

import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.common.serialization.Serdes;
import org.apache.kafka.streams.KafkaStreams;
import org.apache.kafka.streams.StreamsBuilder;
import org.apache.kafka.streams.StreamsConfig;
import org.apache.kafka.streams.kstream.KStream;
import org.apache.kafka.streams.kstream.KTable;
import org.apache.kafka.streams.kstream.Produced;

import java.util.Arrays;
import java.util.Properties;

public class WordCountApp {
    static final String inputTopic = "streams-plaintext-input";
    static final String outputTopic = "streams-wordcount-output";



    /**
     * Define the processing topology for Word Count.
     *
     * @param builder StreamsBuilder to use
     */



    public static void main(String[] args) {

        //System.out.println("Hello world");

        Properties config = new Properties();
        config.put(StreamsConfig.APPLICATION_ID_CONFIG, "wordcount-app");
        config.put(StreamsConfig.BOOTSTRAP_SERVERS_CONFIG, "localhost:9092");
        config.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, "earliest");
        config.put(StreamsConfig.DEFAULT_KEY_SERDE_CLASS_CONFIG, Serdes.String().getClass());
        config.put(StreamsConfig.DEFAULT_VALUE_SERDE_CLASS_CONFIG, Serdes.String().getClass());

        //KStreamBuilder deprecated, use StreamsBuilder instead
        StreamsBuilder builder = new StreamsBuilder();
        // 1. Stream from Kafka
        KStream<String, String> wordCountInput = builder.stream(inputTopic);
        
        // 2. MapValues lowercase
        KTable<String, Long> wordCounts = wordCountInput
                .mapValues(textLine -> textLine.toLowerCase())
                // can be alternative written as: .mapValues(String::toLowerCase)
                // 3. FlatMapValues split by space
                .flatMapValues(lowercasedTextLine -> Arrays.asList(lowercasedTextLine.split(" ")))
                // 4. SelectKey to apply a key
                //.selectKey((ignoredKey, word) -> word)
                // 5. GroupByKey before aggregation
                .groupBy((ignoredKey, word) -> word)
                // can be alternatively .groupBy((ignoredKey, word) -> word)
                // 6. Count occurrences in each group
                // @Deprecated
                //KTable<K,java.lang.Long> count​(java.lang.String queryableStoreName)
                //Deprecated. use count(Materialized.as(queryableStoreName))
                .count();

        // 7. To in order to write the resutls back to Kfaka

        wordCounts.toStream()
                .to(outputTopic, Produced.with(Serdes.String(), Serdes.Long()));


        KafkaStreams streams = new KafkaStreams(builder.build(), config);
        streams.cleanUp();
        streams.start();

        // printed topology
        System.out.println(streams.toString());

        // shutdown hook to correctly close the Kafka Streams application
        Runtime.getRuntime().addShutdownHook(new Thread(streams::close));




    }

}
