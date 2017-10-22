FROM ubuntu:artful

ENV DEBIAN_FRONTEND noninteractive
ENV TERM vt100

# Get the base tools installed
RUN apt-get update                                                                         && \
    apt-get install -y apt-file gnupg htop iftop iotop libterm-readline-gnu-perl              \
                       lm-sensors make openjdk-8-jre-headless perl-doc runit-init snmp        \
                       snmp-mibs-downloader snmpd snmptrapd software-properties-common        \
                       syslog-ng syslog-ng-mod-kafka unzip vim wget                        && \
    apt-get upgrade -y                                                                     && \
    apt-get dist-upgrade -y                                                                && \
    apt-file update

# Install ZooKeeper
RUN apt-get install -y zookeeper zookeeper-bin zookeeperd

# Install Confluent REST API for Kafka
RUN wget -qO - http://packages.confluent.io/deb/3.3/archive.key | apt-key add -            && \
    add-apt-repository "deb [arch=amd64] http://packages.confluent.io/deb/3.3 stable main" && \
    apt-get update                                                                         && \
    apt-get install -y confluent-platform-oss-2.11


    
