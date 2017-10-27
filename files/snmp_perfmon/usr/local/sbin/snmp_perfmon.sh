#!/bin/bash
#set -x

TERM="vt100"
PATH="/bin:/usr/bin:/usr/local/bin:/sbin:/usr/sbin:/usr/local/sbin"
export TERM PATH

# ==========
# TRAP Type:
# ==========
# The TYPE is a single character, one of:
#              i  INTEGER
#              u  UNSIGNED
#              c  COUNTER32
#              s  STRING
#              x  HEX STRING
#              d  DECIMAL STRING
#              n  NULLOBJ
#              o  OBJID
#              t  TIMETICKS
#              a  IPADDRESS
#              b  BITS
#       which are handled in the same way as the snmpset command.

# ========================
# System Performance OIDs:
# ========================
# ----------------------------
# Network Interface Statistics
# ----------------------------
# 
# List NIC names: .1.3.6.1.2.1.2.2.1.2
# Get Bytes IN: .1.3.6.1.2.1.2.2.1.10
# Get Bytes IN for NIC 4: .1.3.6.1.2.1.2.2.1.10.4
# Get Bytes OUT: .1.3.6.1.2.1.2.2.1.16
# Get Bytes OUT for NIC 4: .1.3.6.1.2.1.2.2.1.16.4
# 
# ----------------------------
# CPU Statistics
# ----------------------------
# 
# Load
# 1 minute Load: .1.3.6.1.4.1.2021.10.1.3.1
# 5 minute Load: .1.3.6.1.4.1.2021.10.1.3.2
# 15 minute Load: .1.3.6.1.4.1.2021.10.1.3.3
# 
# CPU times
# percentage of user CPU time: .1.3.6.1.4.1.2021.11.9.0
# raw user cpu time: .1.3.6.1.4.1.2021.11.50.0
# percentages of system CPU time: .1.3.6.1.4.1.2021.11.10.0
# raw system cpu time: .1.3.6.1.4.1.2021.11.52.0
# percentages of idle CPU time: .1.3.6.1.4.1.2021.11.11.0
# raw idle cpu time: .1.3.6.1.4.1.2021.11.53.0
# raw nice cpu time: .1.3.6.1.4.1.2021.11.51.0
# 
# ----------------------------
# Memory Statistics
# ----------------------------
# 
# Total Swap Size: .1.3.6.1.4.1.2021.4.3.0
# Available Swap Space: .1.3.6.1.4.1.2021.4.4.0
# Total RAM in machine: .1.3.6.1.4.1.2021.4.5.0
# Total RAM used: .1.3.6.1.4.1.2021.4.6.0
# Total RAM Free: .1.3.6.1.4.1.2021.4.11.0
# Total RAM Shared: .1.3.6.1.4.1.2021.4.13.0
# Total RAM Buffered: .1.3.6.1.4.1.2021.4.14.0
# Total Cached Memory: .1.3.6.1.4.1.2021.4.15.0
# 
# ----------------------------
# Disk Statistics
# ----------------------------
# 
# Add the following line to snmpd.conf and restart:
# 
# includeAllDisks 10% for all partitions and disks
# 
# Disk OID's
# 
# Path where the disk is mounted: .1.3.6.1.4.1.2021.9.1.2.1
# Path of the device for the partition: .1.3.6.1.4.1.2021.9.1.3.1
# Total size of the disk/partion (kBytes): .1.3.6.1.4.1.2021.9.1.6.1
# Available space on the disk: .1.3.6.1.4.1.2021.9.1.7.1
# Used space on the disk: .1.3.6.1.4.1.2021.9.1.8.1
# Percentage of space used on disk: .1.3.6.1.4.1.2021.9.1.9.1
# Percentage of inodes used on disk: .1.3.6.1.4.1.2021.9.1.10.1
# 
# ----------------------------
# System Uptime: .1.3.6.1.2.1.1.3.0
# ----------------------------

