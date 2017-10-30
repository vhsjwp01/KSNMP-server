WHAT:
This Dockerfile sends JSON tokenized SNMP traps to a kafka message queue

WHY:
In order to create a structured log of SNMP events in a resilient way

HOW:
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
    - A custom written BASH script that reads in a list of SNMP OIDs and them queries SNMPd
8) Runit
    - An alternative init system replacement used inside the docker container to coordinate service resiliency

How to use this Docker Project
1) Build the container:
    - git clone <this project>
    - cd <this project>
    - docker build .
2) Run the container
    - docker run -d -p 8082:8082 <container image hash>
    - NOTE: If you want to use persistent storage with pure docker, use this command instead:
        - docker run -d -p 8082:8082 -v <some folder path>:/data <container image hash>
    - NOTE: If you want to tuse persistent storage with docker swarm, use this command instead:
        - dockewr service create --name kdnmp-server -p 8082:8082 --mount src=<some folder name>,dst=/data <container image hash>
3) Connect to the service running at localhost:8082 using the Confluent documentation as as reference
    - https://docs.confluent.io/current/kafka-rest/docs/intro.html
    - An example script:
        - https://github.com/corneel/SNMP-Server/blob/master/kafka-rest_config/debian_ubuntu/xenial/usr/local/bin/kafka-rest_commands.sh

Configurable Runtime Variables: (defaults shown below)
|Environmant Variable    |Default Value                |
|------------------------|-----------------------------|
|DATA_DIR                |/data                        |
|KAFKA_DATA_DIR          |${DATA_DIR}/kafka            |
|ZK_DATA_DIR             |${DATA_DIR}/zookeeper        |
|------------------------|-----------------------------|
|KAFKA_LOG_DIR           |${DATA_DIR}/logs/kafka       |
|KAFKA_REST_LOG_DIR      |${DATA_DIR}/logs/kafka-rest  |
|SNMP_PERFMON_LOG_DIR    |${DATA_DIR}/logs/snmp-perfmon|
|SNMPD_LOG_DIR           |${DATA_DIR}/logs/snmpd       |
|SNMPTRAP_LOG_DIR        |${DATA_DIR}/logs/snmp        |
|SNMPTRAPD_LOG_DIR       |${DATA_DIR}/logs/snmptrapd   |
|SYSLOG_NG_LOG_DIR       |${DATA_DIR}/logs/syslog-ng   |
|ZK_LOG_DIR              |${DATA_DIR}/logs/zookeeper   |
|------------------------|-----------------------------|
|KAFKA_LOG_FILE          |kafka_runtime.log            |
|KAFKA_REST_LOG_FILE     |kafka-rest_runtime.log       |
|SNMP_PERFMON_LOG_FILE   |snmp-perfmon_runtime.log     |
|SNMPD_LOG_FILE          |snmpd_runtime.log            |
|SNMPTRAP_JSON_FILE      |snmptrapd_json.log           |
|SNMPTRAP_LOG_FILE       |snmptrapd.log                |
|SNMPTRAPD_LOG_FILE      |snmptrapd_runtime.log        |
|SYSLOG_NG_LOG_FILE      |syslog-ng_runtime.log        |
|ZK_LOG_FILE             |zookeeper_runtime.log        |
|------------------------|-----------------------------|
|KAFKA_BROKER_ID         |0                            |
|KAFKA_ZK_CONNECT        |localhost:2181/SNMP          |
|------------------------|-----------------------------|
|SYSLOG_NG_KAFKA_CONNECT |localhost:9092               |
|SYSLOG_NG_KAFKA_TOPIC   |SNMP                         |
