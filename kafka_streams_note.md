### Kafka Streams vs other stream processing libraries (Spark Streaming, NiFi, Flink
* spark streaming, NiFi and Flink: at least spark streaming does microbatch, 
  Kakfa streams does per data streaming
  do you want real time or micro batch time

* cluster required for spark streaming, NiFi and Flink (so cluster maintenance is required, eg. how launch and scale application)
    kafka streams don't require cluster
* Scales easily by just adding java process (no re-configuration required)
* Exactly once sematics (vs at least once for Spark)