OID_DATA_DIR="/data"
OID_DATA_FILE="oids.txt"

if [ ! -e "${OID_DATA_DIR}/${OID_DATA_FILE}" ]; then
    oid_list=".1.3.6.1.4.1.2021.10.1.3.1 \
              .1.3.6.1.4.1.2021.11.11.0  \
              .1.3.6.1.4.1.2021.4.11.0   \
              .1.3.6.1.4.1.2021.9.1.7.1  \
              .1.3.6.1.2.1.1.3.0"

    for oid in ${oid_list} ; do
        echo "${oid}" >> "${OID_DATA_DIR}/${OID_DATA_FILE}"
    done

fi

OID_LIST=$(awk '{print $0}' "${OID_DATA_DIR}/${OID_DATA_FILE}")

my_snmpget=$(which snmpget 2> /dev/null)
my_snmptrap=$(which snmptrap 2> /dev/null)
snmp_get_auth_string="-c -v3 -l authPriv  -u local-snmp-agent -a sha -A Str0ng@uth3ntic@ti0n -x aes -X Str0ngPriv@cy"
snmptrap_args="-v 2c -c public"

let sleep_interval=60

# If we have an argument, it should be the sleep interval (as a positive integer)
if [ "${1}" != "" ]; then
    let is_posint=$(echo "${1}>0" | bc 2> /dev/null)

    if [ "${is_posint}" = "" ]; then
        let SLEEP_INTERVAL=${sleep_interval}
    elif [ ${is_posint} -gt 0 ]; then
        let SLEEP_INTERVAL=${1}
    else
        let SLEEP_INTERVAL=${sleep_interval}
    fi

else
    SLEEP_INTERVAL=${sleep_interval}
fi

# March through the OIDs of interest, perform an snmpget, 
# then shovel it back in as an snmptrap
#
if [ "${my_snmpget}" != "" -a "${my_snmptrap}" != "" ]; then

    while [ ${SLEEP_INTERVAL} -gt 0 ]; do

        for my_OID in ${OID_LIST} ; do
            output=$(${my_snmpget} ${snmp_get_auth_string} localhost ${my_OID})
            #echo "${output}"

            if [ "${output}" != "" ]; then
                mib_attribute=$(echo "${output}" | awk '{print $1}')
                mib_attribute_type=$(echo "${output}" | awk -F' = ' '{print $NF}' | awk -F':' '{print $1}' | tr '[A-Z]' '[a-z]')
                mib_attribute_value=$(echo "${output}" | awk -F':' '{print $NF}' | awk '{print $1}' | egrep -iv "No Such Instance|No Such Object")
                value_type=""

                case ${mib_attribute_type} in

                    "integer")
                        value_type="i"
                    ;;

                    "unsigned")
                        value_type="u"
                    ;;

                    "counter32")
                        value_type="c"
                    ;;

                    "string")
                        value_type="s"
                    ;;

                    "hex string")
                        value_type="x"
                    ;;

                    "decimal string")
                        value_type="d"
                    ;;

                    "nullobj")
                        value_type="n"
                    ;;

                    "objid")
                        value_type="o"
                    ;;

                    "timeticks")
                        value_type="t"
                        mib_attribute_value=$(echo "${output}" | awk -F'(' '{print $NF}' | awk -F')' '{print $1}')
                    ;;

                    "ipaddress")
                        value_type="a"
                    ;;

                    "bits")
                        value_type="b"
                    ;;

                    *)
                        value_type="unknown"
                    ;;

                esac

            fi

            if [ "${mib_attribute}" != "" -a "${mib_attribute_type}" != "" -a "${mib_attribute_value}" != "" ]; then

                if [ "${value_type}" != "unknown" ]; then
                    ${my_snmptrap} ${snmptrap_args} localhost "$(hostname)-${mib_attribute}" ${my_OID} ${mib_attribute} ${value_type} ${mib_attribute_value}
                fi

            fi

        done

        sleep ${SLEEP_INTERVAL}
    done

fi
