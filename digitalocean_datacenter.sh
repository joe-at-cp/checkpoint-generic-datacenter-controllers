#!/bin/bash

#Digital Ocean API Default Settings
APIKEY=""
TIMER="120"
DEBUG_LOG="/var/log/datacenter.log"
OUTPUT_FILE="digitalocean_${API_REGION}.json"

#Input Parameters
POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -r|--region)
    API_REGION="$2"
    shift # past argument
    shift # past value
    ;;
    -t|--time)
    TIMER="$2"
    shift # past argument
    shift # past value
    ;;
    -o|--output)
    OUTPUT_FILE="$2"
    shift # past argument
    shift # past value
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

while true; do
 
    #Write JSON Header
    #-------------------------------------------------------------------------------------------
    echo '{' > $OUTPUT_FILE
    echo '     "version": "1.0",' >> $OUTPUT_FILE
    echo '     "description": "Digital Ocean",' >> $OUTPUT_FILE
    echo '     "objects": [' >> $OUTPUT_FILE
    #-------------------------------------------------------------------------------------------

    INSTANCE_JSON=$(curl_cli -s -k -X GET "https://api.digitalocean.com/v2/droplets" -H "Authorization: Bearer ${APIKEY}")
    INSTANCE_NUMBER=$(echo ${INSTANCE_JSON} | jq .meta.total -r)
    COUNT=0

    until [ $COUNT -eq $INSTANCE_NUMBER ]; do

        INSTANCE_NAME=$(echo ${INSTANCE_JSON} | jq .droplets[${COUNT}].name -r)
        INSTANCE_ID=$(echo ${INSTANCE_JSON} | jq .droplets[${COUNT}].id -r)
        INSTANCE_IF_NUMBER=$(echo ${INSTANCE_JSON} | jq '.droplets['${COUNT}'].networks.v4 | length')
        INSTANCE_PROFILE=$(echo ${INSTANCE_JSON} | jq .droplets[${COUNT}].size.slug -r)
        INSTANCE_VPC=$(echo ${INSTANCE_JSON} | jq .droplets[${COUNT}].region.slug -r)

        #Print
        echo " - Name: ${INSTANCE_NAME}"
        echo "   ID: ${INSTANCE_ID}"
        echo "   Profile: ${INSTANCE_PROFILE}"
        echo "   Region: ${INSTANCE_VPC}"
        echo "   Interfaces:"

        #Write JSON Instance Entry
        #-------------------------------------------------------------------------------------------
        echo '                          {' >> $OUTPUT_FILE
        echo '                               "name": "'${INSTANCE_NAME}'",' >> $OUTPUT_FILE
        echo '                               "id": "'${INSTANCE_ID}'",' >> $OUTPUT_FILE
        echo '                               "description": "Region: '${INSTANCE_VPC}', Profile: '${INSTANCE_PROFILE}'",' >> $OUTPUT_FILE
        echo '                               "ranges": [' >> $OUTPUT_FILE
        #-------------------------------------------------------------------------------------------

        INTERFACE_COUNT=0
        until [ "$INTERFACE_COUNT" == "$INSTANCE_IF_NUMBER" ]; do

            INSTANCE_IF_IP=$(echo ${INSTANCE_JSON} | jq .droplets[${COUNT}].networks.v4[${INTERFACE_COUNT}].ip_address -r)

            #Print
            echo "   - ${INSTANCE_IF_IP}"
            (( INTERFACE_COUNT++ ))

            #Write JSON Instance Interface Entries
            #-------------------------------------------------------------------------------------------
            if [ $INTERFACE_COUNT == $INSTANCE_IF_NUMBER ]; then
                #Last interface
                echo '                                                 "'${INSTANCE_IF_IP}'"' >> $OUTPUT_FILE
            else
                echo '                                                 "'${INSTANCE_IF_IP}'",' >> $OUTPUT_FILE
            fi
            #-------------------------------------------------------------------------------------------
            
        done

        #Close JSON Instance Interface Entries
        #-------------------------------------------------------------------------------------------
        echo '                               ]' >> $OUTPUT_FILE
        #-------------------------------------------------------------------------------------------

        (( COUNT++ ))

        #Close JSON Instance Entry
        #-------------------------------------------------------------------------------------------
        if [ $COUNT == $INSTANCE_NUMBER ]; then
            #Last Instance
            echo "                          }" >> $OUTPUT_FILE
        else
            echo "                          }," >> $OUTPUT_FILE
        fi
        #-------------------------------------------------------------------------------------------

    done

    #JSON Footer
    #-------------------------------------------------------------------------------------------
    echo '     ]' >> $OUTPUT_FILE
    echo '}' >> $OUTPUT_FILE
    #-------------------------------------------------------------------------------------------

echo "[ Digital Ocean: ${API_REGION} $(date +"%T")] Update Complete: ${INSTANCE_NUMBER} instances in all regions" >> $DEBUG_LOG

sleep ${TIMER}s
done
