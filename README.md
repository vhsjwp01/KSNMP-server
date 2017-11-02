<b>WHAT:</b><gr>
This Dockerfile sends JSON tokenized SNMP traps to a kafka message queue

<b>WHY:</b><gr>
In order to create a structured log of SNMP events in a resilient way

<b>HOW:</b><gr>
This Dockerfile uses the following open source tools:
1) ZooKeeper
    - ZooKeeper is the communication backplane for Kafka brokers
2) Kafka
    - Kafka is the message queue service
3) SNMPTrapd
    - SNMPTrapd listens for incoming SNMP Traps and logs them
4) SNMPd
    - SNMPd listens for SNMP OID requests and returns their values
5) Syslog-NG
    - Reads in SNMPTrapd logs, JSON tokenizes them, then sends them to kafka
6) Kafka-REST
    - Provides a RESTful API for kafka message topic consumption
7) SNMP-PerMon
    - A custom written BASH script that reads in a list of SNMP OIDs and then queries SNMPd
8) Runit
    - An alternative init system replacement used inside the docker container to coordinate service resiliency

<b>HOW TO USE THIS DOCKER PROJECT:</b><br>
1) Build the container:
    - <tt>git clone \<this project\></tt>
    - <tt>cd \<this project\></tt>
    - <tt>docker build .</tt>
        - <i><b>NOTE:</b> you can name the image using an addition build switch:</i><br>
            <tt>docker build . -t \<some name\></tt>
            - <i><b>NOTE:</b> the </i>'<tt>-t</tt>'<i> switch stands for </i>'<tt>tag</tt>'<i> and docker tags <b>*MUST BE* lowercase</b></i>
2) Run the container
    - <tt>docker run -d -p 8082:8082 \<container image hash\> OR \<tag name\></tt>
        - <i><b>NOTE:</b> you can also choose to name the running instance like so:</i><br>
            <tt>docker run -d -p 8082:8082 --name \<some name\> \<tag name\></tt>
            - <i><b>NOTE:</b> the value of the </i>'<tt>--name</tt>'<i> switch <b>*MUST BE* lowercase</b></i>
        - <i><b>NOTE:</b> If you want to use persistent storage with pure docker, use this command instead:</i><br>
            - <tt>docker run -d -p 8082:8082 -v \<some folder path\>:/data \<container image hash\></tt>
        - <i><b>NOTE:</b> If you want to use persistent storage with <b>docker swarm</b>, use this command instead:</i><br>
            - <tt>docker service create --name ksnmp-server -p 8082:8082 --mount src=\<some folder name\>,dst=/data \<container image hash\></tt>
3) Connect to the service running at localhost:8082 using the Confluent documentation as as reference
    - https://docs.confluent.io/current/kafka-rest/docs/intro.html
    - An example script:
        - https://github.com/corneel/SNMP-Server/blob/master/kafka-rest_config/debian_ubuntu/xenial/usr/local/bin/kafka-rest_commands.sh

Configurable Runtime Variables: (defaults shown below)
<pre>
- DATA_DIR                /data
- KAFKA_DATA_DIR          ${DATA_DIR}/kafka
- ZK_DATA_DIR             ${DATA_DIR}/zookeeper

- KAFKA_LOG_DIR           ${DATA_DIR}/logs/kafka
- KAFKA_REST_LOG_DIR      ${DATA_DIR}/logs/kafka-rest
- SNMP_PERFMON_LOG_DIR    ${DATA_DIR}/logs/snmp-perfmon
- SNMPD_LOG_DIR           ${DATA_DIR}/logs/snmpd
- SNMPTRAP_LOG_DIR        ${DATA_DIR}/logs/snmp
- SNMPTRAPD_LOG_DIR       ${DATA_DIR}/logs/snmptrapd
- SYSLOG_NG_LOG_DIR       ${DATA_DIR}/logs/syslog-ng
- ZK_LOG_DIR              ${DATA_DIR}/logs/zookeeper

- KAFKA_LOG_FILE          kafka_runtime.log
- KAFKA_REST_LOG_FILE     kafka-rest_runtime.log
- SNMP_PERFMON_LOG_FILE   snmp-perfmon_runtime.log
- SNMPD_LOG_FILE          snmpd_runtime.log
- SNMPTRAP_JSON_FILE      snmptrapd_json.log
- SNMPTRAP_LOG_FILE       snmptrapd.log
- SNMPTRAPD_LOG_FILE      snmptrapd_runtime.log
- SYSLOG_NG_LOG_FILE      syslog-ng_runtime.log
- ZK_LOG_FILE             zookeeper_runtime.log

- KAFKA_BROKER_ID         0
- KAFKA_ZK_CONNECT        localhost:2181/SNMP

- SYSLOG_NG_KAFKA_CONNECT localhost:9092
- SYSLOG_NG_KAFKA_TOPIC   SNMP
</pre>
