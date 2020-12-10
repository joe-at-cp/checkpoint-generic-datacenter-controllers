#!/bin/bash

#IBM Cloud VPC API Default Settings
APIKEY=""
API_VERSION="2020-06-02"
API_REGION="us-east"
TIMER="120"
DEBUG_LOG="/var/log/datacenter.log"
OUTPUT_FILE="ibm_${API_REGION}.json"

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

API_ENDPOINT="https://${API_REGION}.iaas.cloud.ibm.com"


while true; do
 
    #Get Bearer Token
    TOKEN=$(curl_cli -s -k -X POST --header "Content-Type: application/x-www-form-urlencoded" --header "Accept: application/json" --data-urlencode "grant_type=urn:ibm:params:oauth:grant-type:apikey" --data-urlencode "apikey=${APIKEY}" "https://iam.cloud.ibm.com/identity/token" | jq .access_token -r)

    #Write JSON Header
    #-------------------------------------------------------------------------------------------
    echo '{' > $OUTPUT_FILE
    echo '     "version": "1.0",' >> $OUTPUT_FILE
    echo '     "description": "IBM Cloud VPC Gen 2",' >> $OUTPUT_FILE
    echo '     "objects": [' >> $OUTPUT_FILE
    #-------------------------------------------------------------------------------------------

    INSTANCE_JSON=$(curl_cli -s -k -X GET "$API_ENDPOINT/v1/instances?version=$API_VERSION&generation=2" -H "Authorization: Bearer ${TOKEN}")
    INSTANCE_NUMBER=$(echo ${INSTANCE_JSON} | jq .total_count -r)
    COUNT=0

    until [ $COUNT -eq $INSTANCE_NUMBER ]; do

        INSTANCE_NAME=$(echo ${INSTANCE_JSON} | jq .instances[${COUNT}].name -r)
        INSTANCE_ID=$(echo ${INSTANCE_JSON} | jq .instances[${COUNT}].id -r)
        INSTANCE_IF_NUMBER=$(echo ${INSTANCE_JSON} | jq '.instances['${COUNT}'].network_interfaces | length')
        INSTANCE_PROFILE=$(echo ${INSTANCE_JSON} | jq .instances[${COUNT}].profile.name -r)
        INSTANCE_VPC=$(echo ${INSTANCE_JSON} | jq .instances[${COUNT}].vpc.name -r)
        INSTANCE_ZONE=$(echo ${INSTANCE_JSON} | jq .instances[${COUNT}].zone.name -r)

        #Print
        echo " - Name: ${INSTANCE_NAME}"
        echo "   ID: ${INSTANCE_ID}"
        echo "   Profile: ${INSTANCE_PROFILE}"
        echo "   VPC: ${INSTANCE_VPC}"
        echo "   Zone: ${INSTANCE_ZONE}"
        echo "   Interfaces:"

        #Write JSON Instance Entry
        #-------------------------------------------------------------------------------------------
        echo '                          {' >> $OUTPUT_FILE
        echo '                               "name": "'${INSTANCE_NAME}'",' >> $OUTPUT_FILE
        echo '                               "id": "'${INSTANCE_ID}'",' >> $OUTPUT_FILE
        echo '                               "description": "VPC: '${INSTANCE_VPC}', Zone: '${INSTANCE_ZONE}', Profile: '${INSTANCE_PROFILE}'",' >> $OUTPUT_FILE
        echo '                               "ranges": [' >> $OUTPUT_FILE
        #-------------------------------------------------------------------------------------------

        INTERFACE_COUNT=0
        until [ "$INTERFACE_COUNT" == "$INSTANCE_IF_NUMBER" ]; do

            INSTANCE_IF_IP=$(echo ${INSTANCE_JSON} | jq .instances[${COUNT}].network_interfaces[${INTERFACE_COUNT}].primary_ipv4_address -r)

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

echo "[ IBM Cloud: ${API_REGION} $(date +"%T")] Update Complete: ${INSTANCE_NUMBER} instances in region" >> $DEBUG_LOG

sleep ${TIMER}s
done
