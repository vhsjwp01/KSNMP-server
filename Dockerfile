FROM ubuntu:artful

MAINTAINER Jason W. Plummer "vhsjwp01@gmail.com"

ENV DEBIAN_FRONTEND noninteractive
ENV TERM vt100

# Get the base tools installed
RUN apt-get update -y                                                                      && \
    apt-get --allow-unauthenticated -o Dpkg::Options::="--force-confold" install -y           \
            apt-file curl elinks gnupg htop iftop iotop jq libterm-readline-gnu-perl          \
            lm-sensors make openjdk-8-jre-headless perl-doc runit-init snmp                   \
            snmp-mibs-downloader snmpd snmptrapd software-properties-common syslog-ng         \
            syslog-ng-mod-kafka unzip vim wget                                             && \
    apt-get upgrade -y                                                                     && \
    apt-get dist-upgrade -y                                                                && \
    apt-file update

# Install Confluent REST API for Kafka
RUN wget -qO - http://packages.confluent.io/deb/3.3/archive.key | apt-key add -            && \
    add-apt-repository "deb [arch=amd64] http://packages.confluent.io/deb/3.3 stable main" && \
    apt-get update                                                                         && \
    apt-get install -y confluent-platform-oss-2.11

# Install ZooKeeper
RUN apt-get install -y zookeeper zookeeper-bin zookeeperd

# Install Kafka
RUN mirror=$(curl --stderr /dev/null https://www.apache.org/dyn/closer.cgi\?as_json\=1 |      \
    jq -r '.preferred')                                                                    && \
    latest_kafka=$(elinks -verbose 1 -dump 1 "${mirror}kafka/?C=M;O=A" |                      \
    egrep "${mirror}kafka/" | awk '{print $NF}' | tail -1)                                 && \
    url=$(elinks -verbose 1 -dump 1 "${latest_kafka}?C=M;O=A" |                               \
    egrep "${latest_kafka}kafka_.*\.tgz$" | awk '{print $NF}' | tail -1)                   && \
    local_archive=$(echo "${url}" | awk -F'/' '{print $NF}')                               && \
    local_dirname=$(echo "${local_archive}" | sed -e 's/\.tgz$//g')                        && \
    wget -q "${url}" -O "/tmp/${local_archive}"                                            && \
    tar xf "/tmp/${local_archive}" -C /opt                                                 && \
    ln -s "/opt/${local_dirname}" "/opt/kafka-latest"                                      && \
    rm -rf "/tmp/${local_archive}"

