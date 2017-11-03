#!/bin/bash
#set -x

####################################################################################
# This script creates a consumer for JSON data, starting at the beginning of the 
# topic's log and then subscribes to a topic.  The script then consumes some data 
# using the base URL in the first response.  Finally, the script closes the consumer
# with a DELETE to make it unsubscribe from the topic and de-register from kafka
#-----------------------------------------------------------------------------------

SUCCESS=0
ERROR=1
exit_code=${SUCCESS}

my_hostname=$(hostname | sed -e 's?\-?_?g')
my_kafka_topic="SNMP"
kafka_rest_host="http://localhost:8082"

# These variables contain place holders
consumer_create="curl -s -X POST -H \"Content-Type: application/vnd.kafka.v2+json\" --data '{\"name\": \"::MY_HOSTNAME::\", \"format\": \"json\", \"auto.offset.reset\": \"earliest\"}' ::KAFKA_REST_HOST::/consumers/my_json_consumer"
consumer_subscribe="curl -s -X POST -H \"Content-Type: application/vnd.kafka.v2+json\" --data '{\"topics\":[\"::MY_KAFKA_TOPIC::\"]}' ::KAFKA_REST_HOST::/consumers/my_json_consumer/instances/::MY_HOSTNAME::/subscription"
consumer_fetch="curl -s -X GET -H \"Accept: application/vnd.kafka.json.v2+json\" ::KAFKA_REST_HOST::/consumers/my_json_consumer/instances/::MY_HOSTNAME::/records"
consumer_delete="curl -s -X DELETE -H \"Content-Type: application/vnd.kafka.v2+json\" ::KAFKA_REST_HOST::/consumers/my_json_consumer/instances/::MY_HOSTNAME::"

# These variables replace the placeholders with real values
this_consumer_create=$(echo "${consumer_create}" | sed -e "s|::MY_HOSTNAME::|${my_hostname}|g" -e "s|::MY_KAFKA_TOPIC::|${my_kafka_topic}|g" -e "s|::KAFKA_REST_HOST::|${kafka_rest_host}|g")
this_consumer_subscribe=$(echo "${consumer_subscribe}" | sed -e "s|::MY_HOSTNAME::|${my_hostname}|g" -e "s|::MY_KAFKA_TOPIC::|${my_kafka_topic}|g" -e "s|::KAFKA_REST_HOST::|${kafka_rest_host}|g")
this_consumer_fetch=$(echo "${consumer_fetch}" | sed -e "s|::MY_HOSTNAME::|${my_hostname}|g" -e "s|::MY_KAFKA_TOPIC::|${my_kafka_topic}|g" -e "s|::KAFKA_REST_HOST::|${kafka_rest_host}|g")
this_consumer_delete=$(echo "${consumer_delete}" | sed -e "s|::MY_HOSTNAME::|${my_hostname}|g" -e "s|::MY_KAFKA_TOPIC::|${my_kafka_topic}|g" -e "s|::KAFKA_REST_HOST::|${kafka_rest_host}|g")

# WHAT: Register a new consumer
# WHY:  Because we want to subscribe to a kafka topic on ${kafka_rest_host}
#
if [ ${exit_code} -eq ${SUCCESS} ]; then
    echo -ne "Registering consumer instance ${my_hostname} with ${kafka_rest_host} ... "
    output=$(eval ${this_consumer_create})
    instance_id=$(echo "${output}" | jq ".instance_id" 2> /dev/null)

    if [ "${instance_id}" = "" -o "${instance_id}" = "null" ]; then
        message=$(echo "${output}" | jq ".message" 2> /dev/null)
        let already_exists=$(echo "${message}" | egrep -c "Consumer with specified consumer ID already exists in the specified consumer group")
    
        if [ ${already_exists} -gt 0 ]; then
            echo "SUCCESS"
        else
            echo "ERROR"
            echo "    Error Message: ${message}"
            exit_code=${ERROR}
        fi
    
    else
        base_uri=$(echo "${output}" | jq ".base_uri" 2> /dev/null)
        echo "SUCCESS"
        echo "    Registered consumer as ${base_uri}"
        sleep 5
    fi

fi

# WHAT: Subscribe to a kafka topic
# WHY:  Because we successfully registered ourselves as a consumer
#
if [ ${exit_code} -eq ${SUCCESS} ]; then
    echo -ne "Subscribing to kafka topic ${my_kafka_topic} ... "
    output=$(eval ${this_consumer_subscribe})
    message=$(echo "${output}" | jq ".[]")

    if [ "${message}" != "" ]; then
        echo "ERROR"
        echo "    Error Message: ${message}"
        exit_code=${ERROR}
    else
        echo "SUCCESS"
        echo "    Subscribed to kafka topic ${my_kafka_topic}"
        sleep 5
    fi

fi
        
# WHAT: Retrieve data from kafka via the rest api
# WHY:  The reason we are here
#
if [ ${exit_code} -eq ${SUCCESS} ]; then
    echo "Starting data fetch ... "

    # Iterate 10 times
    let counter=0
    
    while [ ${counter} -lt 2 ]; do
        sleep 12
        clear
        eval ${this_consumer_fetch} | jq ".[]"
        let counter=${counter}+1
    done

    # Finish up
    echo "Destroying consumer ... "
    eval ${this_consumer_delete}
fi

exit ${exit_code}

# NOTES:
####################################################################################
# Produce a message using JSON with the value '{ "foo": "bar" }' to the topic SNMP
#-----------------------------------------------------------------------------------
#    eval curl -X POST -H "Content-Type: application/vnd.kafka.json.v2+json" \
#        -H "Accept: application/vnd.kafka.v2+json" \
#        --data '{"records":[{"value":{"foo":"bar"}}]}' "${kafka_rest_host}/topics/${my_kafka_topic}"
#
####################################################################################
# Successful registration of consumer looks something like this:
#-----------------------------------------------------------------------------------
#    {
#      "instance_id": "upboard_01",
#      "base_uri": "http://localhost:8082/consumers/my_json_consumer/instances/upboard_01"
#    }
#
####################################################################################
# Trying to register a consumer that is already registered looks like this:
#-----------------------------------------------------------------------------------
#    {
#      "error_code": 40902,
#      "message": "Consumer with specified consumer ID already exists in the specified consumer group."
#    }

