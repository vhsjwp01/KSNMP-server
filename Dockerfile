FROM ubuntu:artful

MAINTAINER Jason W. Plummer "vhsjwp01@gmail.com"

ENV DEBIAN_FRONTEND noninteractive

ENV TERM vt100

ENV ZOO_DATA_DIR /data/zookeeper
ENV ZOO_LOG_DIR /data/logs/zookeeper

ENV KAFKA_DATA_DIR /data/kafpa
ENV KAFKA_LOG_DIR /data/logs/kafpa

# Get the base tools installed
RUN apt-get update -y                                                                      && \
    apt-get --allow-unauthenticated -o Dpkg::Options::="--force-confold" install -y           \
            apt-file curl elinks gnupg htop iftop iotop jq libterm-readline-gnu-perl          \
            lm-sensors make net-tools openjdk-8-jre-headless perl-doc runit-init snmp         \
            snmp-mibs-downloader snmpd snmptrapd software-properties-common syslog-ng         \
            syslog-ng-mod-kafka unzip vim wget                                             && \
    apt-get upgrade -y                                                                     && \
    apt-get dist-upgrade -y                                                                && \
    apt-file update

# Install Confluent REST API for Kafka
# NOTE: Confluent provides an apt repo for installing their software
RUN wget -qO - http://packages.confluent.io/deb/3.3/archive.key | apt-key add -            && \
    add-apt-repository "deb [arch=amd64] http://packages.confluent.io/deb/3.3 stable main" && \
    apt-get update                                                                         && \
    apt-get install -y confluent-platform-oss-2.11

# Install ZooKeeper
# NOTE: ubuntu v17 has packaged versions of zookeeper
RUN apt-get install -y zookeeper zookeeper-bin zookeeperd

# Install Kafka
# NOTE: This block figures out the nearest apache mirror, then figures out the
#       latest version of kafka, then figures out the latest version of scala
#       that goes with it.  It then downloads the archive, unpacks it, then removes
#       the archive for housekeeping
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

# Configure ZooKeeper for standalone operations
COPY files/zookeeper/etc/zookeeper/conf/zoo.cfg /etc/zookeeper/conf/
RUN chmod 644 /etc/zookeeper/conf/zoo.cfg
RUN if [ ! -d "${ZOO_DATA_DIR}" ]; then                                                               \
        mkdir -p "${ZOO_DATA_DIR}"                                                                  ;  \
    fi                                                                                              ; \
    if [ ! -d "${ZOO_LOG_DIR}" ]; then                                                                \
        mkdir -p "${ZOO_LOG_DIR}"                                                                   ; \
    fi                                                                                              ; \
    chown -R zookeeper:zookeeper "${ZOO_DATA_DIR}"                                                  && \
    chown -R zookeeper:zookeeper "${ZOO_LOG_DIR}"                                                   && \
    sed -i -e "s|^ZOO_LOG_DIR=.*$|ZOO_LOG_DIR=${ZOO_LOG_DIR}|g" /etc/zookeeper/conf/environment

# Configure Kafka for standalone operations
